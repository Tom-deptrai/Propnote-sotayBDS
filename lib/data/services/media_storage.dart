import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../models/property_document.dart';
import '../../models/property_photo.dart';
import 'app_directories.dart';

class MediaCommit {
  final AppDirectories _directories;
  final Map<String, String> _movedPaths;
  final List<PropertyPhoto> photos;
  final List<PropertyDocument> documents;

  MediaCommit._({
    required this._directories,
    required this._movedPaths,
    required this.photos,
    required this.documents,
  });

  Future<void> rollback() async {
    for (final entry in _movedPaths.entries.toList().reversed) {
      final current = File(_directories.resolve(entry.value));
      if (!await current.exists()) continue;
      final original = File(_directories.resolve(entry.key));
      await original.parent.create(recursive: true);
      await current.rename(original.path);
    }
  }
}

class StagedPropertyDeletion {
  final Directory? _original;
  final Directory? _staged;

  StagedPropertyDeletion._(this._original, this._staged);

  Future<void> rollback() async {
    final staged = _staged;
    final original = _original;
    if (staged == null ||
        original == null ||
        !await staged.exists() ||
        await original.exists()) {
      return;
    }
    await original.parent.create(recursive: true);
    await staged.rename(original.path);
  }

  Future<void> complete() async {
    final staged = _staged;
    if (staged != null && await staged.exists()) {
      await staged.delete(recursive: true);
    }
  }
}

/// Quản lý binary media ngoài SQLite bằng đường dẫn tương đối.
class MediaStorage {
  final AppDirectories directories;
  final ImagePicker imagePicker;
  final Uuid uuid;

  MediaStorage({
    required this.directories,
    ImagePicker? imagePicker,
    Uuid? uuid,
  }) : imagePicker = imagePicker ?? ImagePicker(),
       uuid = uuid ?? const Uuid();

  String absolutePath(String relativePath) => directories.resolve(relativePath);

  Future<List<PropertyPhoto>> pickPhotos({
    required String propertyId,
    required ImageSource source,
  }) async {
    final List<XFile> picked;
    if (source == ImageSource.camera) {
      final cameraPhoto = await imagePicker.pickImage(source: source);
      picked = [?cameraPhoto];
    } else {
      picked = await imagePicker.pickMultiImage();
    }
    final photos = <PropertyPhoto>[];
    for (final file in picked) {
      photos.add(await _storePhoto(propertyId, file));
    }
    return photos;
  }

  Future<PropertyDocument?> pickDocumentImage({
    required String propertyId,
    required ImageSource source,
  }) async {
    final picked = await imagePicker.pickImage(source: source);
    if (picked == null) return null;
    return _storeDocument(
      propertyId,
      source: picked,
      originalName: p.basename(picked.path),
    );
  }

  Future<PropertyDocument?> pickDocumentFile({
    required String propertyId,
  }) async {
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Chọn tài liệu cho bất động sản',
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'webp',
        'doc',
        'docx',
        'xls',
        'xlsx',
      ],
    );
    if (picked == null) return null;
    return _storeDocument(
      propertyId,
      source: picked.xFile,
      originalName: picked.name,
    );
  }

  Future<MediaCommit> commitDraft({
    required String propertyId,
    required List<PropertyPhoto> photos,
    required List<PropertyDocument> documents,
  }) async {
    final moved = <String, String>{};

    Future<String?> commitPath(String? relativePath) async {
      if (relativePath == null ||
          !relativePath.startsWith('temporary/drafts/$propertyId/')) {
        return relativePath;
      }
      final target = relativePath.replaceFirst(
        'temporary/drafts/$propertyId/',
        'media/properties/$propertyId/',
      );
      final sourceFile = File(directories.resolve(relativePath));
      final targetFile = File(directories.resolve(target));
      if (!await sourceFile.exists()) {
        throw StateError('Không tìm thấy media tạm: $relativePath');
      }
      await targetFile.parent.create(recursive: true);
      if (await targetFile.exists()) await targetFile.delete();
      await sourceFile.rename(targetFile.path);
      moved[relativePath] = target;
      return target;
    }

    try {
      final committedPhotos = <PropertyPhoto>[];
      for (final photo in photos) {
        committedPhotos.add(
          photo.copyWith(
            relativePath: await commitPath(photo.relativePath),
            thumbnailRelativePath: await commitPath(
              photo.thumbnailRelativePath,
            ),
          ),
        );
      }
      final committedDocuments = <PropertyDocument>[];
      for (final document in documents) {
        committedDocuments.add(
          document.copyWith(
            relativePath: await commitPath(document.relativePath),
            thumbnailRelativePath: await commitPath(
              document.thumbnailRelativePath,
            ),
          ),
        );
      }
      return MediaCommit._(
        directories: directories,
        movedPaths: moved,
        photos: committedPhotos,
        documents: committedDocuments,
      );
    } catch (_) {
      await MediaCommit._(
        directories: directories,
        movedPaths: moved,
        photos: photos,
        documents: documents,
      ).rollback();
      rethrow;
    }
  }

  Future<void> cleanupDraft(String propertyId) async {
    final directory = Directory(
      directories.resolve('temporary/drafts/$propertyId'),
    );
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  Future<void> reconcileAfterStartup({
    required Set<String> propertyIds,
    required Set<String> referencedPaths,
  }) async {
    final deleting = Directory(directories.resolve('temporary/deleting'));
    if (await deleting.exists()) {
      await for (final entity in deleting.list(followLinks: false)) {
        if (entity is! Directory) continue;
        String? propertyId;
        for (final id in propertyIds) {
          if (p.basename(entity.path).endsWith('_$id')) {
            propertyId = id;
            break;
          }
        }
        if (propertyId == null) {
          await entity.delete(recursive: true);
          continue;
        }
        final original = Directory(
          directories.resolve('media/properties/$propertyId'),
        );
        if (await original.exists()) {
          await entity.delete(recursive: true);
        } else {
          await original.parent.create(recursive: true);
          await entity.rename(original.path);
        }
      }
    }

    final drafts = Directory(directories.resolve('temporary/drafts'));
    if (await drafts.exists()) await drafts.delete(recursive: true);

    final properties = Directory(directories.propertiesMediaPath);
    if (!await properties.exists()) return;
    await for (final entity in properties.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final propertyId = p.basename(entity.path);
      if (!propertyIds.contains(propertyId)) {
        await entity.delete(recursive: true);
        continue;
      }
      final childDirectories = <Directory>[];
      await for (final child in entity.list(
        recursive: true,
        followLinks: false,
      )) {
        if (child is Directory) {
          childDirectories.add(child);
        } else if (child is File) {
          final relativePath = directories.relative(child.path);
          if (!referencedPaths.contains(relativePath)) await child.delete();
        }
      }
      childDirectories.sort((a, b) => b.path.length.compareTo(a.path.length));
      for (final directory in childDirectories) {
        if (await directory.list().isEmpty) await directory.delete();
      }
    }
  }

  Future<void> deletePaths(Iterable<String> relativePaths) async {
    for (final relativePath in relativePaths.toSet()) {
      final file = File(directories.resolve(relativePath));
      if (await file.exists()) await file.delete();
    }
  }

  Future<StagedPropertyDeletion> stagePropertyDeletion(
    String propertyId,
  ) async {
    final original = Directory(
      directories.resolve('media/properties/$propertyId'),
    );
    if (!await original.exists()) {
      return StagedPropertyDeletion._(null, null);
    }
    final staged = Directory(
      directories.resolve('temporary/deleting/${uuid.v4()}_$propertyId'),
    );
    await staged.parent.create(recursive: true);
    await original.rename(staged.path);
    return StagedPropertyDeletion._(original, staged);
  }

  Future<PropertyPhoto> _storePhoto(String propertyId, XFile source) async {
    final id = uuid.v4();
    final originalRelative = 'temporary/drafts/$propertyId/photos/$id.jpg';
    final thumbnailRelative =
        'temporary/drafts/$propertyId/thumbnails/photos/$id.jpg';
    final original = File(directories.resolve(originalRelative));
    final thumbnail = File(directories.resolve(thumbnailRelative));
    await original.parent.create(recursive: true);
    await thumbnail.parent.create(recursive: true);

    await _compressOrCopy(
      source.path,
      original.path,
      quality: 88,
      minWidth: 2400,
      minHeight: 2400,
    );
    await _compressOrCopy(
      original.path,
      thumbnail.path,
      quality: 72,
      minWidth: 512,
      minHeight: 512,
    );

    return PropertyPhoto(
      id: id,
      propertyId: propertyId,
      relativePath: originalRelative,
      thumbnailRelativePath: thumbnailRelative,
      mimeType: 'image/jpeg',
      fileSize: await original.length(),
      sortOrder: 0,
      createdAt: DateTime.now(),
    );
  }

  Future<PropertyDocument> _storeDocument(
    String propertyId, {
    required XFile source,
    required String originalName,
  }) async {
    final id = uuid.v4();
    final safeExtension = _safeExtension(originalName);
    final relativePath =
        'temporary/drafts/$propertyId/documents/$id$safeExtension';
    final destination = File(directories.resolve(relativePath));
    await destination.parent.create(recursive: true);
    await source.saveTo(destination.path);

    final mimeType =
        lookupMimeType(originalName) ?? lookupMimeType(destination.path);
    String? thumbnailRelativePath;
    if (mimeType?.startsWith('image/') == true) {
      thumbnailRelativePath =
          'temporary/drafts/$propertyId/thumbnails/documents/$id.jpg';
      final thumbnail = File(directories.resolve(thumbnailRelativePath));
      await thumbnail.parent.create(recursive: true);
      await _compressOrCopy(
        destination.path,
        thumbnail.path,
        quality: 72,
        minWidth: 512,
        minHeight: 512,
      );
    }

    return PropertyDocument(
      id: id,
      propertyId: propertyId,
      relativePath: relativePath,
      originalName: originalName,
      thumbnailRelativePath: thumbnailRelativePath,
      mimeType: mimeType,
      fileSize: await destination.length(),
      sortOrder: 0,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _compressOrCopy(
    String source,
    String destination, {
    required int quality,
    required int minWidth,
    required int minHeight,
  }) async {
    final compressed = await FlutterImageCompress.compressAndGetFile(
      source,
      destination,
      format: CompressFormat.jpeg,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      keepExif: true,
      autoCorrectionAngle: true,
    );
    if (compressed == null) {
      await File(source).copy(destination);
    }
  }

  String _safeExtension(String fileName) {
    final extension = p.extension(fileName).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(extension) ? extension : '';
  }
}
