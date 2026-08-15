import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/models/geo_point.dart';
import 'package:propnote/models/property_status.dart';
import 'package:propnote/screens/map/widgets/property_map_view.dart';
import 'package:propnote/widgets/mini_map_preview.dart';

const _hanoi = GeoPoint(latitude: 21.0285, longitude: 105.8542);
const _hcmc = GeoPoint(latitude: 10.7769, longitude: 106.7009);

void main() {
  testWidgets(
    'MiniMapPreview opts its PropertyMapView into camera-follow so the '
    'camera tracks a new location prop instead of staying on the old one',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniMapPreview(
              location: _hanoi,
              status: PropertyStatus.selling,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final view = tester.widget<PropertyMapView>(find.byType(PropertyMapView));
      expect(view.followInitialTargetChanges, isTrue);
      expect(view.initialTarget, _hanoi);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniMapPreview(
              location: _hcmc,
              status: PropertyStatus.selling,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final updatedView = tester.widget<PropertyMapView>(
        find.byType(PropertyMapView),
      );
      expect(updatedView.initialTarget, _hcmc);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the interactive Map Screen renderer does NOT auto-follow initialTarget '
    'by default, so it will not re-center itself whenever the visible '
    'property list changes underneath the user',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PropertyMapView(initialTarget: _hanoi)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final view = tester.widget<PropertyMapView>(find.byType(PropertyMapView));
      expect(view.followInitialTargetChanges, isFalse);
    },
  );
}
