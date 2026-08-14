import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/models/list_sort_option.dart';
import 'package:propnote/models/property.dart';
import 'package:propnote/models/property_status.dart';

void main() {
  Property property({
    required String id,
    required double price,
    required double area,
    required DateTime createdAt,
    DateTime? surveyDate,
  }) {
    return Property(
      id: id,
      title: id,
      address: id,
      areaId: 'area',
      status: PropertyStatus.selling,
      price: price,
      landArea: area,
      propertyType: 'Nhà phố',
      surveyDate: surveyDate,
      createdAt: createdAt,
      mapX: 0.5,
      mapY: 0.5,
    );
  }

  final properties = [
    property(
      id: 'a',
      price: 100,
      area: 30,
      createdAt: DateTime(2026, 1),
      surveyDate: DateTime(2026, 1, 3),
    ),
    property(id: 'b', price: 200, area: 20, createdAt: DateTime(2026, 1, 2)),
    property(
      id: 'c',
      price: 100,
      area: 40,
      createdAt: DateTime(2026, 1, 2),
      surveyDate: DateTime(2026, 1, 3),
    ),
    property(
      id: 'd',
      price: 100,
      area: 40,
      createdAt: DateTime(2026, 1, 2),
      surveyDate: DateTime(2026, 1, 3),
    ),
  ];

  List<String> sortedIds(ListSortOption option) {
    final sorted = [...properties]..sort(option.compare);
    return sorted.map((property) => property.id).toList();
  }

  test('provides all six required sort labels', () {
    expect(ListSortOption.values.map((option) => option.label), [
      'Mới nhất',
      'Cũ nhất',
      'Giá cao → thấp',
      'Giá thấp → cao',
      'Diện tích lớn → nhỏ',
      'Diện tích nhỏ → lớn',
    ]);
  });

  test('sorts newest and oldest using survey date then created date', () {
    expect(sortedIds(ListSortOption.newest), ['c', 'd', 'a', 'b']);
    expect(sortedIds(ListSortOption.oldest), ['b', 'a', 'c', 'd']);
  });

  test('sorts price in both directions with deterministic date fallback', () {
    expect(sortedIds(ListSortOption.priceHighToLow), ['b', 'c', 'd', 'a']);
    expect(sortedIds(ListSortOption.priceLowToHigh), ['c', 'd', 'a', 'b']);
  });

  test('sorts area in both directions with deterministic date fallback', () {
    expect(sortedIds(ListSortOption.areaLargeToSmall), ['c', 'd', 'a', 'b']);
    expect(sortedIds(ListSortOption.areaSmallToLarge), ['b', 'a', 'c', 'd']);
  });
}
