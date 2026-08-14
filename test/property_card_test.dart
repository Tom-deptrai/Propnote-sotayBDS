import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/models/property.dart';
import 'package:propnote/models/property_status.dart';
import 'package:propnote/widgets/property_card.dart';

void main() {
  Property property({DateTime? surveyDate}) {
    return Property(
      id: 'p',
      title: 'Nhà phố',
      address: 'Ngõ 22 Trung Kính',
      areaId: 'area',
      status: PropertyStatus.selling,
      price: 12.5e9,
      landArea: 72,
      propertyType: 'Nhà phố',
      tags: const ['Ô tô vào', 'Kinh doanh'],
      surveyDate: surveyDate,
      createdAt: DateTime(2026, 8, 1),
      mapX: 0.5,
      mapY: 0.5,
    );
  }

  Future<void> pumpCard(WidgetTester tester, Property property) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 350,
              child: PropertyCard(
                property: property,
                areaName: 'Cầu Giấy',
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows compact survey date on the card', (tester) async {
    await pumpCard(tester, property(surveyDate: DateTime(2026, 8, 14)));
    expect(find.text('Khảo sát: 14/08/2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows missing survey state without overflowing', (tester) async {
    await pumpCard(tester, property());
    expect(find.text('Chưa khảo sát'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
