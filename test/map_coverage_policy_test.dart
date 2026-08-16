import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/data/services/map/map_coverage_policy.dart';
import 'package:propnote/models/geo_point.dart';

void main() {
  group('MapCoveragePolicy.regionContaining', () {
    test('a point inside HCM bbox resolves to the HCM region', () {
      const point = GeoPoint(latitude: 10.772, longitude: 106.698); // Bến Thành
      expect(MapCoveragePolicy.regionContaining(point)?.id, 'hcm');
    });

    test('a point inside Hanoi bbox resolves to the Hanoi region', () {
      const point = GeoPoint(latitude: 21.028, longitude: 105.854); // Hoàn Kiếm
      expect(MapCoveragePolicy.regionContaining(point)?.id, 'hanoi');
    });

    test('a point far from both regions resolves to null (unsupported)', () {
      const daLat = GeoPoint(latitude: 11.940, longitude: 108.458);
      expect(MapCoveragePolicy.regionContaining(daLat), isNull);
      expect(MapCoveragePolicy.isSupported(daLat), isFalse);
    });

    test('bbox edges are inclusive', () {
      const hcm = MapCoveragePolicy.hcm;
      final northEdge = GeoPoint(
        latitude: hcm.north,
        longitude: (hcm.west + hcm.east) / 2,
      );
      expect(hcm.contains(northEdge), isTrue);
      final justOutsideNorth = GeoPoint(
        latitude: hcm.north + 0.001,
        longitude: (hcm.west + hcm.east) / 2,
      );
      expect(hcm.contains(justOutsideNorth), isFalse);
    });

    test('HCM and Hanoi bboxes do not overlap', () {
      const hcm = MapCoveragePolicy.hcm;
      const hanoi = MapCoveragePolicy.hanoi;
      final overlapsLat = hcm.south <= hanoi.north && hanoi.south <= hcm.north;
      final overlapsLng = hcm.west <= hanoi.east && hanoi.west <= hcm.east;
      expect(overlapsLat && overlapsLng, isFalse);
    });
  });

  group('MapCoveragePolicy.nearestRegion', () {
    test('a point inside a region resolves to that exact region', () {
      const point = GeoPoint(latitude: 10.772, longitude: 106.698);
      expect(MapCoveragePolicy.nearestRegion(point).id, 'hcm');
    });

    test('a point outside every region still resolves to a non-null nearest '
        'region (never throws / never returns null)', () {
      const daLat = GeoPoint(latitude: 11.940, longitude: 108.458);
      final region = MapCoveragePolicy.nearestRegion(daLat);
      expect(region, isNotNull);
      // Đà Lạt gần TP.HCM hơn Hà Nội về mặt địa lý.
      expect(region.id, 'hcm');
    });

    test('nearestRegion never mutates or clamps the input coordinate — it '
        'only picks which local map to open, GeoPoint itself stays intact',
        () {
      const original = GeoPoint(latitude: 11.940, longitude: 108.458);
      MapCoveragePolicy.nearestRegion(original);
      // GeoPoint là immutable — gọi nearestRegion không có cách nào sửa được
      // giá trị gốc; assertion này ghi lại rõ ràng hợp đồng đó cho người đọc
      // test sau này.
      expect(original.latitude, 11.940);
      expect(original.longitude, 108.458);
    });
  });

  group('SupportedMapRegion coverage constants', () {
    test('HCM bbox/zoom matches the approved production spec', () {
      const hcm = MapCoveragePolicy.hcm;
      expect(hcm.west, 106.42);
      expect(hcm.south, 10.60);
      expect(hcm.east, 106.95);
      expect(hcm.north, 11.05);
      expect(hcm.minZoom, 9.6);
      expect(hcm.maxZoom, 18.0);
    });

    test('Hanoi bbox/zoom matches the approved production spec (extended '
        'south edge)', () {
      const hanoi = MapCoveragePolicy.hanoi;
      expect(hanoi.west, 105.45);
      expect(hanoi.south, 20.756);
      expect(hanoi.east, 106.05);
      expect(hanoi.north, 21.30);
      expect(hanoi.minZoom, 9.4);
      expect(hanoi.maxZoom, 18.0);
    });
  });
}
