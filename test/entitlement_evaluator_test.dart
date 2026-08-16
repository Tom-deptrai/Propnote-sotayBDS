import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/subscription/entitlement_evaluator.dart';

// [parseRevocationFlags] là phần LOGIC THUẦN (parse JSON, không đụng
// platform channel) của [StoreKit2EntitlementEvaluator] — test trực tiếp
// bằng chuỗi JSON mẫu theo đúng schema JWSTransactionDecodedPayload mà
// Apple công bố (revocationDate/isUpgraded đều optional), không cần mock
// StoreKit2 thật (không khả thi trong `flutter test`).
void main() {
  group('parseRevocationFlags', () {
    test('null jsonRepresentation → both flags unknown (null)', () {
      final flags = parseRevocationFlags(null);
      expect(flags.isRevoked, isNull);
      expect(flags.isUpgraded, isNull);
    });

    test('malformed (non-JSON) string → both flags unknown, does not throw', () {
      final flags = parseRevocationFlags('not valid json {{{');
      expect(flags.isRevoked, isNull);
      expect(flags.isUpgraded, isNull);
    });

    test('JSON that decodes to a non-object (e.g. an array) → both unknown', () {
      final flags = parseRevocationFlags(jsonEncode([1, 2, 3]));
      expect(flags.isRevoked, isNull);
      expect(flags.isUpgraded, isNull);
    });

    test(
      'well-formed transaction with neither field present → both false/known '
      '(not revoked, not upgraded)',
      () {
        final flags = parseRevocationFlags(
          jsonEncode({
            'transactionId': '123',
            'productId': 'propnote_pro_yearly',
            'purchaseDate': 1000,
            'expiresDate': 2000,
          }),
        );
        expect(flags.isRevoked, isFalse);
        expect(flags.isUpgraded, isNull); // isUpgraded absent → still null
      },
    );

    test('revocationDate present (non-null) → isRevoked true', () {
      final flags = parseRevocationFlags(
        jsonEncode({
          'transactionId': '123',
          'revocationDate': 1700000000000,
          'revocationReason': 1,
        }),
      );
      expect(flags.isRevoked, isTrue);
    });

    test('revocationDate explicitly null → isRevoked false', () {
      final flags = parseRevocationFlags(
        jsonEncode({'transactionId': '123', 'revocationDate': null}),
      );
      expect(flags.isRevoked, isFalse);
    });

    test('isUpgraded: true → parsed correctly', () {
      final flags = parseRevocationFlags(
        jsonEncode({'transactionId': '123', 'isUpgraded': true}),
      );
      expect(flags.isUpgraded, isTrue);
    });

    test('isUpgraded: false → parsed correctly', () {
      final flags = parseRevocationFlags(
        jsonEncode({'transactionId': '123', 'isUpgraded': false}),
      );
      expect(flags.isUpgraded, isFalse);
    });

    test(
      'both revoked and upgraded present at once → both parsed independently',
      () {
        final flags = parseRevocationFlags(
          jsonEncode({
            'transactionId': '123',
            'revocationDate': 1700000000000,
            'isUpgraded': true,
          }),
        );
        expect(flags.isRevoked, isTrue);
        expect(flags.isUpgraded, isTrue);
      },
    );

    test(
      'isUpgraded present but wrong type (not a bool) → treated as unknown, '
      'not a crash and not a guessed value',
      () {
        final flags = parseRevocationFlags(
          jsonEncode({'transactionId': '123', 'isUpgraded': 'yes'}),
        );
        expect(flags.isUpgraded, isNull);
      },
    );
  });

  group('EntitlementResult', () {
    test('has exactly the 3 states the service depends on', () {
      expect(EntitlementResult.values, [
        EntitlementResult.active,
        EntitlementResult.notActive,
        EntitlementResult.unknown,
      ]);
    });
  });
}
