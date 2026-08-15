import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/models/geo_point.dart';
import 'package:propnote/screens/add_property/widgets/location_picker_screen.dart';

const _pointA = GeoPoint(latitude: 21.0285, longitude: 105.8542); // Hà Nội
const _pointB = GeoPoint(latitude: 16.0544, longitude: 108.2022); // Đà Nẵng

void main() {
  group('resolveConfirmedLocation', () {
    test('actual camera center (read live from renderer) wins over the cached '
        'onCameraMove target when both are available and valid', () {
      final result = resolveConfirmedLocation(
        cachedTarget: _pointA,
        actualCameraCenter: _pointB,
      );
      expect(result, _pointB);
    });

    test('falls back to the cached target when the live camera center could '
        'not be read (e.g. queryCameraPosition failed or style not ready)', () {
      final result = resolveConfirmedLocation(
        cachedTarget: _pointA,
        actualCameraCenter: null,
      );
      expect(result, _pointA);
    });
  });
}
