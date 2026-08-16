import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/data/services/map/map_coverage_policy.dart';
import 'package:propnote/models/geo_point.dart';
import 'package:propnote/models/property_status.dart';
import 'package:propnote/screens/map/widgets/property_map_view.dart';

const _bannerText = 'Bản đồ chưa hỗ trợ khu vực này.';

// Toạ độ thật của 1 BĐS "cũ" đã lưu trước khi vùng phủ PMTiles tồn tại (vd.
// Đà Lạt) — đại diện mục 18: BĐS ngoài vùng phủ vẫn phải mở được, hiển thị
// đúng marker, không crash, và toạ độ (nguồn xác nhận trực tiếp cho việc lưu
// trữ/backup — không phụ thuộc renderer bản đồ) không hề bị đổi.
const _daLatProperty = GeoPoint(latitude: 11.940, longitude: 108.458);

void main() {
  testWidgets(
    'a target outside every SupportedMapRegion shows the coverage banner',
    (tester) async {
      const daLat = GeoPoint(latitude: 11.940, longitude: 108.458);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PropertyMapView(initialTarget: daLat)),
        ),
      );
      await tester.pump();

      expect(find.text(_bannerText), findsOneWidget);
    },
  );

  testWidgets(
    'a target inside a SupportedMapRegion does NOT show the coverage banner',
    (tester) async {
      const hcmc = GeoPoint(latitude: 10.7769, longitude: 106.7009);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PropertyMapView(initialTarget: hcmc)),
        ),
      );
      await tester.pump();

      expect(find.text(_bannerText), findsNothing);
    },
  );

  testWidgets(
    'showCoverageBanner: false suppresses the banner even outside coverage '
    '(used by MiniMapPreview, which has no room for it)',
    (tester) async {
      const daLat = GeoPoint(latitude: 11.940, longitude: 108.458);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropertyMapView(
              initialTarget: daLat,
              showCoverageBanner: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(_bannerText), findsNothing);
    },
  );

  testWidgets(
    'an existing property outside every SupportedMapRegion renders its '
    'marker + the coverage banner without throwing, and keeps its original '
    'coordinate untouched (mục 18: BĐS cũ ngoài vùng phủ PMTiles)',
    (tester) async {
      expect(MapCoveragePolicy.isSupported(_daLatProperty), isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyMapView(
              initialTarget: _daLatProperty,
              markers: const [
                PropertyMapMarkerData(
                  id: 'p-da-lat',
                  position: _daLatProperty,
                  status: PropertyStatus.selling,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // Không có exception nào bắn ra trong lúc dựng + render marker ngoài
      // vùng phủ (FlutterError.onError sẽ tự fail test nếu có).
      expect(find.text(_bannerText), findsOneWidget);
      expect(_daLatProperty.latitude, 11.940);
      expect(_daLatProperty.longitude, 108.458);
      expect(_daLatProperty.isValid, isTrue);
    },
  );
}
