import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/data/database/app_database.dart';
import 'package:propnote/data/repositories/sqlite_app_repository.dart';
import 'package:propnote/data/services/app_directories.dart';
import 'package:propnote/models/contact.dart';
import 'package:propnote/models/list_sort_option.dart';
import 'package:propnote/models/property.dart';
import 'package:propnote/models/property_status.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('loads and processes a 300-property local dataset', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'propnote_volume_test_',
    );
    final directories = await AppDirectories.create(rootPath: temporary.path);
    final database = AppDatabase(
      directories: directories,
      factory: databaseFactoryFfi,
    );
    final repository = SqliteAppRepository(database);
    try {
      final defaults = await repository.loadSnapshot();
      final started = Stopwatch()..start();
      for (var i = 0; i < 300; i++) {
        final type = defaults.propertyTypes[i % defaults.propertyTypes.length];
        final tag = defaults.tags[i % defaults.tags.length];
        await repository.saveProperty(
          Property(
            id: 'volume-$i',
            title: 'Nhà mẫu $i',
            address: 'Đường thử nghiệm ${i % 30}',
            areaId: defaults.areas[i % defaults.areas.length].id,
            status: PropertyStatus.values[i % PropertyStatus.values.length],
            price: 1e9 + i * 1e7,
            landArea: 30 + i % 100,
            propertyTypeId: type.id,
            propertyType: type.name,
            tagIds: [tag.id],
            tags: [tag.name],
            notes: i.isEven ? 'Gần trường học' : 'Ngõ ô tô',
            latitude: 20.9 + (i % 20) * 0.01,
            longitude: 105.7 + (i % 20) * 0.01,
            createdAt: DateTime(2026, 1, 1).add(Duration(days: i)),
            contacts: [
              Contact(
                id: 'contact-$i',
                label: 'Liên hệ',
                phone: '090${i.toString().padLeft(7, '0')}',
              ),
            ],
          ),
        );
      }
      for (var i = 0; i < 20; i++) {
        await repository.movePropertyToTrash('volume-$i', DateTime(2026, 12));
      }

      final snapshot = await repository.loadSnapshot();
      final matched =
          snapshot.properties
              .where(
                (property) =>
                    property.title.contains('29') ||
                    property.notes.contains('trường học'),
              )
              .toList()
            ..sort(ListSortOption.newest.compare);
      started.stop();

      expect(snapshot.properties, hasLength(280));
      expect(snapshot.trash, hasLength(20));
      expect(matched, isNotEmpty);
      expect(
        started.elapsed,
        lessThan(const Duration(seconds: 15)),
        reason: 'Repository fixture took ${started.elapsed}',
      );
    } finally {
      await database.close();
      await temporary.delete(recursive: true);
    }
  });
}
