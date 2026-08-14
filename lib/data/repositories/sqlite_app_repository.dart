import 'package:sqflite/sqflite.dart';

import '../../models/area.dart';
import '../../models/contact.dart';
import '../../models/geo_point.dart';
import '../../models/property.dart';
import '../../models/property_document.dart';
import '../../models/property_photo.dart';
import '../../models/property_status.dart';
import '../../models/property_tag.dart';
import '../../models/property_type.dart';
import '../database/app_database.dart';
import 'app_repository.dart';

class SqliteAppRepository implements AppRepository {
  final AppDatabase appDatabase;

  SqliteAppRepository(this.appDatabase);

  @override
  Future<AppDataSnapshot> loadSnapshot() async {
    final db = await appDatabase.open();
    final results = await Future.wait([
      db.query('areas', orderBy: 'sort_order ASC, name ASC'),
      db.query('property_types', orderBy: 'sort_order ASC, name ASC'),
      db.query('tags', orderBy: 'sort_order ASC, name ASC'),
      db.query('properties', orderBy: 'created_at DESC, id ASC'),
      db.query('property_tags', orderBy: 'sort_order ASC'),
      db.query('contacts', orderBy: 'sort_order ASC, id ASC'),
      db.query('property_photos', orderBy: 'sort_order ASC, id ASC'),
      db.query('property_documents', orderBy: 'sort_order ASC, id ASC'),
      db.query(
        'app_settings',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: ['marker_scale'],
        limit: 1,
      ),
    ]);

    final areas = results[0].map(_areaFromRow).toList(growable: false);
    final types = results[1].map(_typeFromRow).toList(growable: false);
    final tags = results[2].map(_tagFromRow).toList(growable: false);
    final typeById = {for (final type in types) type.id: type};
    final tagById = {for (final tag in tags) tag.id: tag};

    final tagIdsByProperty = <String, List<String>>{};
    for (final row in results[4]) {
      tagIdsByProperty
          .putIfAbsent(row['property_id']! as String, () => [])
          .add(row['tag_id']! as String);
    }

    final contactsByProperty = <String, List<Contact>>{};
    for (final row in results[5]) {
      contactsByProperty
          .putIfAbsent(row['property_id']! as String, () => [])
          .add(_contactFromRow(row));
    }

    final photosByProperty = <String, List<PropertyPhoto>>{};
    for (final row in results[6]) {
      photosByProperty
          .putIfAbsent(row['property_id']! as String, () => [])
          .add(_photoFromRow(row));
    }

    final documentsByProperty = <String, List<PropertyDocument>>{};
    for (final row in results[7]) {
      documentsByProperty
          .putIfAbsent(row['property_id']! as String, () => [])
          .add(_documentFromRow(row));
    }

    final allProperties = results[3]
        .map(
          (row) => _propertyFromRow(
            row,
            typeById: typeById,
            tagById: tagById,
            tagIds: tagIdsByProperty[row['id']] ?? const [],
            contacts: contactsByProperty[row['id']] ?? const [],
            photos: photosByProperty[row['id']] ?? const [],
            documents: documentsByProperty[row['id']] ?? const [],
          ),
        )
        .toList(growable: false);

    final active = allProperties
        .where((property) => property.deletedAt == null)
        .toList(growable: false);
    final trash =
        allProperties.where((property) => property.deletedAt != null).toList()
          ..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));

    final settingRows = results[8];
    final markerScale = settingRows.isEmpty
        ? 1.0
        : double.tryParse(settingRows.first['value']! as String) ?? 1.0;

    return AppDataSnapshot(
      properties: active,
      trash: trash,
      areas: areas,
      propertyTypes: types,
      tags: tags,
      markerScale: markerScale,
    );
  }

  @override
  Future<void> saveProperty(Property property) async {
    if (property.propertyTypeId.isEmpty) {
      throw ArgumentError.value(
        property.propertyTypeId,
        'property.propertyTypeId',
        'Property phải dùng stable property type ID',
      );
    }

    final db = await appDatabase.open();
    await db.transaction((txn) async {
      final row = _propertyToRow(property);
      final existing = Sqflite.firstIntValue(
        await txn.rawQuery('SELECT COUNT(*) FROM properties WHERE id = ?', [
          property.id,
        ]),
      );
      if (existing == 0) {
        await txn.insert('properties', row);
      } else {
        await txn.update(
          'properties',
          row,
          where: 'id = ?',
          whereArgs: [property.id],
        );
      }

      await txn.delete(
        'property_tags',
        where: 'property_id = ?',
        whereArgs: [property.id],
      );
      for (var i = 0; i < property.tagIds.length; i++) {
        await txn.insert('property_tags', {
          'property_id': property.id,
          'tag_id': property.tagIds[i],
          'sort_order': i,
        });
      }

      await txn.delete(
        'contacts',
        where: 'property_id = ?',
        whereArgs: [property.id],
      );
      for (var i = 0; i < property.contacts.length; i++) {
        final contact = property.contacts[i];
        await txn.insert('contacts', {
          'id': contact.id,
          'property_id': property.id,
          'label': contact.label,
          'phone': contact.phone,
          'sort_order': i,
          'created_at': property.createdAt.millisecondsSinceEpoch,
          'updated_at': property.updatedAt.millisecondsSinceEpoch,
        });
      }

      await txn.delete(
        'property_photos',
        where: 'property_id = ?',
        whereArgs: [property.id],
      );
      for (var i = 0; i < property.photos.length; i++) {
        await txn.insert(
          'property_photos',
          _photoToRow(property.photos[i].copyWith(sortOrder: i)),
        );
      }

      await txn.delete(
        'property_documents',
        where: 'property_id = ?',
        whereArgs: [property.id],
      );
      for (var i = 0; i < property.documents.length; i++) {
        await txn.insert(
          'property_documents',
          _documentToRow(property.documents[i].copyWith(sortOrder: i)),
        );
      }
    });
  }

  @override
  Future<void> movePropertyToTrash(
    String propertyId,
    DateTime deletedAt,
  ) async {
    final db = await appDatabase.open();
    final count = await db.update(
      'properties',
      {
        'deleted_at': deletedAt.millisecondsSinceEpoch,
        'updated_at': deletedAt.millisecondsSinceEpoch,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [propertyId],
    );
    if (count != 1) {
      throw StateError('Không tìm thấy BĐS đang hoạt động: $propertyId');
    }
  }

  @override
  Future<void> restoreProperty(String propertyId, DateTime updatedAt) async {
    final db = await appDatabase.open();
    final count = await db.update(
      'properties',
      {'deleted_at': null, 'updated_at': updatedAt.millisecondsSinceEpoch},
      where: 'id = ? AND deleted_at IS NOT NULL',
      whereArgs: [propertyId],
    );
    if (count != 1) {
      throw StateError('Không tìm thấy BĐS trong thùng rác: $propertyId');
    }
  }

  @override
  Future<PropertyAssetPaths> deletePropertyPermanently(
    String propertyId,
  ) async {
    final db = await appDatabase.open();
    return db.transaction((txn) async {
      final paths = await _assetPaths(txn, propertyId);
      final count = await txn.delete(
        'properties',
        where: 'id = ? AND deleted_at IS NOT NULL',
        whereArgs: [propertyId],
      );
      if (count != 1) {
        throw StateError('Không tìm thấy BĐS trong thùng rác: $propertyId');
      }
      return PropertyAssetPaths(propertyId: propertyId, relativePaths: paths);
    });
  }

  @override
  Future<List<PropertyAssetPaths>> emptyTrash() async {
    final db = await appDatabase.open();
    return db.transaction((txn) async {
      final rows = await txn.query(
        'properties',
        columns: ['id'],
        where: 'deleted_at IS NOT NULL',
      );
      final assets = <PropertyAssetPaths>[];
      for (final row in rows) {
        final id = row['id']! as String;
        assets.add(
          PropertyAssetPaths(
            propertyId: id,
            relativePaths: await _assetPaths(txn, id),
          ),
        );
      }
      await txn.delete('properties', where: 'deleted_at IS NOT NULL');
      return assets;
    });
  }

  @override
  Future<void> saveArea(PropertyArea area) async {
    final db = await appDatabase.open();
    await _upsertNamedOption(
      db,
      table: 'areas',
      id: area.id,
      name: area.name,
      sortOrder: area.sortOrder,
    );
  }

  @override
  Future<void> deleteArea(String areaId) async {
    final db = await appDatabase.open();
    final count = await db.delete(
      'areas',
      where: 'id = ?',
      whereArgs: [areaId],
    );
    if (count != 1) throw StateError('Không tìm thấy khu vực: $areaId');
  }

  @override
  Future<void> reorderAreas(List<String> orderedIds) =>
      _reorder('areas', orderedIds);

  @override
  Future<void> savePropertyType(PropertyType type) async {
    final db = await appDatabase.open();
    await _upsertNamedOption(
      db,
      table: 'property_types',
      id: type.id,
      name: type.name,
      sortOrder: type.sortOrder,
    );
  }

  @override
  Future<void> deletePropertyType(String typeId) async {
    final db = await appDatabase.open();
    final count = await db.delete(
      'property_types',
      where: 'id = ?',
      whereArgs: [typeId],
    );
    if (count != 1) throw StateError('Không tìm thấy loại BĐS: $typeId');
  }

  @override
  Future<void> reorderPropertyTypes(List<String> orderedIds) =>
      _reorder('property_types', orderedIds);

  @override
  Future<void> saveTag(PropertyTag tag) async {
    final db = await appDatabase.open();
    await _upsertNamedOption(
      db,
      table: 'tags',
      id: tag.id,
      name: tag.name,
      sortOrder: tag.sortOrder,
    );
  }

  @override
  Future<void> deleteTag(String tagId) async {
    final db = await appDatabase.open();
    final count = await db.delete('tags', where: 'id = ?', whereArgs: [tagId]);
    if (count != 1) throw StateError('Không tìm thấy tag: $tagId');
  }

  @override
  Future<void> reorderTags(List<String> orderedIds) =>
      _reorder('tags', orderedIds);

  @override
  Future<String?> readSetting(String key) async {
    final db = await appDatabase.open();
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value']! as String;
  }

  @override
  Future<void> writeSetting(String key, String value) async {
    final db = await appDatabase.open();
    await db.insert('app_settings', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _reorder(String table, List<String> orderedIds) async {
    final db = await appDatabase.open();
    await db.transaction((txn) async {
      for (var i = 0; i < orderedIds.length; i++) {
        final count = await txn.update(
          table,
          {
            'sort_order': i,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [orderedIds[i]],
        );
        if (count != 1) {
          throw StateError('Không tìm thấy $table: ${orderedIds[i]}');
        }
      }
    });
  }

  static Future<void> _upsertNamedOption(
    DatabaseExecutor db, {
    required String table,
    required String id,
    required String name,
    required int sortOrder,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $table WHERE id = ?', [id]),
    );
    if (existing == 0) {
      await db.insert(table, {
        'id': id,
        'name': name,
        'sort_order': sortOrder,
        'created_at': now,
        'updated_at': now,
      });
    } else {
      await db.update(
        table,
        {'name': name, 'sort_order': sortOrder, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  static Future<List<String>> _assetPaths(
    DatabaseExecutor db,
    String propertyId,
  ) async {
    final paths = <String>[];
    for (final table in ['property_photos', 'property_documents']) {
      final rows = await db.query(
        table,
        columns: ['relative_path', 'thumbnail_relative_path'],
        where: 'property_id = ?',
        whereArgs: [propertyId],
      );
      for (final row in rows) {
        paths.add(row['relative_path']! as String);
        final thumbnail = row['thumbnail_relative_path'] as String?;
        if (thumbnail != null) paths.add(thumbnail);
      }
    }
    return paths;
  }

  static PropertyArea _areaFromRow(Map<String, Object?> row) {
    return PropertyArea(
      id: row['id']! as String,
      name: row['name']! as String,
      sortOrder: row['sort_order']! as int,
    );
  }

  static PropertyType _typeFromRow(Map<String, Object?> row) {
    return PropertyType(
      id: row['id']! as String,
      name: row['name']! as String,
      sortOrder: row['sort_order']! as int,
    );
  }

  static PropertyTag _tagFromRow(Map<String, Object?> row) {
    return PropertyTag(
      id: row['id']! as String,
      name: row['name']! as String,
      sortOrder: row['sort_order']! as int,
    );
  }

  static Contact _contactFromRow(Map<String, Object?> row) {
    return Contact(
      id: row['id']! as String,
      label: row['label']! as String,
      phone: row['phone']! as String,
      sortOrder: row['sort_order']! as int,
    );
  }

  static PropertyPhoto _photoFromRow(Map<String, Object?> row) {
    return PropertyPhoto(
      id: row['id']! as String,
      propertyId: row['property_id']! as String,
      relativePath: row['relative_path']! as String,
      thumbnailRelativePath: row['thumbnail_relative_path'] as String?,
      mimeType: row['mime_type'] as String?,
      width: row['width'] as int?,
      height: row['height'] as int?,
      fileSize: row['file_size'] as int?,
      sortOrder: row['sort_order']! as int,
      createdAt: _date(row['created_at'])!,
    );
  }

  static PropertyDocument _documentFromRow(Map<String, Object?> row) {
    return PropertyDocument(
      id: row['id']! as String,
      propertyId: row['property_id']! as String,
      relativePath: row['relative_path']! as String,
      originalName: row['original_name']! as String,
      thumbnailRelativePath: row['thumbnail_relative_path'] as String?,
      mimeType: row['mime_type'] as String?,
      fileSize: row['file_size'] as int?,
      sortOrder: row['sort_order']! as int,
      createdAt: _date(row['created_at'])!,
    );
  }

  static Property _propertyFromRow(
    Map<String, Object?> row, {
    required Map<String, PropertyType> typeById,
    required Map<String, PropertyTag> tagById,
    required List<String> tagIds,
    required List<Contact> contacts,
    required List<PropertyPhoto> photos,
    required List<PropertyDocument> documents,
  }) {
    final typeId = row['property_type_id']! as String;
    final resolvedTagIds = tagIds
        .where(tagById.containsKey)
        .toList(growable: false);
    final latitude = (row['latitude'] as num?)?.toDouble();
    final longitude = (row['longitude'] as num?)?.toDouble();
    final fallbackPosition = latitude == null || longitude == null
        ? null
        : GeoPoint(
            latitude: latitude,
            longitude: longitude,
          ).toLegacyNormalized();
    return Property(
      id: row['id']! as String,
      title: row['title']! as String,
      address: row['address']! as String,
      areaId: row['area_id']! as String,
      status: PropertyStatus.values.byName(row['status']! as String),
      price: (row['price']! as num).toDouble(),
      landArea: (row['land_area']! as num).toDouble(),
      propertyTypeId: typeId,
      propertyType: typeById[typeId]?.name ?? 'Chưa rõ loại BĐS',
      frontage: (row['frontage'] as num?)?.toDouble(),
      floors: row['floors'] as int?,
      tagIds: resolvedTagIds,
      tags: resolvedTagIds
          .map((id) => tagById[id]!.name)
          .toList(growable: false),
      notes: row['notes']! as String,
      surveyDate: _date(row['survey_date']),
      latitude: latitude,
      longitude: longitude,
      mapX: fallbackPosition?.x ?? 0.5,
      mapY: fallbackPosition?.y ?? 0.5,
      createdAt: _date(row['created_at'])!,
      updatedAt: _date(row['updated_at'])!,
      deletedAt: _date(row['deleted_at']),
      contacts: contacts,
      photos: photos,
      documents: documents,
      photoSeeds: const [0],
      documentSeeds: const [],
    );
  }

  static Map<String, Object?> _propertyToRow(Property property) {
    return {
      'id': property.id,
      'title': property.title,
      'address': property.address,
      'area_id': property.areaId,
      'status': property.status.name,
      'price': property.price,
      'land_area': property.landArea,
      'property_type_id': property.propertyTypeId,
      'frontage': property.frontage,
      'floors': property.floors,
      'notes': property.notes,
      'survey_date': property.surveyDate?.millisecondsSinceEpoch,
      'latitude': property.latitude,
      'longitude': property.longitude,
      'created_at': property.createdAt.millisecondsSinceEpoch,
      'updated_at': property.updatedAt.millisecondsSinceEpoch,
      'deleted_at': property.deletedAt?.millisecondsSinceEpoch,
    };
  }

  static Map<String, Object?> _photoToRow(PropertyPhoto photo) {
    return {
      'id': photo.id,
      'property_id': photo.propertyId,
      'relative_path': photo.relativePath,
      'thumbnail_relative_path': photo.thumbnailRelativePath,
      'mime_type': photo.mimeType,
      'width': photo.width,
      'height': photo.height,
      'file_size': photo.fileSize,
      'sort_order': photo.sortOrder,
      'created_at': photo.createdAt.millisecondsSinceEpoch,
    };
  }

  static Map<String, Object?> _documentToRow(PropertyDocument document) {
    return {
      'id': document.id,
      'property_id': document.propertyId,
      'relative_path': document.relativePath,
      'original_name': document.originalName,
      'thumbnail_relative_path': document.thumbnailRelativePath,
      'mime_type': document.mimeType,
      'file_size': document.fileSize,
      'sort_order': document.sortOrder,
      'created_at': document.createdAt.millisecondsSinceEpoch,
    };
  }

  static DateTime? _date(Object? value) {
    return value == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(value as int);
  }
}
