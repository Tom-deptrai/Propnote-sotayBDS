import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/data/database/app_database.dart';
import 'package:propnote/data/repositories/sqlite_app_repository.dart';
import 'package:propnote/data/services/app_directories.dart';
import 'package:propnote/models/property.dart';
import 'package:propnote/models/property_status.dart';
import 'package:propnote/state/app_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test(
    'AppState CRUD and marker settings survive a full database reopen',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'propnote_state_test_',
      );
      try {
        final directories = await AppDirectories.create(
          rootPath: temporary.path,
        );
        var database = AppDatabase(
          directories: directories,
          factory: databaseFactoryFfi,
        );
        var state = AppState(repository: SqliteAppRepository(database));
        await state.initialize();

        final area = state.areas.first;
        final type = state.propertyTypeModels.first;
        final tag = state.tagModels.first;
        final now = DateTime(2026, 8, 14);
        await state.addProperty(
          Property(
            id: 'persistent-property',
            title: 'Nhà lưu thật',
            address: 'Hà Nội',
            areaId: area.id,
            status: PropertyStatus.selling,
            price: 8e9,
            landArea: 60,
            propertyTypeId: type.id,
            propertyType: type.name,
            tagIds: [tag.id],
            tags: [tag.name],
            latitude: 21.03,
            longitude: 105.85,
            createdAt: now,
          ),
        );
        await state.setMarkerScale(1.3);
        await state.deleteProperty('persistent-property');
        await database.close();

        database = AppDatabase(
          directories: directories,
          factory: databaseFactoryFfi,
        );
        state = AppState(repository: SqliteAppRepository(database));
        await state.initialize();

        expect(state.properties, isEmpty);
        expect(state.trash.single.id, 'persistent-property');
        expect(state.trash.single.tagIds, [tag.id]);
        expect(state.markerScale, 1.3);

        await state.restoreFromTrash('persistent-property');
        await database.close();

        database = AppDatabase(
          directories: directories,
          factory: databaseFactoryFfi,
        );
        state = AppState(repository: SqliteAppRepository(database));
        await state.initialize();
        expect(state.properties.single.title, 'Nhà lưu thật');
        expect(state.trash, isEmpty);
        await database.close();
      } finally {
        await temporary.delete(recursive: true);
      }
    },
  );
}
