import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:propnote/data/services/storage_usage_service.dart';

void main() {
  group('StorageUsageService.directorySize', () {
    late Directory temp;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('propnote_storage_test_');
    });

    tearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    test('missing directory returns 0', () async {
      final missing = p.join(temp.path, 'does-not-exist');
      final size = await StorageUsageService.directorySize(missing);
      expect(size, 0);
    });

    test('empty directory returns 0', () async {
      final size = await StorageUsageService.directorySize(temp.path);
      expect(size, 0);
    });

    test('sums nested files correctly', () async {
      await File(p.join(temp.path, 'a.txt')).writeAsBytes(List.filled(100, 0));
      final subDir = Directory(p.join(temp.path, 'sub'));
      await subDir.create();
      await File(
        p.join(subDir.path, 'b.txt'),
      ).writeAsBytes(List.filled(250, 0));

      final size = await StorageUsageService.directorySize(temp.path);
      expect(size, 350);
    });

    test(
      'file already gone before scan is simply excluded, no throw',
      () async {
        final file = File(p.join(temp.path, 'vanishing.txt'));
        await file.writeAsBytes(List.filled(100, 0));
        await File(
          p.join(temp.path, 'stays.txt'),
        ).writeAsBytes(List.filled(50, 0));
        await file.delete();

        final size = await StorageUsageService.directorySize(temp.path);
        expect(size, 50);
      },
    );

    test(
      'unreadable subdirectory is skipped instead of aborting the whole scan',
      () async {
        final readable = File(p.join(temp.path, 'ok.txt'));
        await readable.writeAsBytes(List.filled(64, 0));
        final lockedDir = Directory(p.join(temp.path, 'locked'));
        await lockedDir.create();
        await File(
          p.join(lockedDir.path, 'inside.txt'),
        ).writeAsBytes(List.filled(999, 0));
        await Process.run('chmod', ['000', lockedDir.path]);
        try {
          final size = await StorageUsageService.directorySize(temp.path);
          expect(size, greaterThanOrEqualTo(64));
        } finally {
          await Process.run('chmod', ['755', lockedDir.path]);
        }
      },
      skip: Platform.isWindows,
    );
  });

  group('StorageUsageService.compute', () {
    late Directory temp;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('propnote_storage_test_');
    });

    tearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    test('sums appData + map without double counting', () async {
      final appDataRoot = Directory(p.join(temp.path, 'propnote'));
      final mapRoot = Directory(p.join(temp.path, 'map'));
      await appDataRoot.create();
      await mapRoot.create();
      await File(
        p.join(appDataRoot.path, 'db.sqlite'),
      ).writeAsBytes(List.filled(1000, 0));
      await File(
        p.join(mapRoot.path, 'hcm.pmtiles'),
      ).writeAsBytes(List.filled(2000, 0));

      final service = StorageUsageService(
        appDataRoot: appDataRoot.path,
        mapRoot: mapRoot.path,
      );
      final usage = await service.compute();

      expect(usage.appDataBytes, 1000);
      expect(usage.mapBytes, 2000);
      expect(usage.totalBytes, 3000);
    });

    test('missing map dir still returns a valid total (app data only)', () async {
      final appDataRoot = Directory(p.join(temp.path, 'propnote'));
      await appDataRoot.create();
      await File(
        p.join(appDataRoot.path, 'db.sqlite'),
      ).writeAsBytes(List.filled(500, 0));

      final service = StorageUsageService(
        appDataRoot: appDataRoot.path,
        mapRoot: p.join(temp.path, 'map-not-created'),
      );
      final usage = await service.compute();

      expect(usage.appDataBytes, 500);
      expect(usage.mapBytes, 0);
      expect(usage.totalBytes, 500);
    });
  });

  group('formatStorageBytes', () {
    test('formats bytes', () => expect(formatStorageBytes(500), '500 B'));
    test(
      'formats kilobytes',
      () => expect(formatStorageBytes(2048), '2.0 KB'),
    );
    test(
      'formats megabytes',
      () => expect(formatStorageBytes(5 * 1024 * 1024), '5.0 MB'),
    );
    test(
      'formats gigabytes',
      () => expect(
        formatStorageBytes(2 * 1024 * 1024 * 1024),
        '2.00 GB',
      ),
    );
  });
}
