import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/data/database/app_database.dart';
import 'package:propnote/data/repositories/sqlite_app_repository.dart';
import 'package:propnote/data/services/app_directories.dart';
import 'package:propnote/data/services/backup_service.dart';
import 'package:propnote/models/backup_manifest.dart';
import 'package:propnote/models/property.dart';
import 'package:propnote/models/property_status.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Directory temporary;
  late AppDirectories directories;
  late AppDatabase database;
  late SqliteAppRepository repository;
  late BackupService backups;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('propnote_backup_test_');
    directories = await AppDirectories.create(rootPath: temporary.path);
    database = AppDatabase(
      directories: directories,
      factory: databaseFactoryFfi,
    );
    repository = SqliteAppRepository(database);
    backups = BackupService(directories: directories, database: database);
  });

  tearDown(() async {
    await database.close();
    await temporary.delete(recursive: true);
  });

  Future<void> addProperty(String id) async {
    final snapshot = await repository.loadSnapshot();
    await repository.saveProperty(
      Property(
        id: id,
        title: id,
        address: 'Hà Nội',
        areaId: snapshot.areas.first.id,
        status: PropertyStatus.selling,
        price: 1,
        landArea: 1,
        propertyTypeId: snapshot.propertyTypes.first.id,
        propertyType: snapshot.propertyTypes.first.name,
        createdAt: DateTime(2026, 8, 14),
      ),
    );
  }

  test(
    'creates a versioned archive and restores database plus media',
    () async {
      await addProperty('before-backup');
      final media = File(
        directories.resolve('media/properties/before-backup/photos/photo.jpg'),
      );
      await media.parent.create(recursive: true);
      await media.writeAsString('photo');

      final archive = await backups.createBackup();
      final manifest = await backups.validateBackup(archive.path);
      expect(manifest.formatVersion, BackupManifest.currentFormatVersion);

      await addProperty('after-backup');
      await media.writeAsString('changed');
      await backups.restoreBackup(archive.path);

      final restored = await repository.loadSnapshot();
      expect(restored.properties.map((property) => property.id), [
        'before-backup',
      ]);
      expect(await media.readAsString(), 'photo');
    },
  );

  test('rejects corrupt backup without changing current data', () async {
    await addProperty('safe-property');
    final corrupt = File(directories.resolve('temporary/corrupt.zip'));
    await corrupt.writeAsString('not a zip');

    await expectLater(
      backups.restoreBackup(corrupt.path),
      throwsA(isA<BackupValidationException>()),
    );
    expect(
      (await repository.loadSnapshot()).properties.single.id,
      'safe-property',
    );
  });

  test('backup manifest rejects incomplete metadata', () {
    expect(
      () => BackupManifest.fromJson(const {'formatVersion': 1}),
      throwsFormatException,
    );
  });
}
