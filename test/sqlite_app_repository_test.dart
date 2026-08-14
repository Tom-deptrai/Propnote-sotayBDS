import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/data/database/app_database.dart';
import 'package:propnote/data/database/database_schema.dart';
import 'package:propnote/data/repositories/sqlite_app_repository.dart';
import 'package:propnote/data/services/app_directories.dart';
import 'package:propnote/models/contact.dart';
import 'package:propnote/models/property.dart';
import 'package:propnote/models/property_status.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Directory temporary;
  late AppDirectories directories;
  late AppDatabase database;
  late SqliteAppRepository repository;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('propnote_db_test_');
    directories = await AppDirectories.create(rootPath: temporary.path);
    database = AppDatabase(
      directories: directories,
      factory: databaseFactoryFfi,
    );
    repository = SqliteAppRepository(database);
  });

  tearDown(() async {
    await database.close();
    await temporary.delete(recursive: true);
  });

  test(
    'creates versioned schema, enables foreign keys, and seeds no property',
    () async {
      final db = await database.open();
      final foreignKeys = await db.rawQuery('PRAGMA foreign_keys');
      final version = await db.rawQuery('PRAGMA user_version');
      final snapshot = await repository.loadSnapshot();

      expect(foreignKeys.single['foreign_keys'], 1);
      expect(version.single['user_version'], DatabaseSchema.version);
      expect(snapshot.properties, isEmpty);
      expect(snapshot.trash, isEmpty);
      expect(snapshot.areas, isNotEmpty);
      expect(snapshot.propertyTypes, isNotEmpty);
      expect(snapshot.tags, isNotEmpty);
      expect(snapshot.markerScale, 1);
    },
  );

  test(
    'persists property relations and trash lifecycle across reopen',
    () async {
      final initial = await repository.loadSnapshot();
      final now = DateTime(2026, 8, 14, 10);
      final type = initial.propertyTypes.first;
      final tag = initial.tags.first;
      final area = initial.areas.first;
      final property = Property(
        id: 'property-1',
        title: 'Nhà test',
        address: 'Hà Nội',
        areaId: area.id,
        status: PropertyStatus.selling,
        price: 12.5e9,
        landArea: 72,
        propertyTypeId: type.id,
        propertyType: type.name,
        tagIds: [tag.id],
        tags: [tag.name],
        notes: 'Persist me',
        surveyDate: now,
        latitude: 21.0285,
        longitude: 105.8542,
        createdAt: now,
        contacts: const [
          Contact(id: 'contact-1', label: 'Chủ nhà', phone: '0901234567'),
        ],
      );

      await repository.saveProperty(property);
      await database.close();

      var snapshot = await repository.loadSnapshot();
      expect(snapshot.properties, hasLength(1));
      expect(snapshot.properties.single.propertyTypeId, type.id);
      expect(snapshot.properties.single.tagIds, [tag.id]);
      expect(snapshot.properties.single.contacts.single.phone, '0901234567');
      expect(snapshot.properties.single.latitude, 21.0285);

      await repository.movePropertyToTrash(
        'property-1',
        now.add(const Duration(days: 1)),
      );
      snapshot = await repository.loadSnapshot();
      expect(snapshot.properties, isEmpty);
      expect(snapshot.trash.single.id, 'property-1');

      await repository.restoreProperty(
        'property-1',
        now.add(const Duration(days: 2)),
      );
      snapshot = await repository.loadSnapshot();
      expect(snapshot.properties.single.deletedAt, isNull);

      await repository.movePropertyToTrash(
        'property-1',
        now.add(const Duration(days: 3)),
      );
      final assets = await repository.deletePropertyPermanently('property-1');
      expect(assets.propertyId, 'property-1');
      expect((await repository.loadSnapshot()).trash, isEmpty);

      final db = await database.open();
      expect(
        (await db.rawQuery(
          'SELECT COUNT(*) AS count FROM contacts',
        )).single['count'],
        0,
      );
      expect(
        (await db.rawQuery(
          'SELECT COUNT(*) AS count FROM property_tags',
        )).single['count'],
        0,
      );
    },
  );

  test('persists marker scale and protects referenced options', () async {
    final snapshot = await repository.loadSnapshot();
    final area = snapshot.areas.first;
    final type = snapshot.propertyTypes.first;
    final now = DateTime(2026, 8, 14);
    await repository.saveProperty(
      Property(
        id: 'property-2',
        title: 'BĐS',
        address: '',
        areaId: area.id,
        status: PropertyStatus.unsurveyed,
        price: 0,
        landArea: 0,
        propertyTypeId: type.id,
        propertyType: type.name,
        createdAt: now,
      ),
    );
    await repository.writeSetting('marker_scale', '1.25');
    await database.close();

    expect((await repository.loadSnapshot()).markerScale, 1.25);
    expect(
      () => repository.deleteArea(area.id),
      throwsA(isA<DatabaseException>()),
    );
    expect(
      () => repository.deletePropertyType(type.id),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('migrates a v1 database forward without dropping user data', () async {
    final legacy = await databaseFactoryFfi.openDatabase(
      directories.databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await DatabaseSchema.create(db);
          await db.execute('DROP INDEX idx_properties_updated_at');
        },
      ),
    );
    await legacy.insert('app_settings', {
      'key': 'migration_sentinel',
      'value': 'preserved',
      'updated_at': DateTime(2026).millisecondsSinceEpoch,
    });
    await legacy.close();

    final upgraded = await database.open();
    final indexes = await upgraded.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index'",
    );
    expect(await upgraded.getVersion(), DatabaseSchema.version);
    expect(
      indexes.map((row) => row['name']),
      contains('idx_properties_updated_at'),
    );
    expect(await repository.readSetting('migration_sentinel'), 'preserved');
  });
}
