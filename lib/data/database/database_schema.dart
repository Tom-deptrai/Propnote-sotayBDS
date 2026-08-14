import 'package:sqflite/sqflite.dart';

/// Schema SQLite của PropNote.
///
/// Mỗi migration phải tiến về phía trước và không được drop dữ liệu người dùng.
abstract final class DatabaseSchema {
  static const int version = 2;
  static const int seedVersion = 1;
  static final Map<int, Future<void> Function(Database)> _migrations = {
    2: (db) => db.execute(
      'CREATE INDEX IF NOT EXISTS idx_properties_updated_at '
      'ON properties(updated_at DESC)',
    ),
  };

  static Future<void> create(Database db) async {
    final batch = db.batch()
      ..execute('''
        CREATE TABLE areas (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''')
      ..execute('''
        CREATE TABLE property_types (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''')
      ..execute('''
        CREATE TABLE tags (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''')
      ..execute('''
        CREATE TABLE properties (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          address TEXT NOT NULL,
          area_id TEXT NOT NULL,
          status TEXT NOT NULL CHECK (
            status IN ('selling', 'unsurveyed', 'sold')
          ),
          price REAL NOT NULL DEFAULT 0 CHECK (price >= 0),
          land_area REAL NOT NULL DEFAULT 0 CHECK (land_area >= 0),
          property_type_id TEXT NOT NULL,
          frontage REAL,
          floors INTEGER,
          notes TEXT NOT NULL DEFAULT '',
          survey_date INTEGER,
          latitude REAL CHECK (
            latitude IS NULL OR (latitude >= -90 AND latitude <= 90)
          ),
          longitude REAL CHECK (
            longitude IS NULL OR (longitude >= -180 AND longitude <= 180)
          ),
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER,
          FOREIGN KEY (area_id) REFERENCES areas(id)
            ON UPDATE CASCADE ON DELETE RESTRICT,
          FOREIGN KEY (property_type_id) REFERENCES property_types(id)
            ON UPDATE CASCADE ON DELETE RESTRICT
        )
      ''')
      ..execute('''
        CREATE TABLE property_tags (
          property_id TEXT NOT NULL,
          tag_id TEXT NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (property_id, tag_id),
          FOREIGN KEY (property_id) REFERENCES properties(id)
            ON UPDATE CASCADE ON DELETE CASCADE,
          FOREIGN KEY (tag_id) REFERENCES tags(id)
            ON UPDATE CASCADE ON DELETE CASCADE
        )
      ''')
      ..execute('''
        CREATE TABLE contacts (
          id TEXT PRIMARY KEY,
          property_id TEXT NOT NULL,
          label TEXT NOT NULL,
          phone TEXT NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (property_id) REFERENCES properties(id)
            ON UPDATE CASCADE ON DELETE CASCADE
        )
      ''')
      ..execute('''
        CREATE TABLE property_photos (
          id TEXT PRIMARY KEY,
          property_id TEXT NOT NULL,
          relative_path TEXT NOT NULL UNIQUE,
          thumbnail_relative_path TEXT,
          mime_type TEXT,
          width INTEGER,
          height INTEGER,
          file_size INTEGER,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (property_id) REFERENCES properties(id)
            ON UPDATE CASCADE ON DELETE CASCADE
        )
      ''')
      ..execute('''
        CREATE TABLE property_documents (
          id TEXT PRIMARY KEY,
          property_id TEXT NOT NULL,
          relative_path TEXT NOT NULL UNIQUE,
          original_name TEXT NOT NULL,
          thumbnail_relative_path TEXT,
          mime_type TEXT,
          file_size INTEGER,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (property_id) REFERENCES properties(id)
            ON UPDATE CASCADE ON DELETE CASCADE
        )
      ''')
      ..execute('''
        CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''')
      ..execute(
        'CREATE INDEX idx_properties_deleted_at '
        'ON properties(deleted_at)',
      )
      ..execute(
        'CREATE INDEX idx_properties_status_deleted '
        'ON properties(status, deleted_at)',
      )
      ..execute(
        'CREATE INDEX idx_properties_area_deleted '
        'ON properties(area_id, deleted_at)',
      )
      ..execute(
        'CREATE INDEX idx_properties_type_deleted '
        'ON properties(property_type_id, deleted_at)',
      )
      ..execute(
        'CREATE INDEX idx_properties_created_at '
        'ON properties(created_at DESC)',
      )
      ..execute(
        'CREATE INDEX idx_properties_updated_at '
        'ON properties(updated_at DESC)',
      )
      ..execute(
        'CREATE INDEX idx_properties_survey_date '
        'ON properties(survey_date DESC)',
      )
      ..execute(
        'CREATE INDEX idx_property_tags_tag_id ON property_tags(tag_id)',
      )
      ..execute(
        'CREATE INDEX idx_contacts_property_id ON contacts(property_id)',
      )
      ..execute(
        'CREATE INDEX idx_property_photos_property_order '
        'ON property_photos(property_id, sort_order)',
      )
      ..execute(
        'CREATE INDEX idx_property_documents_property_order '
        'ON property_documents(property_id, sort_order)',
      );
    await batch.commit(noResult: true);
    await seedDefaults(db);
  }

  static Future<void> seedDefaults(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();

    const areas = [
      ('area_cau_giay', 'Cầu Giấy'),
      ('area_nam_tu_liem', 'Nam Từ Liêm'),
      ('area_ha_dong', 'Hà Đông'),
      ('area_thanh_xuan', 'Thanh Xuân'),
      ('area_dong_da', 'Đống Đa'),
    ];
    for (var i = 0; i < areas.length; i++) {
      batch.insert('areas', {
        'id': areas[i].$1,
        'name': areas[i].$2,
        'sort_order': i,
        'created_at': now,
        'updated_at': now,
      });
    }

    const types = [
      ('type_nha_pho', 'Nhà phố'),
      ('type_nha_ngo', 'Nhà ngõ'),
      ('type_nha_mat_pho', 'Nhà mặt phố'),
      ('type_biet_thu', 'Biệt thự'),
      ('type_lien_ke', 'Liền kề'),
      ('type_chung_cu', 'Chung cư'),
      ('type_dat_nen', 'Đất nền'),
      ('type_nha_cap_4', 'Nhà cấp 4'),
    ];
    for (var i = 0; i < types.length; i++) {
      batch.insert('property_types', {
        'id': types[i].$1,
        'name': types[i].$2,
        'sort_order': i,
        'created_at': now,
        'updated_at': now,
      });
    }

    const tags = [
      ('tag_o_to_vao', 'Ô tô vào'),
      ('tag_nha_dep', 'Nhà đẹp'),
      ('tag_kinh_doanh', 'Kinh doanh'),
      ('tag_mat_pho', 'Mặt phố'),
      ('tag_goc', 'Góc'),
    ];
    for (var i = 0; i < tags.length; i++) {
      batch.insert('tags', {
        'id': tags[i].$1,
        'name': tags[i].$2,
        'sort_order': i,
        'created_at': now,
        'updated_at': now,
      });
    }

    batch.insert('app_settings', {
      'key': 'seed_version',
      'value': '$seedVersion',
      'updated_at': now,
    });
    batch.insert('app_settings', {
      'key': 'marker_scale',
      'value': '1.0',
      'updated_at': now,
    });
    await batch.commit(noResult: true);
  }

  static Future<void> upgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    for (var target = oldVersion + 1; target <= newVersion; target++) {
      final migration = _migrations[target];
      if (migration == null) {
        throw StateError('Thiếu migration SQLite tới schema v$target');
      }
      await migration(db);
    }
  }
}
