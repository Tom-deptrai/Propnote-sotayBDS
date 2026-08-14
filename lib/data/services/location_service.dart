import 'package:geolocator/geolocator.dart';

import '../../models/geo_point.dart';

enum LocationFailureReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class LocationFailure implements Exception {
  final LocationFailureReason reason;
  final Object? cause;

  const LocationFailure(this.reason, [this.cause]);

  String get userMessage {
    switch (reason) {
      case LocationFailureReason.serviceDisabled:
        return 'Dịch vụ vị trí đang tắt. Hãy bật Vị trí trong Cài đặt.';
      case LocationFailureReason.permissionDenied:
        return 'PropNote chưa được cấp quyền truy cập vị trí.';
      case LocationFailureReason.permissionDeniedForever:
        return 'Quyền vị trí đã bị từ chối. Hãy cấp lại trong Cài đặt.';
      case LocationFailureReason.unavailable:
        return 'Không thể lấy vị trí hiện tại.';
    }
  }

  @override
  String toString() => userMessage;
}

class LocationService {
  const LocationService();

  Future<GeoPoint> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(LocationFailureReason.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(LocationFailureReason.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationFailureReason.permissionDeniedForever,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (error) {
      if (error is LocationFailure) rethrow;
      throw LocationFailure(LocationFailureReason.unavailable, error);
    }
  }

  Future<bool> openSettings(LocationFailureReason reason) =>
      reason == LocationFailureReason.serviceDisabled
      ? Geolocator.openLocationSettings()
      : Geolocator.openAppSettings();
}
