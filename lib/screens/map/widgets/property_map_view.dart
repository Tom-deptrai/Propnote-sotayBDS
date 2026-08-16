import 'dart:async';
import 'dart:convert';
import 'dart:math' show Point;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../data/services/map/basemap_provider.dart';
import '../../../data/services/map/local_map_assets_service.dart';
import '../../../data/services/map/map_coverage_policy.dart';
import '../../../models/geo_point.dart';
import '../../../models/property_status.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import 'map_marker.dart';
import 'property_map_marker_icons.dart';

/// Dùng chung 1 instance cho toàn app: nhiều [PropertyMapView] có thể tồn
/// tại cùng lúc (Map Screen + mini-map preview trên Property Detail...) —
/// copy PMTiles/fonts ra đĩa chỉ cần làm 1 lần, cache theo path trong bộ nhớ
/// (xem [LocalMapAssetsService]) chứ không phải theo từng widget instance.
final LocalMapAssetsService _sharedLocalMapAssets = LocalMapAssetsService();

/// Một marker hiển thị trên [PropertyMapView] — hoặc marker BĐS (có
/// [status]) hoặc marker vị trí hiện tại ([isCurrentLocation]).
class PropertyMapMarkerData {
  final String id;
  final GeoPoint position;
  final PropertyStatus? status;
  final bool isCurrentLocation;
  final double? price;
  final VoidCallback? onTap;

  const PropertyMapMarkerData({
    required this.id,
    required this.position,
    this.status,
    this.isCurrentLocation = false,
    this.price,
    this.onTap,
  }) : assert(
         status != null || isCurrentLocation,
         'PropertyMapMarkerData cần status hoặc isCurrentLocation',
       );
}

/// Facade điều khiển camera của [PropertyMapView] — che giấu chi tiết
/// renderer (MapLibreMapController/LatLng/CameraUpdate) khỏi các màn hình
/// gọi vào, để sau này đổi renderer không phải sửa lại logic domain.
class PropertyMapController {
  final MapLibreMapController _raw;
  final Future<void> Function(
    SupportedMapRegion region, {
    GeoPoint? cameraTarget,
    double? zoom,
  })
  _switchRegion;
  final void Function() _resetNorth;

  const PropertyMapController._(this._raw, this._switchRegion, this._resetNorth);

  Future<void> animateTo(GeoPoint target, {double zoom = 16}) {
    return _raw.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(target.latitude, target.longitude),
        zoom,
      ),
    );
  }

  /// Đọc vị trí camera THỰC TẾ hiện tại trực tiếp từ renderer (không dùng
  /// giá trị cache phía Dart từ event `onCameraMove`) — đây là nguồn dữ
  /// liệu đáng tin cậy nhất khi cần biết chính xác map đang center ở đâu
  /// tại một thời điểm cụ thể (vd. lúc người dùng bấm "Xác nhận vị trí"),
  /// vì event `onCameraMove` có thể không kịp bắn lần cuối trước khi state
  /// phía Dart được đọc.
  Future<GeoPoint> getCameraCenter() async {
    final position = await _raw.queryCameraPosition();
    final target = position?.target;
    if (target == null) {
      throw StateError('Không lấy được vị trí camera hiện tại từ bản đồ.');
    }
    return GeoPoint(latitude: target.latitude, longitude: target.longitude);
  }

  /// Chuyển bản đồ sang hiển thị [region] — tải PMTiles của vùng đó nếu
  /// chưa có (cache theo vùng, xem [LocalMapAssetsService]), swap style TẠI
  /// CHỖ qua `MapLibreMapController.setStyle` (không remount widget/không
  /// mất controller), camera bay tới `region.defaultCenter`/`defaultZoom`.
  /// Idempotent nếu [region] đã đang active. Marker/price-label/current-
  /// location overlay tự phục hồi sau khi style mới load xong (xem
  /// `_onStyleLoaded`, dùng lại nguyên logic sync đã có).
  Future<void> switchToRegion(SupportedMapRegion region) => _switchRegion(
    region,
    cameraTarget: region.defaultCenter,
    zoom: region.defaultZoom,
  );

  /// Xoay bản đồ về hướng Bắc (bearing 0°) — KHÔNG đổi center/zoom, dùng cho
  /// nút la bàn tự vẽ (đồng bộ UX với compass control gốc của MapLibre).
  void resetNorth() => _resetNorth();
}

typedef PropertyMapReadyCallback =
    void Function(PropertyMapController controller);
typedef PropertyMapCameraMoveCallback = void Function(GeoPoint target);
typedef PropertyMapRegionChangedCallback =
    void Function(SupportedMapRegion region);

/// Renderer adapter: bọc widget bản đồ MapLibre + basemap [BasemapProviders]
/// đằng sau một API domain-friendly (GeoPoint, PropertyStatus, callback đơn
/// giản). Đây là điểm DUY NHẤT trong app import `package:maplibre_gl` ngoài
/// [PropertyMapController] — map_screen/location_picker/mini_map_preview chỉ
/// làm việc với [PropertyMapMarkerData]/[PropertyMapController]/[GeoPoint].
///
/// Marker BĐS luôn được vẽ riêng lẻ — không gom cụm theo số lượng. Label giá
/// (khi bật) là một symbol văn bản HOÀN TOÀN TÁCH BIỆT khỏi icon marker, với
/// vòng đời add/update/remove độc lập, để việc renderer tự ẩn label do
/// collision không bao giờ kéo theo việc ẩn icon marker.
class PropertyMapView extends StatefulWidget {
  final GeoPoint initialTarget;
  final double initialZoom;
  final List<PropertyMapMarkerData> markers;
  final double markerScale;
  final bool interactive;
  final bool showCompass;

  /// Lề (điểm x/y) cho compass control gốc của MapLibre — mặc định null
  /// (SDK tự đặt góc trên-phải sát mép). Map Screen truyền lề dưới xuống để
  /// compass không bị khuất sau thanh tìm kiếm/filter chip ở đầu màn hình;
  /// Location Picker không cần đổi vì không có UI che góc trên.
  final Point<double>? compassViewMargins;
  final bool showPrice;
  final bool showPriceUnit;
  final PropertyMapReadyCallback? onMapReady;
  final PropertyMapCameraMoveCallback? onCameraMove;

  /// Gọi mỗi khi vùng bản đồ (PMTiles) đang active thực sự đổi — do người
  /// dùng bấm nút chọn vùng (qua [PropertyMapController.switchToRegion])
  /// HOẶC do camera/GPS tự đi vào một [SupportedMapRegion] khác vùng đang
  /// active. Dùng để đồng bộ UI chọn vùng (bấm nút nào đang sáng) và lưu
  /// last-supported-region — không gọi khi camera chỉ đơn thuần rời khỏi
  /// coverage vào vùng xám (đó là [showCoverageBanner], không phải đổi
  /// region).
  final PropertyMapRegionChangedCallback? onRegionChanged;

  /// Khi true, camera tự động bay tới [initialTarget] mỗi khi giá trị này
  /// đổi giữa các lần build (vd. mini-preview cần "đi theo" location đang
  /// chỉnh). Mặc định false — Map Screen KHÔNG nên tự tái định vị mỗi khi
  /// initialTarget suy ra từ danh sách BĐS thay đổi (filter/thêm mới),
  /// vì đó là bản đồ tương tác người dùng đang tự điều khiển.
  final bool followInitialTargetChanges;

  /// Hiện banner "Bản đồ chưa hỗ trợ khu vực này." khi camera nằm ngoài vùng
  /// coverage local (xem [MapCoveragePolicy]). Mặc định true cho Map Screen/
  /// Location Picker; mini-map preview tắt banner này (không đủ chỗ hiển
  /// thị) nhưng vẫn hiện nền xám + marker bình thường.
  final bool showCoverageBanner;

  const PropertyMapView({
    super.key,
    required this.initialTarget,
    this.initialZoom = 12.5,
    this.markers = const [],
    this.markerScale = 1.0,
    this.interactive = true,
    this.showCompass = true,
    this.compassViewMargins,
    this.showPrice = false,
    this.showPriceUnit = true,
    this.onMapReady,
    this.onCameraMove,
    this.onRegionChanged,
    this.followInitialTargetChanges = false,
    this.showCoverageBanner = true,
  });

  @override
  State<PropertyMapView> createState() => _PropertyMapViewState();
}

typedef _IconEntry = ({Symbol symbol, String iconName, GeoPoint position});

class _PropertyMapViewState extends State<PropertyMapView> {
  final PropertyMapMarkerIcons _iconFactory = PropertyMapMarkerIcons();
  final Map<String, double> _iconSizeByName = {};

  // Icon marker BĐS dùng SymbolManager annotation API (addSymbol) — khoá
  // theo 'icon:<id>' với vòng đời add/update/remove độc lập hoàn toàn khỏi
  // label giá bên dưới.
  final Map<String, _IconEntry> _iconSymbols = {};
  Map<String, PropertyMapMarkerData> _markersById = {};
  MapLibreMapController? _controller;
  int _syncGeneration = 0;

  // Label giá KHÔNG dùng SymbolManager: plugin maplibre_gl 0.26.2 hard-code
  // text-font của SymbolManager thành ['Open Sans Regular', 'Arial Unicode MS
  // Regular'] (xem annotation_manager.dart) — bỏ qua hoàn toàn fontNames mà
  // ứng dụng truyền vào, nên chữ luôn "câm" trên basemap OpenFreeMap (chỉ
  // phục vụ font Noto Sans). Vì vậy label giá được vẽ bằng một GeoJSON
  // source + symbol layer style thấp cấp riêng (addGeoJsonSource/
  // addSymbolLayer) với text-font đúng theo [BasemapProvider.textFontNames]
  // — tách biệt hoàn toàn khỏi layer icon nên không bao giờ ảnh hưởng tới
  // việc hiển thị marker.
  static const String _priceSourceId = 'propnote-price-labels-source';
  static const String _priceLayerId = 'propnote-price-labels-layer';
  bool _priceLayerReady = false;
  String? _lastPriceSignature;

  // Marker vị trí hiện tại KHÔNG dùng MapLibre Symbol (bitmap tĩnh, có thể
  // bị ẩn bởi collision detection của renderer) — thay vào đó là một overlay
  // Flutter (CurrentLocationMarker, đã có sẵn pulse animation) định vị theo
  // toạ độ màn hình quy đổi từ GeoPoint qua controller. Luôn hiển thị khi
  // được yêu cầu, tách biệt hẳn khỏi marker BĐS.
  GeoPoint? _currentLocationTarget;
  Offset? _currentLocationScreenPosition;
  int _currentLocationGeneration = 0;

  // Bản đồ local (PMTiles) — vùng coverage active có thể đổi trong vòng đời
  // widget (xem [_switchToRegion]): do người dùng bấm nút chọn vùng, hoặc do
  // camera/GPS tự đi vào một SupportedMapRegion khác vùng đang active. Style
  // JSON được dựng KHÔNG ĐỒNG BỘ (phải copy PMTiles/fonts ra đĩa trước, xem
  // LocalMapAssetsService) — cache theo regionId để chuyển qua lại giữa các
  // vùng đã từng active không phải rebuild/re-encode JSON mỗi lần.
  SupportedMapRegion? _activeRegion;
  final Map<String, String> _styleJsonByRegionId = {};
  String? _initialStyleJson;
  bool _mapSetupFailed = false;
  bool _isOutsideCoverage = false;
  bool _regionSwitchInFlight = false;
  int _regionSwitchGeneration = 0;

  // Vị trí camera mới nhất (mọi lần onCameraMove, kể cả khi đang bay do
  // animateCamera của chính app) — dùng làm input cho quyết định TỰ ĐỘNG
  // chuyển vùng, nhưng quyết định đó chỉ thực thi khi camera đã dừng hẳn.
  GeoPoint? _lastCameraPoint;

  // Native `onCameraIdle` (maplibre_gl 0.26.2) đã kiểm chứng KHÔNG đáng tin
  // cậy sau 1 lần `animateCamera` bay xa (vd. GPS nhảy giữa HCM↔Hà Nội, cách
  // nhau ~1200km): quan sát thực tế trên thiết bị — nó bắn ĐÚNG 1 LẦN với 1
  // toạ độ giữa chừng chuyến bay (còn cách xa điểm đến hàng trăm km) rồi im
  // luôn, không bắn lại khi camera đã thực sự dừng ở điểm đến cuối cùng, nên
  // dùng riêng nó làm nguồn tín hiệu "đã dừng" khiến app kẹt vĩnh viễn ở
  // trạng thái xám/chưa chuyển vùng. Thay bằng debounce tự cài trên
  // `onCameraMove`: mỗi lần camera di chuyển, huỷ timer cũ và đặt timer mới
  // — timer chỉ thực sự bắn khi KHÔNG có onCameraMove nào tiếp theo trong
  // suốt khoảng debounce, tương đương "đã dừng" theo đúng nghĩa, không phụ
  // thuộc vào việc native SDK có tự báo đúng hay không.
  Timer? _organicCheckDebounce;
  static const _organicCheckDebounceDelay = Duration(milliseconds: 400);

  // setStyle()/animateCamera() của native renderer có thể tự bắn 1-2 sự
  // kiện camera "settle" thoáng qua ngay sau khi vừa chuyển vùng xong (quan
  // sát thực tế trên thiết bị: layer cũ bị gỡ giữa chừng gây
  // PlatformException(layerNotFound) do 2 lần setStyle đè lên nhau) — nếu
  // toạ độ thoáng qua đó rơi vào vùng khác vùng vừa chuyển tới, logic tự
  // động phát hiện vùng (onCameraIdle) sẽ hiểu lầm thành "camera thực sự
  // sang vùng khác" và bật vòng lặp chuyển vùng qua lại vô hạn. Cooldown này
  // chặn TỰ ĐỘNG chuyển vùng (không chặn nút bấm — luôn là ý định rõ ràng
  // của người dùng) trong 1 khoảng ngắn ngay sau 1 lần chuyển vùng bất kỳ.
  DateTime? _regionSwitchSettledAt;
  static const _organicSwitchCooldown = Duration(milliseconds: 1500);

  // Timer phòng vệ cho _prepareStyleForRegion — xem [_raceWithTimeout]. Có
  // thể có NHIỀU timer cùng lúc (vùng ban đầu + 1 lần chuyển vùng khác) nên
  // dùng Set thay vì 1 field đơn — mỗi timer tự gỡ khỏi Set khi hoàn tất
  // (dù thắng hay thua cuộc đua), và dispose() huỷ hết phần còn sót lại.
  // Future.timeout() dựng Timer nội bộ không expose ra ngoài để huỷ, nên
  // nếu widget bị dispose trước khi platform channel phản hồi, Timer đó vẫn
  // "pending" tới khi tự bắn — vi phạm invariant "no pending timers" của
  // flutter_test và làm rớt các test khác chạy ngay sau.
  final Set<Timer> _pendingTimeoutTimers = {};

  @override
  void initState() {
    super.initState();
    _prepareStyle();
  }

  Future<T> _raceWithTimeout<T>(Future<T> future, Duration timeout) {
    final completer = Completer<T>();
    late final Timer timer;
    timer = Timer(timeout, () {
      _pendingTimeoutTimers.remove(timer);
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Local map asset setup timed out after $timeout'),
        );
      }
    });
    _pendingTimeoutTimers.add(timer);
    future.then(
      (value) {
        timer.cancel();
        _pendingTimeoutTimers.remove(timer);
        if (!completer.isCompleted) completer.complete(value);
      },
      onError: (Object error, StackTrace stackTrace) {
        timer.cancel();
        _pendingTimeoutTimers.remove(timer);
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );
    return completer.future;
  }

  /// Dựng (hoặc lấy từ cache) style JSON cho [region] — copy PMTiles/fonts ra
  /// đĩa nếu cần (xem [LocalMapAssetsService]). Cache theo regionId nên
  /// chuyển qua lại giữa 2 vùng đã từng active (vd. bấm TP.HCM ↔ Hà Nội
  /// nhiều lần) không phải build/jsonEncode lại từ đầu.
  Future<String> _prepareStyleForRegion(SupportedMapRegion region) async {
    final cached = _styleJsonByRegionId[region.id];
    if (cached != null) return cached;
    // Timeout phòng vệ: copy asset local bình thường mất dưới 1s (đọc
    // rootBundle + ghi đĩa), nhưng nếu platform channel (path_provider/
    // package_info) không phản hồi vì bất kỳ lý do gì (vd. môi trường không
    // có platform thật), lỗi phải kết thúc CÓ GIỚI HẠN thay vì treo
    // CircularProgressIndicator (đang animate liên tục) vĩnh viễn.
    final glyphsTemplate = await _raceWithTimeout(
      _sharedLocalMapAssets.ensureGlyphsTemplate(),
      const Duration(seconds: 3),
    );
    final pmtilesUrl = await _raceWithTimeout(
      _sharedLocalMapAssets.ensureRegionPmtilesUrl(region),
      const Duration(seconds: 3),
    );
    final style = buildLocalMapStyle(
      region: region,
      pmtilesUrl: pmtilesUrl,
      glyphsTemplate: glyphsTemplate,
    );
    final json = jsonEncode(style);
    _styleJsonByRegionId[region.id] = json;
    return json;
  }

  Future<void> _prepareStyle() async {
    final region = MapCoveragePolicy.nearestRegion(widget.initialTarget);
    _activeRegion = region;
    _isOutsideCoverage = !region.contains(widget.initialTarget);
    try {
      final json = await _prepareStyleForRegion(region);
      if (!mounted) return;
      setState(() => _initialStyleJson = json);
      // Báo vùng active BAN ĐẦU (không chỉ vùng active sau 1 lần CHUYỂN qua
      // _switchToRegion) — để UI chọn vùng (MapRegionSelector) tô sáng đúng
      // ngay từ lần mở đầu tiên, kể cả khi vùng đó tới từ ưu tiên đã lưu
      // (lastSupportedMapRegionId) chứ không phải người dùng vừa bấm.
      widget.onRegionChanged?.call(region);
    } catch (error, stackTrace) {
      debugPrint('PropertyMapView: không dựng được style bản đồ local: '
          '$error\n$stackTrace');
      if (!mounted) return;
      setState(() => _mapSetupFailed = true);
    }
  }

  /// Chuyển vùng bản đồ active sang [newRegion] — swap style TẠI CHỖ qua
  /// `controller.setStyle` (không remount MapLibreMap/không mất controller).
  /// [cameraTarget]/[zoom] khi có (bấm nút chọn vùng) làm camera bay tới đó
  /// sau khi style mới bắt đầu load; khi null (camera/GPS tự đi vào vùng
  /// khác lúc pan) giữ nguyên vị trí camera hiện tại — không có lý do di
  /// chuyển camera vì nó đã ở đúng chỗ rồi.
  ///
  /// Runtime overlay (icon marker/price label/current-location) tự phục hồi
  /// sau khi native side bắn lại sự kiện "style loaded" (native luôn làm
  /// vậy sau setStyle, xem `_onStyleLoaded`) — không cần gọi lại thủ công ở
  /// đây. Cache marker/price-layer cục bộ được xoá trước khi setStyle vì
  /// style/layer cũ trở thành invalid ngay khi setStyle được gọi.
  Future<void> _switchToRegion(
    SupportedMapRegion newRegion, {
    GeoPoint? cameraTarget,
    double? zoom,
  }) async {
    if (_regionSwitchInFlight || newRegion.id == _activeRegion?.id) return;
    final controller = _controller;
    if (controller == null) return;
    _regionSwitchInFlight = true;
    final generation = ++_regionSwitchGeneration;
    try {
      final json = await _prepareStyleForRegion(newRegion);
      if (generation != _regionSwitchGeneration || !mounted) return;
      _iconSymbols.clear();
      _iconSizeByName.clear();
      _priceLayerReady = false;
      _lastPriceSignature = null;
      await controller.setStyle(json);
      if (generation != _regionSwitchGeneration || !mounted) return;
      if (cameraTarget != null) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(cameraTarget.latitude, cameraTarget.longitude),
            zoom ?? newRegion.defaultZoom,
          ),
        );
        if (generation != _regionSwitchGeneration || !mounted) return;
      }
      setState(() {
        _activeRegion = newRegion;
        _isOutsideCoverage = false;
      });
      widget.onRegionChanged?.call(newRegion);
    } catch (error, stackTrace) {
      debugPrint('PropertyMapView: chuyển vùng bản đồ thất bại: '
          '$error\n$stackTrace');
    } finally {
      _regionSwitchInFlight = false;
      _regionSwitchSettledAt = DateTime.now();
    }
  }

  /// Kiểm tra vùng chứa [_lastCameraPoint] và tự chuyển vùng NẾU camera đã
  /// dừng hẳn (gọi từ debounce timer trên onCameraMove — xem
  /// [_organicCheckDebounce] — KHÔNG dùng onCameraIdle của native SDK vì đã
  /// kiểm chứng không đáng tin cậy sau các chuyến bay camera dài). Tránh
  /// phản ứng với toạ độ thoáng qua giữa lúc camera đang bay (kể cả do
  /// chính animateCamera của [_switchToRegion] gây ra), vốn là nguyên nhân
  /// gây vòng lặp chuyển vùng qua lại vô hạn quan sát được khi test trên
  /// thiết bị thật (2 lần setStyle đè lên nhau ném
  /// PlatformException(layerNotFound)). Cooldown sau mỗi lần chuyển vùng
  /// (nút bấm lẫn tự động) chặn thêm 1 lớp an toàn cho sự kiện "settle"
  /// thoáng qua ngay sau khi vừa setStyle xong.
  void _organicRegionCheck() {
    final point = _lastCameraPoint;
    if (point == null || _regionSwitchInFlight) return;
    final settledAt = _regionSwitchSettledAt;
    if (settledAt != null &&
        DateTime.now().difference(settledAt) < _organicSwitchCooldown) {
      return;
    }
    final containingRegion = MapCoveragePolicy.regionContaining(point);
    if (containingRegion != null && containingRegion.id != _activeRegion?.id) {
      _switchToRegion(containingRegion);
    }
  }

  void _updateCoverageState(GeoPoint point) {
    final region = _activeRegion;
    if (region == null) return;
    final outside = !region.contains(point);
    if (outside != _isOutsideCoverage) {
      setState(() => _isOutsideCoverage = outside);
    }
  }

  @override
  void didUpdateWidget(covariant PropertyMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.followInitialTargetChanges &&
        widget.initialTarget != oldWidget.initialTarget) {
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(widget.initialTarget.latitude, widget.initialTarget.longitude),
          widget.initialZoom,
        ),
        duration: const Duration(milliseconds: 350),
      );
      _updateCoverageState(widget.initialTarget);
    }
    _syncMarkers();
    _refreshCurrentLocationOverlay();
  }

  @override
  void dispose() {
    for (final timer in _pendingTimeoutTimers) {
      timer.cancel();
    }
    _pendingTimeoutTimers.clear();
    _organicCheckDebounce?.cancel();
    _controller?.onSymbolTapped.remove(_handleSymbolTap);
    super.dispose();
  }

  void _handleSymbolTap(Symbol symbol) {
    final markerId = symbol.data?['markerId'] as String?;
    if (markerId == null) return;
    _markersById[markerId]?.onTap?.call();
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller != null) {
      // Icon marker BĐS luôn hiện (không bị collision ẩn).
      await controller.setSymbolIconAllowOverlap(true);
      await controller.setSymbolIconIgnorePlacement(true);
      if (widget.showPrice) await _ensurePriceLayer(controller);
    }
    await _syncMarkers();
    await _refreshCurrentLocationOverlay();
  }

  /// Tạo GeoJSON source + symbol layer style thấp cấp cho label giá, dùng
  /// đúng font stack mà basemap thực sự phục vụ (xem giải thích ở khai báo
  /// [_priceSourceId]). Idempotent — chỉ tạo một lần cho vòng đời map.
  Future<void> _ensurePriceLayer(MapLibreMapController controller) async {
    if (_priceLayerReady) return;
    await controller.addGeoJsonSource(
      _priceSourceId,
      buildFeatureCollection(const []),
      promoteId: 'id',
    );
    await controller.addSymbolLayer(
      _priceSourceId,
      _priceLayerId,
      SymbolLayerProperties(
        textField: [Expressions.get, 'text'],
        textFont: BasemapProviders.active.textFontNames,
        textSize: 15.0,
        textColor: '#1B2559',
        textHaloColor: '#FFFFFF',
        textHaloWidth: 2.0,
        textHaloBlur: 0.5,
        textOffset: const [0, 1.6],
        textAllowOverlap: false,
        textIgnorePlacement: false,
      ),
      // Label giá chỉ để đọc — không được chặn tap xuống marker icon bên
      // dưới, dù label render đè lên icon trên màn hình.
      enableInteraction: false,
    );
    _priceLayerReady = true;
  }

  Future<double> _ensureIcon(
    String name,
    Future<(Uint8List, double)> Function() loader,
  ) async {
    final cached = _iconSizeByName[name];
    if (cached != null) return cached;
    final (bytes, iconSize) = await loader();
    await _controller!.addImage(name, bytes);
    _iconSizeByName[name] = iconSize;
    return iconSize;
  }

  GeoPoint? _findCurrentLocationTarget() {
    for (final marker in widget.markers) {
      if (marker.isCurrentLocation) return marker.position;
    }
    return null;
  }

  /// Quy đổi GeoPoint của marker vị trí hiện tại sang toạ độ màn hình để đặt
  /// overlay Flutter. Gọi lại mỗi khi camera di chuyển hoặc khi target đổi.
  Future<void> _refreshCurrentLocationOverlay() async {
    final controller = _controller;
    final target = _findCurrentLocationTarget();
    _currentLocationTarget = target;
    final generation = ++_currentLocationGeneration;

    if (controller == null || target == null) {
      if (mounted && _currentLocationScreenPosition != null) {
        setState(() => _currentLocationScreenPosition = null);
      }
      return;
    }
    try {
      final point = await controller.toScreenLocation(
        LatLng(target.latitude, target.longitude),
      );
      if (!mounted ||
          generation != _currentLocationGeneration ||
          _currentLocationTarget != target) {
        return;
      }
      setState(
        () => _currentLocationScreenPosition = Offset(
          point.x.toDouble(),
          point.y.toDouble(),
        ),
      );
    } catch (_) {
      // Quy đổi toạ độ màn hình là tiện ích hiển thị — lỗi ở đây (vd. style
      // chưa sẵn sàng) không nên làm crash hay chặn phần còn lại của bản đồ.
    }
  }

  /// Đồng bộ icon marker BĐS trên bản đồ: mỗi property luôn có đúng một
  /// icon riêng, không bao giờ gộp/ẩn vì trùng vị trí hay quá đông — nếu
  /// nhiều marker chồng nhau, marker BĐS mới hơn (đứng sau trong [markers],
  /// do map_screen truyền vào theo thứ tự cũ→mới) được vẽ sau nên nằm trên.
  Future<void> _syncMarkers() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final generation = ++_syncGeneration;
    _markersById = {for (final m in widget.markers) m.id: m};
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final propertyMarkers = widget.markers
        .where((m) => !m.isCurrentLocation)
        .toList();

    // --- Icon marker (luôn hiện, không phụ thuộc price) ---
    final iconIds = {for (final m in propertyMarkers) 'icon:${m.id}'};
    for (final id in _iconSymbols.keys.toList()) {
      if (!iconIds.contains(id)) {
        final removed = _iconSymbols.remove(id);
        if (removed != null) await controller.removeSymbol(removed.symbol);
        if (generation != _syncGeneration || !mounted) return;
      }
    }
    for (final marker in propertyMarkers) {
      final id = 'icon:${marker.id}';
      final iconName = _iconFactory.cacheKey(
        marker.status!,
        widget.markerScale,
        dpr,
      );
      final iconSize = await _ensureIcon(
        iconName,
        () => _iconFactory.iconFor(
          status: marker.status!,
          scale: widget.markerScale,
          devicePixelRatio: dpr,
        ),
      );
      if (generation != _syncGeneration || !mounted) return;

      final existing = _iconSymbols[id];
      final latLng = LatLng(
        marker.position.latitude,
        marker.position.longitude,
      );
      if (existing == null) {
        final symbol = await controller.addSymbol(
          SymbolOptions(
            geometry: latLng,
            iconImage: iconName,
            iconSize: iconSize,
          ),
          {'markerId': marker.id},
        );
        if (generation != _syncGeneration || !mounted) return;
        _iconSymbols[id] = (
          symbol: symbol,
          iconName: iconName,
          position: marker.position,
        );
      } else if (existing.iconName != iconName ||
          existing.position != marker.position) {
        await controller.updateSymbol(
          existing.symbol,
          SymbolOptions(
            geometry: latLng,
            iconImage: iconName,
            iconSize: iconSize,
          ),
        );
        if (generation != _syncGeneration || !mounted) return;
        _iconSymbols[id] = (
          symbol: existing.symbol,
          iconName: iconName,
          position: marker.position,
        );
      }
    }

    // --- Label giá (tuỳ chọn, GeoJSON source + style layer riêng biệt
    // hoàn toàn khỏi icon — xem [_ensurePriceLayer]) ---
    // Chỉ tạo source/layer khi thực sự cần: map picker và mini-map preview
    // không bao giờ bật showPrice, không có lý do tốn thêm 2 lệnh platform
    // channel (addGeoJsonSource + addSymbolLayer) mỗi lần style load xong.
    if (!widget.showPrice && !_priceLayerReady) return;
    await _ensurePriceLayer(controller);
    if (generation != _syncGeneration || !mounted) return;

    final priceFeatures = <Map<String, dynamic>>[];
    final signatureParts = <String>[];
    if (widget.showPrice) {
      for (final marker in propertyMarkers) {
        final text = formatMarkerPrice(
          marker.price ?? 0,
          withUnit: widget.showPriceUnit,
        );
        if (text == null) continue;
        priceFeatures.add({
          'type': 'Feature',
          'id': marker.id,
          'geometry': {
            'type': 'Point',
            'coordinates': [
              marker.position.longitude,
              marker.position.latitude,
            ],
          },
          'properties': {'id': marker.id, 'text': text},
        });
        signatureParts.add(
          '${marker.id}:$text:${marker.position.latitude},${marker.position.longitude}',
        );
      }
    }
    final signature = signatureParts.join('|');
    if (signature != _lastPriceSignature) {
      await controller.setGeoJsonSource(
        _priceSourceId,
        buildFeatureCollection(priceFeatures),
      );
      if (generation != _syncGeneration || !mounted) return;
      _lastPriceSignature = signature;
    }
  }

  /// Bấm nút la bàn tự vẽ (xem map_screen.dart) — animate bearing về 0° mà
  /// KHÔNG đổi center/zoom. `CameraUpdate.bearingTo` chỉ set 1 thuộc tính
  /// bearing, camera position khác giữ nguyên theo đúng semantics của
  /// MapLibre (không phải "camera mới" thay thế toàn bộ).
  void _resetNorth() {
    _controller?.animateCamera(CameraUpdate.bearingTo(0));
  }

  @override
  Widget build(BuildContext context) {
    final screenPosition = _currentLocationScreenPosition;
    final styleJson = _initialStyleJson;
    final region = _activeRegion;
    return Stack(
      children: [
        if (styleJson != null && region != null)
          MapLibreMap(
            key: const ValueKey('propnote-map'),
            styleString: styleJson,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.initialTarget.latitude,
                widget.initialTarget.longitude,
              ),
              zoom: widget.initialZoom,
            ),
            minMaxZoomPreference: MinMaxZoomPreference(
              region.minZoom,
              region.maxZoom,
            ),
            // Không khoá cứng camera tại mép coverage — người dùng pan tự do
            // ra ngoài vùng có PMTiles, phần ngoài hiện nền xám qua layer
            // `coverage-mask-fill` trong style (xem buildLocalMapStyle), báo
            // "Bản đồ chưa hỗ trợ khu vực này." qua [_CoverageBanner] — toạ
            // độ camera/marker KHÔNG bao giờ bị clamp.
            cameraTargetBounds: CameraTargetBounds.unbounded,
            compassEnabled: widget.showCompass && widget.interactive,
            compassViewMargins: widget.compassViewMargins,
            scrollGesturesEnabled: widget.interactive,
            zoomGesturesEnabled: widget.interactive,
            rotateGesturesEnabled: widget.interactive,
            tiltGesturesEnabled: widget.interactive,
            dragEnabled: widget.interactive,
            doubleClickZoomEnabled: widget.interactive,
            logoEnabled: false,
            // Bắt buộc phải bật để controller.queryCameraPosition() (dùng bởi
            // PropertyMapController.getCameraCenter) trả về giá trị thật thay
            // vì null — trên iOS, native side (getCamera() trong
            // MapLibreMapController.swift) chỉ đọc mapView.camera khi cờ này
            // true, nếu không sẽ luôn trả nil bất kể camera đang ở đâu.
            trackCameraPosition: true,
            onMapCreated: (controller) {
              _controller = controller;
              controller.onSymbolTapped.add(_handleSymbolTap);
              widget.onMapReady?.call(
                PropertyMapController._(controller, _switchToRegion, _resetNorth),
              );
            },
            onStyleLoadedCallback: _onStyleLoaded,
            onCameraMove: (position) {
              final point = GeoPoint(
                latitude: position.target.latitude,
                longitude: position.target.longitude,
              );
              _lastCameraPoint = point;
              widget.onCameraMove?.call(point);
              // Cập nhật gray/banner theo thời gian thực khi pan (mượt, phản
              // hồi ngay) — QUYẾT ĐỊNH tự động chuyển vùng thì đợi camera
              // dừng hẳn (debounce bên dưới) để không phản ứng với toạ độ
              // thoáng qua giữa lúc đang bay.
              _updateCoverageState(point);
              if (_currentLocationTarget != null) {
                _refreshCurrentLocationOverlay();
              }
              _organicCheckDebounce?.cancel();
              _organicCheckDebounce = Timer(
                _organicCheckDebounceDelay,
                _organicRegionCheck,
              );
            },
            onCameraIdle: _organicRegionCheck,
          )
        else if (_mapSetupFailed)
          const ColoredBox(
            color: AppColors.mapLand,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Không thể tải bản đồ. Vui lòng thử lại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          )
        else
          const ColoredBox(
            color: AppColors.mapLand,
            child: Center(child: CircularProgressIndicator()),
          ),
        if (screenPosition != null)
          Positioned(
            left: screenPosition.dx - 32,
            top: screenPosition.dy - 32,
            child: const CurrentLocationMarker(),
          ),
        if (widget.showCoverageBanner && _isOutsideCoverage)
          const Positioned(
            left: 16,
            right: 16,
            bottom: 78,
            child: SafeArea(top: false, child: _CoverageBanner()),
          ),
      ],
    );
  }
}

/// Banner cố định (không popup/toast, chỉ hiện/ẩn theo trạng thái coverage)
/// báo camera đang xem 1 khu vực chưa có bản đồ local — toạ độ vẫn hợp lệ,
/// vẫn cho chọn/lưu bình thường (xem [MapCoveragePolicy]).
class _CoverageBanner extends StatelessWidget {
  const _CoverageBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Bản đồ chưa hỗ trợ khu vực này.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 12.5),
      ),
    );
  }
}
