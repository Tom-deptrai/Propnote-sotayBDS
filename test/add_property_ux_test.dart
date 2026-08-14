import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/screens/add_property/add_property_screen.dart';
import 'package:propnote/state/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  Future<AppState> pumpScreen(WidgetTester tester) async {
    final state = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: AddPropertyScreen()),
      ),
    );
    await tester.pump();
    return state;
  }

  Finder fieldWithHint(String hint) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
  }

  testWidgets('decimal fields normalize input and expose keyboard dismissal', (
    tester,
  ) async {
    await pumpScreen(tester);
    final frontage = fieldWithHint('4,2');
    await tester.scrollUntilVisible(
      frontage,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(frontage);
    await tester.pump();

    tester.testTextInput.enterText('4.2');
    await tester.pump();
    expect(tester.widget<TextField>(frontage).controller?.text, '4,2');
    expect(find.text('Xong'), findsOneWidget);
    expect(find.text('Lưu bất động sản'), findsOneWidget);

    await tester.tap(find.text('Xong'));
    await tester.pump();
    expect(tester.widget<TextField>(frontage).focusNode?.hasFocus, isFalse);

    final area = fieldWithHint('72');
    await tester.scrollUntilVisible(
      area,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(area);
    tester.testTextInput.enterText('12500,5');
    await tester.pump();
    expect(tester.widget<TextField>(area).controller?.text, '12.500,5');
    final areaFocusNode = tester.widget<TextField>(area).focusNode;

    await tester.drag(find.byType(ListView), const Offset(0, -150));
    await tester.pump();
    expect(areaFocusNode?.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('property types and tags can be reordered from the form', (
    tester,
  ) async {
    final state = await pumpScreen(tester);
    final firstType = state.propertyTypes.first;

    await tester.scrollUntilVisible(
      find.text('Loại bất động sản'),
      250,
      scrollable: find.byType(Scrollable).first,
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
    await tester.pumpAndSettle();
    var handle = find.byIcon(Icons.drag_indicator_rounded).first;
    var gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 120));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(state.propertyTypes.first, isNot(firstType));

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    final firstTag = state.tagOptions.first;
    await tester.scrollUntilVisible(
      find.text('Tags'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final tagRow = find
        .ancestor(of: find.text('Tags'), matching: find.byType(Row))
        .first;
    await tester.tap(
      find.descendant(of: tagRow, matching: find.text('Quản lý')),
    );
    await tester.pumpAndSettle();
    handle = find.byIcon(Icons.drag_indicator_rounded).first;
    gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 120));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(state.tagOptions.first, isNot(firstTag));
    expect(tester.takeException(), isNull);
  });
}
