import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/data/database/app_database.dart';
import 'package:propnote/data/repositories/sqlite_app_repository.dart';
import 'package:propnote/data/services/app_directories.dart';
import 'package:propnote/models/geo_point.dart';
import 'package:propnote/models/property.dart';
import 'package:propnote/models/property_status.dart';
import 'package:propnote/screens/map/map_screen.dart';
import 'package:propnote/utils/formatters.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _pointA = GeoPoint(latitude: 21.0285, longitude: 105.8542); // Hà Nội
const _pointB = GeoPoint(latitude: 10.7769, longitude: 106.7009); // TP.HCM

void main() {
  sqfliteFfiInit();

  late Directory temporary;
  late AppDirectories directories;
  late AppDatabase database;
  late SqliteAppRepository repository;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp(
      'propnote_marker_pos_test_',
    );
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

  test('two properties saved at distinct lat/lng stay distinct across reload, '
      'and editing one does not move the other', () async {
    final snapshot = await repository.loadSnapshot();
    final type = snapshot.propertyTypes.first;
    final area = snapshot.areas.first;
    final now = DateTime(2026, 8, 16);

    Property propertyAt(String id, GeoPoint point) => Property(
      id: id,
      title: 'BĐS $id',
      address: 'BĐS $id',
      areaId: area.id,
      status: PropertyStatus.selling,
      price: 1e9,
      landArea: 50,
      propertyTypeId: type.id,
      propertyType: type.name,
      latitude: point.latitude,
      longitude: point.longitude,
      createdAt: now,
    );

    await repository.saveProperty(propertyAt('property-a', _pointA));
    await repository.saveProperty(propertyAt('property-b', _pointB));
    await database.close();

    var reloaded = await repository.loadSnapshot();
    final a = reloaded.properties.firstWhere((p) => p.id == 'property-a');
    final b = reloaded.properties.firstWhere((p) => p.id == 'property-b');
    expect(a.location, _pointA);
    expect(b.location, _pointB);
    expect(a.location, isNot(b.location));

    // Editing A's location must not move B.
    await repository.saveProperty(
      propertyAt(
        'property-a',
        const GeoPoint(latitude: 16.0544, longitude: 108.2022), // Đà Nẵng
      ),
    );
    reloaded = await repository.loadSnapshot();
    final movedA = reloaded.properties.firstWhere((p) => p.id == 'property-a');
    final untouchedB = reloaded.properties.firstWhere(
      (p) => p.id == 'property-b',
    );
    expect(
      movedA.location,
      const GeoPoint(latitude: 16.0544, longitude: 108.2022),
    );
    expect(untouchedB.location, _pointB);
  });

  test('buildPropertyMarkers maps each distinct-location property to its own '
      'marker position, independent of the map renderer', () {
    final now = DateTime(2026, 8, 16);
    Property propertyAt(String id, GeoPoint point, PropertyStatus status) =>
        Property(
          id: id,
          title: 'BĐS $id',
          address: 'BĐS $id',
          areaId: 'area-1',
          status: status,
          price: 1e9,
          landArea: 50,
          propertyTypeId: 'type-1',
          propertyType: 'Nhà phố',
          latitude: point.latitude,
          longitude: point.longitude,
          createdAt: now,
        );

    final properties = [
      propertyAt('marker-a', _pointA, PropertyStatus.selling),
      propertyAt('marker-b', _pointB, PropertyStatus.unsurveyed),
    ];

    final markers = buildPropertyMarkers(
      properties: properties,
      currentLocation: null,
      onMarkerTap: (_) {},
    );

    expect(markers, hasLength(2));
    final markerA = markers.firstWhere((m) => m.id == 'marker-a');
    final markerB = markers.firstWhere((m) => m.id == 'marker-b');
    expect(markerA.position, _pointA);
    expect(markerB.position, _pointB);
    expect(markerA.position, isNot(markerB.position));
    expect(markerA.status, PropertyStatus.selling);
    expect(markerB.status, PropertyStatus.unsurveyed);
  });

  test(
    'buildPropertyMarkers skips properties without a location and adds a '
    'separate current-location marker that never collides with a property id',
    () {
      final now = DateTime(2026, 8, 16);
      final withLocation = Property(
        id: 'has-location',
        title: 'Có vị trí',
        address: 'Có vị trí',
        areaId: 'area-1',
        status: PropertyStatus.sold,
        price: 1e9,
        landArea: 50,
        propertyTypeId: 'type-1',
        propertyType: 'Nhà phố',
        latitude: _pointA.latitude,
        longitude: _pointA.longitude,
        createdAt: now,
      );
      final withoutLocation = Property(
        id: 'no-location',
        title: 'Chưa có vị trí',
        address: 'Chưa có vị trí',
        areaId: 'area-1',
        status: PropertyStatus.unsurveyed,
        price: 1e9,
        landArea: 50,
        propertyTypeId: 'type-1',
        propertyType: 'Nhà phố',
        createdAt: now,
      );

      final markers = buildPropertyMarkers(
        properties: [withLocation, withoutLocation],
        currentLocation: _pointB,
        onMarkerTap: (_) {},
      );

      expect(markers, hasLength(2));
      expect(markers.any((m) => m.id == 'no-location'), isFalse);
      final currentLocationMarker = markers.firstWhere(
        (m) => m.isCurrentLocation,
      );
      expect(currentLocationMarker.position, _pointB);
      expect(currentLocationMarker.id, isNot('has-location'));
    },
  );

  test('buildPropertyMarkers stays fast and produces one distinct marker per '
      'property with a ~300-property dataset (performance sanity check)', () {
    final now = DateTime(2026, 8, 16);
    final properties = [
      for (var i = 0; i < 300; i++)
        Property(
          id: 'volume-$i',
          title: 'Nhà mẫu $i',
          address: 'Đường thử nghiệm ${i % 30}',
          areaId: 'area-1',
          status: PropertyStatus.values[i % PropertyStatus.values.length],
          price: 1e9 + i * 1e7,
          landArea: 30 + i % 100,
          propertyTypeId: 'type-1',
          propertyType: 'Nhà phố',
          latitude: 20.9 + (i % 20) * 0.01,
          longitude: 105.7 + (i % 20) * 0.01,
          createdAt: now,
        ),
    ];

    final stopwatch = Stopwatch()..start();
    final markers = buildPropertyMarkers(
      properties: properties,
      currentLocation: _pointA,
      onMarkerTap: (_) {},
    );
    stopwatch.stop();

    expect(markers, hasLength(301)); // 300 BĐS + 1 marker vị trí hiện tại
    expect(markers.map((m) => m.id).toSet(), hasLength(301));
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(milliseconds: 500)),
      reason: 'buildPropertyMarkers took ${stopwatch.elapsed} for 300 BĐS',
    );
  });

  test(
    'current-location marker is a toggle: absent when the toggle is OFF '
    '(currentLocation: null), present exactly once when ON — mirrors the '
    'ON/OFF button on Map Screen, which never re-fetches GPS just to hide it',
    () {
      final now = DateTime(2026, 8, 16);
      final property = Property(
        id: 'toggle-property',
        title: 'BĐS toggle',
        address: 'BĐS toggle',
        areaId: 'area-1',
        status: PropertyStatus.selling,
        price: 1e9,
        landArea: 50,
        propertyTypeId: 'type-1',
        propertyType: 'Nhà phố',
        latitude: _pointA.latitude,
        longitude: _pointA.longitude,
        createdAt: now,
      );

      final markersOff = buildPropertyMarkers(
        properties: [property],
        currentLocation: null,
        onMarkerTap: (_) {},
      );
      expect(markersOff, hasLength(1));
      expect(markersOff.any((m) => m.isCurrentLocation), isFalse);

      final markersOn = buildPropertyMarkers(
        properties: [property],
        currentLocation: _pointB,
        onMarkerTap: (_) {},
      );
      expect(markersOn, hasLength(2));
      expect(markersOn.where((m) => m.isCurrentLocation), hasLength(1));
      expect(
        markersOn.firstWhere((m) => m.isCurrentLocation).position,
        _pointB,
      );
    },
  );

  test('every property with a location always produces a marker regardless of '
      'its price, and formatMarkerPrice (which the renderer consults for the '
      'separate price label) never controls whether that marker exists', () {
    final now = DateTime(2026, 8, 16);
    Property propertyWithPrice(String id, double price) => Property(
      id: id,
      title: 'BĐS $id',
      address: 'BĐS $id',
      areaId: 'area-1',
      status: PropertyStatus.selling,
      price: price,
      landArea: 50,
      propertyTypeId: 'type-1',
      propertyType: 'Nhà phố',
      latitude: _pointA.latitude,
      longitude: _pointA.longitude,
      createdAt: now,
    );

    final properties = [
      propertyWithPrice('no-price', 0),
      propertyWithPrice('negative-price', -1),
      propertyWithPrice('normal-price', 10.5e9),
    ];

    final markers = buildPropertyMarkers(
      properties: properties,
      currentLocation: null,
      onMarkerTap: (_) {},
    );

    // Marker luôn tồn tại cho mọi BĐS có vị trí, bất kể giá.
    expect(markers.map((m) => m.id).toSet(), {
      'no-price',
      'negative-price',
      'normal-price',
    });

    // Trong khi đó, label giá (formatMarkerPrice) trả về null cho giá
    // không hợp lệ — renderer bỏ qua label ở những trường hợp này nhưng
    // marker (chấm trạng thái) vẫn luôn được vẽ.
    expect(formatMarkerPrice(0, withUnit: true), isNull);
    expect(formatMarkerPrice(-1, withUnit: true), isNull);
    expect(formatMarkerPrice(10.5e9, withUnit: true), isNotNull);
  });
}
