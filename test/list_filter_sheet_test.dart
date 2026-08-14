import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/models/list_sort_option.dart';
import 'package:propnote/screens/list/widgets/list_filter_sheet.dart';

void main() {
  testWidgets('shows six sort choices and reset restores newest', (
    tester,
  ) async {
    final result = ValueNotifier<ListFilters?>(null);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result.value = await showListFilterSheet(
                  context,
                  const ListFilters(
                    price: RangeValues(10, 20),
                    area: RangeValues(50, 100),
                    sort: ListSortOption.priceHighToLow,
                  ),
                );
              },
              child: const Text('Mở bộ lọc'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở bộ lọc'));
    await tester.pumpAndSettle();

    for (final option in ListSortOption.values) {
      expect(find.text(option.label), findsOneWidget);
    }

    await tester.tap(find.text('Đặt lại'));
    await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();

    expect(result.value?.sort, ListSortOption.newest);
    expect(result.value?.price, const RangeValues(0, 50));
    expect(result.value?.area, const RangeValues(0, 250));
    expect(result.value?.isActive, isFalse);
    expect(tester.takeException(), isNull);
  });
}
