import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/backup_manifest.dart';
import '../database/app_database.dart';
import '../database/database_schema.dart';
import 'app_directories.dart';

class BackupValidationException implements Exception {
  final String message;

  const BackupValidationException(this.message);

  @override
  String toString() => message;
}

class BackupService {
  final AppDirectories directories;
  final AppDatabase database;
  final Uuid uuid;

  BackupService({required this.directories, required this.database, Uuid? uuid})
    : uuid = uuid ?? const Uuid();

  Future<File> createBackup() async {
    final working = Directory(
      directories.resolve('temporary/backup-${uuid.v4()}'),
    );
    await working.create(recursive: true);
    try {
      final databaseCopy = File(p.join(working.path, 'data.sqlite'));
      await database.checkpoint();
      await database.close();
      try {
        await File(database.path).copy(databaseCopy.path);
      } finally {
        await database.open();
      }

      final mediaSource = Directory(directories.mediaPath);
      final mediaCopy = Directory(p.join(working.path, 'media'));
      if (await mediaSource.exists()) {
        await _copyDirectory(mediaSource, mediaCopy);
      } else {
        await mediaCopy.create(recursive: true);
      }

      final manifest = BackupManifest(
        formatVersion: BackupManifest.currentFormatVersion,
        schemaVersion: DatabaseSchema.version,
        createdAt: DateTime.now().toUtc(),
        databaseSha256: await _sha256(databaseCopy),
      );
      await File(
        p.join(working.path, 'manifest.json'),
      ).writeAsString(jsonEncode(manifest.toJson()), flush: true);

      final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
        RegExp(r'[:.]'),
        '-',
      );
      final output = File(
        p.join(directories.backupsPath, 'propnote-$timestamp.zip'),
      );
      final encoder = ZipFileEncoder();
      encoder.create(output.path);
      await encoder.addDirectory(working, includeDirName: false);
      await encoder.close();
      return output;
    } finally {
      if (await working.exists()) await working.delete(recursive: true);
    }
  }

  Future<BackupManifest> validateBackup(String archivePath) async {
    final extracted = await _extract(archivePath);
    try {
      return await _validateExtracted(extracted);
    } finally {
      if (await extracted.exists()) await extracted.delete(recursive: true);
    }
  }

  Future<void> restoreBackup(String archivePath) async {
    final extracted = await _extract(archivePath);
    final recovery = Directory(
      directories.resolve('temporary/recovery-${uuid.v4()}'),
    );
    await recovery.create(recursive: true);
    try {
      await _validateExtracted(extracted);
      final candidateDatabase = File(p.join(extracted.path, 'data.sqlite'));
      final candidateMedia = Directory(p.join(extracted.path, 'media'));
      final currentDatabase = File(database.path);
      final currentMedia = Directory(directories.mediaPath);
      final recoveryDatabase = File(p.join(recovery.path, 'data.sqlite'));
      final recoveryMedia = Directory(p.join(recovery.path, 'media'));

      await database.close();
      var currentDatabaseMoved = false;
      var currentMediaMoved = false;
      try {
        if (await currentDatabase.exists()) {
          await currentDatabase.rename(recoveryDatabase.path);
          currentDatabaseMoved = true;
        }
        if (await currentMedia.exists()) {
          await currentMedia.rename(recoveryMedia.path);
          currentMediaMoved = true;
        }

        await currentDatabase.parent.create(recursive: true);
        await candidateDatabase.rename(currentDatabase.path);
        if (await candidateMedia.exists()) {
          await candidateMedia.rename(currentMedia.path);
        } else {
          await currentMedia.create(recursive: true);
        }
        await database.open();
      } catch (_) {
        await database.close();
        if (await currentDatabase.exists()) await currentDatabase.delete();
        if (await currentMedia.exists()) {
          await currentMedia.delete(recursive: true);
        }
        if (currentDatabaseMoved && await recoveryDatabase.exists()) {
          await recoveryDatabase.rename(currentDatabase.path);
        }
        if (currentMediaMoved && await recoveryMedia.exists()) {
          await recoveryMedia.rename(currentMedia.path);
        }
        await database.open();
        rethrow;
      }
    } finally {
      if (await extracted.exists()) await extracted.delete(recursive: true);
      if (await recovery.exists()) await recovery.delete(recursive: true);
    }
  }

  Future<Directory> _extract(String archivePath) async {
    final archive = File(archivePath);
    if (!await archive.exists() ||
        p.extension(archive.path).toLowerCase() != '.zip') {
      throw const BackupValidationException(
        'Tệp đã chọn không phải backup ZIP của PropNote',
      );
    }
    final extracted = Directory(
      directories.resolve('temporary/restore-${uuid.v4()}'),
    );
    await extracted.create(recursive: true);
    try {
      await extractFileToDisk(archive.path, extracted.path);
      return extracted;
    } catch (_) {
      if (await extracted.exists()) await extracted.delete(recursive: true);
      throw const BackupValidationException(
        'Không thể đọc tệp backup hoặc tệp đã bị hỏng',
      );
    }
  }

  Future<BackupManifest> _validateExtracted(Directory extracted) async {
    final manifestFile = File(p.join(extracted.path, 'manifest.json'));
    final candidateDatabase = File(p.join(extracted.path, 'data.sqlite'));
    if (!await manifestFile.exists() || !await candidateDatabase.exists()) {
      throw const BackupValidationException(
        'Backup thiếu manifest hoặc database',
      );
    }

    BackupManifest manifest;
    try {
      manifest = BackupManifest.fromJson(
        jsonDecode(await manifestFile.readAsString()) as Map<String, Object?>,
      );
    } catch (_) {
      throw const BackupValidationException('Manifest backup không hợp lệ');
    }
    if (manifest.formatVersion != BackupManifest.currentFormatVersion) {
      throw BackupValidationException(
        'Phiên bản backup ${manifest.formatVersion} chưa được hỗ trợ',
      );
    }
    if (manifest.schemaVersion < 1 ||
        manifest.schemaVersion > DatabaseSchema.version) {
      throw BackupValidationException(
        'Schema backup v${manifest.schemaVersion} không tương thích',
      );
    }
    if (await _sha256(candidateDatabase) != manifest.databaseSha256) {
      throw const BackupValidationException(
        'Database trong backup không khớp checksum',
      );
    }

    Database? candidate;
    try {
      candidate = await database.factory.openDatabase(
        candidateDatabase.path,
        options: OpenDatabaseOptions(readOnly: true),
      );
      final version = await candidate.getVersion();
      final tables = await candidate.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final tableNames = tables.map((row) => row['name']).toSet();
      if (version != manifest.schemaVersion ||
          !tableNames.containsAll([
            'properties',
            'areas',
            'property_types',
            'tags',
            'app_settings',
          ])) {
        throw const BackupValidationException(
          'Cấu trúc database backup không hợp lệ',
        );
      }
      final foreignKeyErrors = await candidate.rawQuery(
        'PRAGMA foreign_key_check',
      );
      if (foreignKeyErrors.isNotEmpty) {
        throw const BackupValidationException(
          'Quan hệ dữ liệu trong backup bị hỏng',
        );
      }
    } on BackupValidationException {
      rethrow;
    } catch (_) {
      throw const BackupValidationException(
        'Không thể mở database trong backup',
      );
    } finally {
      await candidate?.close();
    }
    return manifest;
  }

  Future<String> _sha256(File file) async =>
      (await sha256.bind(file.openRead()).first).toString();

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {
      final relative = p.relative(entity.path, from: source.path);
      final target = p.join(destination.path, relative);
      if (entity is Directory) {
        await Directory(target).create(recursive: true);
      } else if (entity is File) {
        await File(target).parent.create(recursive: true);
        await entity.copy(target);
      }
    }
  }
}
