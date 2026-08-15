import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/models/geo_point.dart';
import 'package:propnote/screens/add_property/widgets/location_picker_screen.dart';

void main() {
  testWidgets(
    'confirming location pops the initial target back to the caller',
    (tester) async {
      const initial = GeoPoint(latitude: 10.7769, longitude: 106.7009);
      GeoPoint? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showLocationPickerScreen(
                  context,
                  initial: initial,
                );
              },
              child: const Text('Mở'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn trên bản đồ'), findsOneWidget);
      expect(find.text('Xác nhận vị trí'), findsOneWidget);

      await tester.tap(find.text('Xác nhận vị trí'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn trên bản đồ'), findsNothing);
      expect(result?.latitude, initial.latitude);
      expect(result?.longitude, initial.longitude);
    },
  );
}
