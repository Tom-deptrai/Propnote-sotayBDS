import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/models/property_status.dart';
import 'package:propnote/screens/map/widgets/advanced_filter_sheet.dart';
import 'package:propnote/screens/map/widgets/map_marker.dart';
import 'package:propnote/screens/map/widgets/property_map_marker_icons.dart';
import 'package:propnote/state/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('marker slider is centered, updates live, and resets', (
    tester,
  ) async {
    final state = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showAdvancedFilterSheet(context),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    var slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, AppState.markerScaleDefault);
    expect(
      (slider.value - slider.min) / (slider.max - slider.min),
      closeTo(0.5, 1e-9),
    );

    slider.onChanged!(AppState.markerScaleMax);
    await tester.pump();
    expect(state.markerScale, AppState.markerScaleMax);
    slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, AppState.markerScaleMax);

    await tester.tap(find.text('Đặt lại').first);
    await tester.pump();
    expect(state.markerScale, AppState.markerScaleDefault);
  });

  test('property and cluster marker sizes respond within safe bounds', () {
    expect(
      PropertyMarker.hitBoxFor(AppState.markerScaleMin),
      lessThan(PropertyMarker.hitBoxFor(AppState.markerScaleDefault)),
    );
    expect(
      PropertyMarker.hitBoxFor(AppState.markerScaleDefault),
      lessThan(PropertyMarker.hitBoxFor(AppState.markerScaleMax)),
    );
    expect(
      PropertyMarker.hitBoxFor(AppState.markerScaleMin),
      greaterThanOrEqualTo(30),
    );
    expect(
      PropertyMarker.hitBoxFor(AppState.markerScaleMax),
      lessThanOrEqualTo(60),
    );

    expect(
      MapClusterMarker.sizeFor(15, AppState.markerScaleMin),
      lessThan(MapClusterMarker.sizeFor(15, AppState.markerScaleDefault)),
    );
    expect(
      MapClusterMarker.sizeFor(15, AppState.markerScaleDefault),
      lessThan(MapClusterMarker.sizeFor(15, AppState.markerScaleMax)),
    );
  });

  testWidgets('advanced map filter returns persisted price and type choices', (
    tester,
  ) async {
    final state = AppState();
    MapAdvancedFilter? result;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showAdvancedFilterSheet(context);
                },
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(state.propertyTypes.first));
    final rangeSlider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    rangeSlider.onChanged!(const RangeValues(5, 20));
    await tester.pump();
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();

    expect(result?.minimumPriceBillions, 5);
    expect(result?.maximumPriceBillions, 20);
    expect(result?.propertyTypes, contains(state.propertyTypes.first));
  });

  test('Property marker cache keys include status, scale, and pixel ratio', () {
    final factory = PropertyMapMarkerIcons();
    final selling = factory.cacheKey(PropertyStatus.selling, 1, 3);

    expect(selling, isNot(factory.cacheKey(PropertyStatus.unsurveyed, 1, 3)));
    expect(selling, isNot(factory.cacheKey(PropertyStatus.selling, 1.2, 3)));
    expect(selling, isNot(factory.cacheKey(PropertyStatus.selling, 1, 2)));
    expect(PropertyStatus.selling.color, const Color(0xFFD92D20));
    expect(PropertyStatus.unsurveyed.color, const Color(0xFF17B26A));
    expect(PropertyStatus.sold.color, const Color(0xFF98A2B3));
  });
}
