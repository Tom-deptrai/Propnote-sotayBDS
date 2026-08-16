import 'dart:ui' as ui;

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

  testWidgets(
    'fresh sheet defaults to show-price + show-unit ON, and turning '
    'show-price off hides the unit sub-toggle',
    (tester) async {
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

      // Product default (mục 2): showPrice + showPriceUnit đều ON ngay khi
      // mở sheet lần đầu (không có initial nào khác) — unit sub-toggle phải
      // hiện sẵn, không ẩn như hành vi cũ.
      expect(find.text('Hiển thị giá'), findsOneWidget);
      expect(find.text('Hiển thị đơn vị tỷ'), findsOneWidget);

      await tester.tap(find.text('Hiển thị giá'));
      await tester.pumpAndSettle();
      expect(find.text('Hiển thị đơn vị tỷ'), findsNothing);

      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(result?.showPrice, isFalse);
      expect(result?.showPriceUnit, isTrue);
    },
  );

  testWidgets(
    'reset button restores showPrice/showPriceUnit to the new ON/ON default',
    (tester) async {
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
                    result = await showAdvancedFilterSheet(
                      context,
                      initial: const MapAdvancedFilter(showPrice: false),
                    );
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
      expect(find.text('Hiển thị đơn vị tỷ'), findsNothing);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Đặt lại'));
      await tester.pumpAndSettle();
      expect(find.text('Hiển thị đơn vị tỷ'), findsOneWidget);

      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(result?.showPrice, isTrue);
      expect(result?.showPriceUnit, isTrue);
    },
  );

  test(
    'MapAdvancedFilter.isDefault accounts for the price display toggles',
    () {
      expect(const MapAdvancedFilter().isDefault, isTrue);
      expect(const MapAdvancedFilter(showPrice: false).isDefault, isFalse);
      expect(const MapAdvancedFilter(showPriceUnit: false).isDefault, isFalse);
    },
  );

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

  test('property marker icon is rendered at ~2x the pre-Đợt-1.1 baseline size '
      'across the full markerScale range, and grows with scale', () async {
    final factory = PropertyMapMarkerIcons();
    const dpr = 2.0;

    Future<int> widthFor(double scale) async {
      final (bytes, _) = await factory.iconFor(
        status: PropertyStatus.selling,
        scale: scale,
        devicePixelRatio: dpr,
      );
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final width = frame.image.width;
      frame.image.dispose();
      return width;
    }

    final minWidth = await widthFor(AppState.markerScaleMin);
    final defaultWidth = await widthFor(AppState.markerScaleDefault);
    final maxWidth = await widthFor(AppState.markerScaleMax);

    // Baseline (trước Đợt 1.1) render ở logicalSize*dpr với logicalSize
    // clamp [20,45]; sau khi x2 là clamp [40,90] — kiểm tra đúng biên mới.
    expect(minWidth, greaterThanOrEqualTo((40.0 * dpr).round() - 1));
    expect(maxWidth, lessThanOrEqualTo((90.0 * dpr).round() + 1));
    expect(minWidth, lessThan(defaultWidth));
    expect(defaultWidth, lessThan(maxWidth));

    // So với vùng baseline cũ (clamp [20,45] * dpr), icon mới phải lớn
    // hơn nhiều hơn hệ số 1.5x ở cả hai đầu range — xác nhận việc x2 có
    // hiệu lực thật trên bitmap, không chỉ trên số lý thuyết.
    const oldMinWidth = 20.0 * dpr;
    const oldMaxWidth = 45.0 * dpr;
    expect(minWidth, greaterThan(oldMinWidth * 1.5));
    expect(maxWidth, greaterThan(oldMaxWidth * 1.5));
  });
}
