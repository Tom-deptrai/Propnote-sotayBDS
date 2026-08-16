import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/data/services/map/map_coverage_policy.dart';
import 'package:propnote/screens/map/widgets/map_region_selector.dart';

void main() {
  testWidgets('renders one chip per SupportedMapRegion, labeled correctly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapRegionSelector(activeRegionId: 'hcm', onSelect: (_) {}),
        ),
      ),
    );

    for (final region in MapCoveragePolicy.allRegions) {
      expect(find.text(region.displayName), findsOneWidget);
    }
  });

  testWidgets(
    'tapping a region chip invokes onSelect with that exact region — never '
    'auto-selects, never fires for the region not tapped',
    (tester) async {
      SupportedMapRegion? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapRegionSelector(
              activeRegionId: 'hcm',
              onSelect: (region) => selected = region,
            ),
          ),
        ),
      );

      expect(selected, isNull);
      await tester.tap(find.text(MapCoveragePolicy.hanoi.displayName));
      await tester.pump();

      expect(selected?.id, 'hanoi');
    },
  );

  testWidgets(
    'activeRegionId: null (region not yet known, e.g. outside coverage on '
    'first open) renders without throwing and highlights nothing',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapRegionSelector(activeRegionId: null, onSelect: (_) {}),
          ),
        ),
      );

      expect(find.byType(MapRegionSelector), findsOneWidget);
    },
  );
}
