/// Mô tả một nhà cung cấp basemap (nền bản đồ) mà renderer có thể hiển thị.
///
/// Đây là lớp cấu hình tập trung duy nhất biết URL/style cụ thể của một
/// provider. Business logic và UI chỉ được phép đọc [BasemapProviders.active]
/// — không hard-code style URL ở bất kỳ đâu khác.
class BasemapProvider {
  final String id;
  final String displayName;
  final String styleUri;
  final String? attribution;
  final Map<String, String>? headers;
  final bool requiresApiKey;

  /// Font stack (theo tên trong style JSON của provider, vd. "Noto Sans
  /// Bold") dùng cho text symbol (label giá...) do app tự vẽ thêm lên bản
  /// đồ. Renderer yêu cầu tên khớp với font stack mà glyphs endpoint của
  /// style thực sự phục vụ — nếu không, chữ sẽ không hiển thị dù layer vẫn
  /// được tạo thành công (không có lỗi rõ ràng nào được ném ra). Đã xác
  /// minh trực tiếp qua style JSON của OpenFreeMap Liberty (glyphs
  /// endpoint) rằng font stack "Noto Sans Bold" tồn tại thật, không phải
  /// suy đoán — an toàn để dùng cho label giá dễ đọc hơn "Regular".
  final List<String> textFontNames;

  const BasemapProvider({
    required this.id,
    required this.displayName,
    required this.styleUri,
    this.attribution,
    this.headers,
    this.requiresApiKey = false,
    this.textFontNames = const ['Noto Sans Bold'],
  });
}

/// Danh sách provider đã biết + provider đang active cho toàn app.
///
/// Đổi basemap (vd. OpenFreeMap → MapTiler hoặc self-hosted) chỉ cần đổi
/// [active] tại đây — không cần sửa map screen hay bất kỳ widget nào khác.
abstract final class BasemapProviders {
  static const openFreeMapLiberty = BasemapProvider(
    id: 'openfreemap-liberty',
    displayName: 'OpenFreeMap (Liberty)',
    styleUri: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: '© OpenFreeMap, © OpenMapTiles, © OpenStreetMap contributors',
  );

  /// Provider nền mặc định cho MVP hiện tại.
  static const BasemapProvider active = openFreeMapLiberty;
}
