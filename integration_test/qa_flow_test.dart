import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:propnote/main.dart';
import 'package:propnote/models/list_sort_option.dart';
import 'package:propnote/screens/map/widgets/map_marker.dart';
import 'package:propnote/state/app_state.dart';
import 'package:propnote/theme/app_colors.dart';
import 'package:propnote/widgets/property_card.dart';
import 'package:provider/provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const PropNoteApp());
    await tester.pump(const Duration(milliseconds: 800));
  }

  Future<void> finishTransition(WidgetTester tester) {
    return tester.pump(const Duration(milliseconds: 500));
  }

  Finder fieldWithHint(String hint) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
  }

  Finder listScrollable() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          widget.restorationId != 'editable' &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
    );
  }

  testWidgets('map marker slider updates, stays bounded, and resets', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await finishTransition(tester);

    var slider = tester.widget<Slider>(find.byType(Slider));
    final state = Provider.of<AppState>(
      tester.element(find.byType(Slider)),
      listen: false,
    );
    expect(slider.value, AppState.markerScaleDefault);
    expect(
      (slider.value - slider.min) / (slider.max - slider.min),
      closeTo(0.5, 1e-9),
    );

    slider.onChanged!(AppState.markerScaleMin);
    await tester.pump();
    expect(state.markerScale, AppState.markerScaleMin);
    expect(
      PropertyMarker.hitBoxFor(state.markerScale),
      greaterThanOrEqualTo(30),
    );

    slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(AppState.markerScaleMax);
    await tester.pump();
    expect(state.markerScale, AppState.markerScaleMax);
    expect(PropertyMarker.hitBoxFor(state.markerScale), lessThanOrEqualTo(60));

    await tester.tap(find.text('Đặt lại').first);
    await tester.pump();
    expect(state.markerScale, AppState.markerScaleDefault);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add form handles decimals, keyboard dismissal, and reorder', (
    tester,
  ) async {
    await pumpApp(tester);
    final state = Provider.of<AppState>(
      tester.element(find.byIcon(Icons.add_rounded)),
      listen: false,
    );
    await tester.tap(find.byIcon(Icons.add_rounded));
    await finishTransition(tester);

    final frontage = fieldWithHint('4,2');
    await tester.scrollUntilVisible(
      frontage,
      250,
      scrollable: listScrollable().last,
    );
    await tester.tap(frontage);
    tester.testTextInput.enterText('4.2');
    await tester.pump();
    expect(tester.widget<TextField>(frontage).controller?.text, '4,2');
    expect(find.text('Xong'), findsOneWidget);
    expect(find.text('Lưu bất động sản'), findsOneWidget);
    await tester.tap(find.text('Xong'));
    await tester.pump();
    expect(tester.widget<TextField>(frontage).focusNode?.hasFocus, isFalse);

    final firstType = state.propertyTypes.first;
    await tester.scrollUntilVisible(
      find.text('Loại bất động sản'),
      -200,
      scrollable: listScrollable().last,
    );
    final typeRow = find
        .ancestor(
          of: find.text('Loại bất động sản'),
          matching: find.byType(Row),
        )
        .first;
    await tester.tap(
      find.descendant(of: typeRow, matching: find.text('Quản lý')),
    );
    await finishTransition(tester);
    var handle = find.byIcon(Icons.drag_indicator_rounded).first;
    var gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 120));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await finishTransition(tester);
    expect(state.propertyTypes.first, isNot(firstType));

    await tester.tapAt(const Offset(8, 8));
    await finishTransition(tester);
    final firstTag = state.tagOptions.first;
    await tester.scrollUntilVisible(
      find.text('Tags'),
      250,
      scrollable: listScrollable().last,
    );
    final tagRow = find
        .ancestor(of: find.text('Tags'), matching: find.byType(Row))
        .first;
    await tester.tap(
      find.descendant(of: tagRow, matching: find.text('Quản lý')),
    );
    await finishTransition(tester);
    handle = find.byIcon(Icons.drag_indicator_rounded).first;
    gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 120));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await finishTransition(tester);
    expect(state.tagOptions.first, isNot(firstTag));
    expect(tester.takeException(), isNull);
  });

  testWidgets('list cards and all six sort options work end to end', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Danh sách'));
    await finishTransition(tester);

    expect(find.text('Chưa khảo sát'), findsWidgets);
    expect(
      tester.widget<PropertyCard>(find.byType(PropertyCard).first).property.id,
      'p13',
    );
    await tester.scrollUntilVisible(
      find.text('Khảo sát: 09/08/2026'),
      250,
      scrollable: listScrollable().last,
    );
    expect(find.text('Khảo sát: 09/08/2026'), findsOneWidget);

    Future<void> chooseSort(
      ListSortOption option,
      String expectedFirstId,
    ) async {
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await finishTransition(tester);
      for (final choice in ListSortOption.values) {
        expect(find.text(choice.label), findsOneWidget);
      }
      await tester.tap(find.text(option.label));
      await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await finishTransition(tester);
      tester.state<ScrollableState>(listScrollable().last).position.jumpTo(0);
      await tester.pump();
      expect(
        tester
            .widget<PropertyCard>(find.byType(PropertyCard).first)
            .property
            .id,
        expectedFirstId,
      );
    }

    await chooseSort(ListSortOption.oldest, 'p9');
    await chooseSort(ListSortOption.priceHighToLow, 'p3');
    await chooseSort(ListSortOption.priceLowToHigh, 'p7');
    await chooseSort(ListSortOption.areaLargeToSmall, 'p3');
    await chooseSort(ListSortOption.areaSmallToLarge, 'p10');

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await finishTransition(tester);
    await tester.tap(find.text('Đặt lại'));
    await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await finishTransition(tester);
    tester.state<ScrollableState>(listScrollable().last).position.jumpTo(0);
    await tester.pump();
    expect(
      tester.widget<PropertyCard>(find.byType(PropertyCard).first).property.id,
      'p13',
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.tune_rounded)).color,
      AppColors.textTertiary,
    );
    expect(tester.takeException(), isNull);
  });
}
