import '../../../models/geo_point.dart';

/// Một vùng đô thị có bản đồ local (PMTiles) đóng gói sẵn trong app.
///
/// Đây là NGUỒN SỰ THẬT DUY NHẤT cho bbox/zoom của từng vùng — không hard-code
/// toạ độ vùng ở bất kỳ màn hình/service nào khác, luôn đi qua
/// [MapCoveragePolicy].
class SupportedMapRegion {
  final String id;
  final String displayName;
  final double west;
  final double south;
  final double east;
  final double north;
  final GeoPoint defaultCenter;
  final double defaultZoom;
  final double minZoom;
  final double maxZoom;

  /// Tên file .pmtiles trong `assets/map/` VÀ tên file khi copy ra thư mục
  /// ghi được trên thiết bị — dùng chung một tên để tránh 2 nguồn sự thật.
  final String pmtilesAssetFileName;

  const SupportedMapRegion({
    required this.id,
    required this.displayName,
    required this.west,
    required this.south,
    required this.east,
    required this.north,
    required this.defaultCenter,
    required this.defaultZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.pmtilesAssetFileName,
  });

  String get pmtilesAssetPath => 'assets/map/$pmtilesAssetFileName';

  bool contains(GeoPoint point) {
    return point.latitude >= south &&
        point.latitude <= north &&
        point.longitude >= west &&
        point.longitude <= east;
  }
}

/// Chính sách coverage bản đồ trung tâm — biết TP.HCM và Hà Nội là 2 vùng có
/// bản đồ local, và cung cấp API để các màn hình map (Map Screen, Location
/// Picker, mini-map preview) xác định vùng phù hợp cho một toạ độ, mà không
/// phải tự biết chi tiết bbox.
///
/// QUAN TRỌNG: coverage bản đồ và toạ độ BĐS ([GeoPoint]) là hai khái niệm
/// ĐỘC LẬP — 1 điểm nằm ngoài mọi [SupportedMapRegion] vẫn là toạ độ hợp lệ
/// (xem [GeoPoint.isValid], không phụ thuộc coverage). Chính sách này chỉ trả
/// lời câu hỏi "vùng nào (nếu có) có dữ liệu bản đồ cho điểm này", KHÔNG bao
/// giờ sửa/xoá/clamp toạ độ.
abstract final class MapCoveragePolicy {
  static const hcm = SupportedMapRegion(
    id: 'hcm',
    displayName: 'TP.HCM',
    west: 106.42,
    south: 10.60,
    east: 106.95,
    north: 11.05,
    defaultCenter: GeoPoint(latitude: 10.772, longitude: 106.698), // Chợ Bến Thành
    defaultZoom: 12.5,
    minZoom: 9.6,
    maxZoom: 18,
    pmtilesAssetFileName: 'hcm_metro.pmtiles',
  );

  static const hanoi = SupportedMapRegion(
    id: 'hanoi',
    displayName: 'Hà Nội',
    west: 105.45,
    south: 20.756,
    east: 106.05,
    north: 21.30,
    defaultCenter: GeoPoint(latitude: 21.028, longitude: 105.854), // Hồ Hoàn Kiếm
    defaultZoom: 12.5,
    minZoom: 9.4,
    maxZoom: 18,
    pmtilesAssetFileName: 'hanoi_metro_v2.pmtiles',
  );

  static const List<SupportedMapRegion> allRegions = [hcm, hanoi];

  /// Vùng có bản đồ local chứa [point], hoặc null nếu điểm nằm ngoài mọi
  /// vùng được hỗ trợ.
  static SupportedMapRegion? regionContaining(GeoPoint point) {
    for (final region in allRegions) {
      if (region.contains(point)) return region;
    }
    return null;
  }

  static bool isSupported(GeoPoint point) =>
      regionContaining(point) != null;

  /// Vùng "phù hợp nhất" để mở một [PropertyMapView] tại [target] — nếu
  /// [target] nằm trong 1 vùng, dùng đúng vùng đó; nếu nằm ngoài mọi vùng
  /// (vd. BĐS cũ ở tỉnh khác), chọn vùng có tâm gần [target] nhất để bản đồ
  /// mở ra gần khu vực người dùng đang quan tâm nhất có thể — vẫn hiển thị
  /// nền xám + banner "chưa hỗ trợ" tại đúng vị trí thật của [target], không
  /// bao giờ tự dịch chuyển toạ độ.
  static SupportedMapRegion nearestRegion(GeoPoint target) {
    final direct = regionContaining(target);
    if (direct != null) return direct;
    SupportedMapRegion best = allRegions.first;
    double bestDistance = double.infinity;
    for (final region in allRegions) {
      final dLat = target.latitude - region.defaultCenter.latitude;
      final dLng = target.longitude - region.defaultCenter.longitude;
      final distance = dLat * dLat + dLng * dLng;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = region;
      }
    }
    return best;
  }
}
