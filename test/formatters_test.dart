import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/utils/formatters.dart';

void main() {
  group('formatMarkerPrice', () {
    test('returns null for zero or invalid price', () {
      expect(formatMarkerPrice(0, withUnit: true), isNull);
      expect(formatMarkerPrice(-1, withUnit: true), isNull);
    });

    test('trims a whole-number billions value to an integer', () {
      expect(formatMarkerPrice(10e9, withUnit: false), '10');
      expect(formatMarkerPrice(10e9, withUnit: true), '10 tỷ');
    });

    test('keeps one decimal place when needed', () {
      expect(formatMarkerPrice(10.5e9, withUnit: false), '10.5');
      expect(formatMarkerPrice(10.5e9, withUnit: true), '10.5 tỷ');
    });

    test('keeps two decimal places when needed', () {
      expect(formatMarkerPrice(10.25e9, withUnit: false), '10.25');
    });

    test('uses a period as the decimal separator, never a comma', () {
      final result = formatMarkerPrice(12.5e9, withUnit: false);
      expect(result, isNot(contains(',')));
      expect(result, contains('.'));
    });
  });
}
