import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:propnote/main.dart';

void main() {
  testWidgets('App launches to the Map screen with bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PropNoteApp());
    // The current-location marker intentionally repeats forever, so waiting
    // for all animations to settle would always time out.
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bản đồ'), findsOneWidget);
    expect(find.text('Danh sách'), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });
}
