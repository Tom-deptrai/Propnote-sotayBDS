import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/data/services/app_directories.dart';
import 'package:propnote/data/services/media_storage.dart';
import 'package:propnote/models/property_document.dart';
import 'package:propnote/models/property_photo.dart';

void main() {
  late Directory temporary;
  late AppDirectories directories;
  late MediaStorage storage;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('propnote_media_test_');
    directories = await AppDirectories.create(rootPath: temporary.path);
    storage = MediaStorage(directories: directories);
  });

  tearDown(() async {
    await temporary.delete(recursive: true);
  });

  test('commits draft media with relative paths and can roll back', () async {
    const propertyId = 'property-1';
    const photoPath = 'temporary/drafts/property-1/photos/photo-1.jpg';
    const thumbnailPath =
        'temporary/drafts/property-1/thumbnails/photos/photo-1.jpg';
    const documentPath = 'temporary/drafts/property-1/documents/document-1.pdf';
    for (final path in [photoPath, thumbnailPath, documentPath]) {
      final file = File(directories.resolve(path));
      await file.parent.create(recursive: true);
      await file.writeAsString(path);
    }

    final commit = await storage.commitDraft(
      propertyId: propertyId,
      photos: [
        PropertyPhoto(
          id: 'photo-1',
          propertyId: propertyId,
          relativePath: photoPath,
          thumbnailRelativePath: thumbnailPath,
          sortOrder: 0,
          createdAt: DateTime(2026),
        ),
      ],
      documents: [
        PropertyDocument(
          id: 'document-1',
          propertyId: propertyId,
          relativePath: documentPath,
          originalName: 'sodo.pdf',
          sortOrder: 0,
          createdAt: DateTime(2026),
        ),
      ],
    );

    expect(
      commit.photos.single.relativePath,
      'media/properties/property-1/photos/photo-1.jpg',
    );
    expect(
      await File(
        directories.resolve(commit.photos.single.relativePath),
      ).exists(),
      isTrue,
    );
    expect(
      commit.documents.single.relativePath,
      'media/properties/property-1/documents/document-1.pdf',
    );

    await commit.rollback();
    expect(await File(directories.resolve(photoPath)).exists(), isTrue);
    expect(await File(directories.resolve(documentPath)).exists(), isTrue);
  });

  test('stages property directory before destructive deletion', () async {
    final media = File(
      directories.resolve('media/properties/property-2/photos/photo.jpg'),
    );
    await media.parent.create(recursive: true);
    await media.writeAsString('photo');

    var deletion = await storage.stagePropertyDeletion('property-2');
    expect(await media.exists(), isFalse);
    await deletion.rollback();
    expect(await media.exists(), isTrue);

    deletion = await storage.stagePropertyDeletion('property-2');
    await deletion.complete();
    expect(await media.exists(), isFalse);
  });

  test('rejects absolute and parent-traversal relative paths', () {
    expect(() => directories.resolve('/tmp/file'), throwsArgumentError);
    expect(() => directories.resolve('../outside'), throwsArgumentError);
  });

  test(
    'startup reconciliation restores staged data and removes orphans',
    () async {
      const referenced = 'media/properties/property-keep/photos/keep.jpg';
      final keep = File(directories.resolve(referenced));
      final unreferenced = File(
        directories.resolve('media/properties/property-keep/photos/orphan.jpg'),
      );
      final orphanProperty = File(
        directories.resolve(
          'media/properties/property-orphan/photos/photo.jpg',
        ),
      );
      final stagedProperty = File(
        directories.resolve(
          'media/properties/property-staged/photos/photo.jpg',
        ),
      );
      final staleDraft = File(
        directories.resolve('temporary/drafts/property-new/photos/photo.jpg'),
      );
      for (final file in [
        keep,
        unreferenced,
        orphanProperty,
        stagedProperty,
        staleDraft,
      ]) {
        await file.parent.create(recursive: true);
        await file.writeAsString('data');
      }
      await storage.stagePropertyDeletion('property-staged');

      await storage.reconcileAfterStartup(
        propertyIds: {'property-keep', 'property-staged'},
        referencedPaths: {
          referenced,
          'media/properties/property-staged/photos/photo.jpg',
        },
      );

      expect(await keep.exists(), isTrue);
      expect(await unreferenced.exists(), isFalse);
      expect(await orphanProperty.exists(), isFalse);
      expect(await stagedProperty.exists(), isTrue);
      expect(await staleDraft.exists(), isFalse);
    },
  );
}
