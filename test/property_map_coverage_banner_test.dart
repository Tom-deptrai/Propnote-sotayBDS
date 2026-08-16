import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/models/geo_point.dart';
import 'package:propnote/screens/map/widgets/property_map_view.dart';

const _bannerText = 'Bản đồ chưa hỗ trợ khu vực này.';

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
}
