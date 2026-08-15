import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../data/services/map/basemap_provider.dart';
import '../../../models/geo_point.dart';
import '../../../models/property_status.dart';
import '../../../utils/formatters.dart';
import 'map_marker.dart';
import 'property_map_marker_icons.dart';

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

  const PropertyMapController._(this._raw);

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
}

typedef PropertyMapReadyCallback =
    void Function(PropertyMapController controller);
typedef PropertyMapCameraMoveCallback = void Function(GeoPoint target);

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
  final bool showPrice;
  final bool showPriceUnit;
  final PropertyMapReadyCallback? onMapReady;
  final PropertyMapCameraMoveCallback? onCameraMove;

  /// Khi true, camera tự động bay tới [initialTarget] mỗi khi giá trị này
  /// đổi giữa các lần build (vd. mini-preview cần "đi theo" location đang
  /// chỉnh). Mặc định false — Map Screen KHÔNG nên tự tái định vị mỗi khi
  /// initialTarget suy ra từ danh sách BĐS thay đổi (filter/thêm mới),
  /// vì đó là bản đồ tương tác người dùng đang tự điều khiển.
  final bool followInitialTargetChanges;

  const PropertyMapView({
    super.key,
    required this.initialTarget,
    this.initialZoom = 12.5,
    this.markers = const [],
    this.markerScale = 1.0,
    this.interactive = true,
    this.showCompass = true,
    this.showPrice = false,
    this.showPriceUnit = true,
    this.onMapReady,
    this.onCameraMove,
    this.followInitialTargetChanges = false,
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
    }
    _syncMarkers();
    _refreshCurrentLocationOverlay();
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final screenPosition = _currentLocationScreenPosition;
    return Stack(
      children: [
        MapLibreMap(
          styleString: BasemapProviders.active.styleUri,
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.initialTarget.latitude,
              widget.initialTarget.longitude,
            ),
            zoom: widget.initialZoom,
          ),
          compassEnabled: widget.showCompass && widget.interactive,
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
            widget.onMapReady?.call(PropertyMapController._(controller));
          },
          onStyleLoadedCallback: _onStyleLoaded,
          onCameraMove: (position) {
            widget.onCameraMove?.call(
              GeoPoint(
                latitude: position.target.latitude,
                longitude: position.target.longitude,
              ),
            );
            if (_currentLocationTarget != null) {
              _refreshCurrentLocationOverlay();
            }
          },
        ),
        if (screenPosition != null)
          Positioned(
            left: screenPosition.dx - 32,
            top: screenPosition.dy - 32,
            child: const CurrentLocationMarker(),
          ),
      ],
    );
  }
}
