class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint({required this.latitude, required this.longitude})
    : assert(latitude >= -90 && latitude <= 90),
      assert(longitude >= -180 && longitude <= 180);

  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  /// Projection gần đúng chỉ dùng cho canvas fallback khi chưa cấu hình API key.
  factory GeoPoint.fromLegacyNormalized(double x, double y) {
    return GeoPoint(
      latitude: 21.0285 + (0.5 - y) * 0.12,
      longitude: 105.8542 + (x - 0.5) * 0.16,
    );
  }

  ({double x, double y}) toLegacyNormalized() {
    return (
      x: ((longitude - 105.8542) / 0.16 + 0.5).clamp(0.02, 0.98),
      y: (0.5 - (latitude - 21.0285) / 0.12).clamp(0.02, 0.98),
    );
  }
}
