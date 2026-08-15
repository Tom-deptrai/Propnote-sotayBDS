import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../data/services/map/basemap_provider.dart';
import '../../../models/geo_point.dart';
import '../../../models/property_status.dart';
import 'property_map_marker_icons.dart';

/// Một marker hiển thị trên [PropertyMapView] — hoặc marker BĐS (có
/// [status]) hoặc marker vị trí hiện tại ([isCurrentLocation]).
class PropertyMapMarkerData {
  final String id;
  final GeoPoint position;
  final PropertyStatus? status;
  final bool isCurrentLocation;
  final VoidCallback? onTap;

  const PropertyMapMarkerData({
    required this.id,
    required this.position,
    this.status,
    this.isCurrentLocation = false,
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
}

typedef PropertyMapReadyCallback = void Function(PropertyMapController controller);
typedef PropertyMapCameraMoveCallback = void Function(GeoPoint target);

/// Renderer adapter: bọc widget bản đồ MapLibre + basemap [BasemapProviders]
/// đằng sau một API domain-friendly (GeoPoint, PropertyStatus, callback đơn
/// giản). Đây là điểm DUY NHẤT trong app import `package:maplibre_gl` ngoài
/// [PropertyMapController] — map_screen/location_picker/mini_map_preview chỉ
/// làm việc với [PropertyMapMarkerData]/[PropertyMapController]/[GeoPoint].
class PropertyMapView extends StatefulWidget {
  final GeoPoint initialTarget;
  final double initialZoom;
  final List<PropertyMapMarkerData> markers;
  final double markerScale;
  final bool interactive;
  final bool showCompass;
  final PropertyMapReadyCallback? onMapReady;
  final PropertyMapCameraMoveCallback? onCameraMove;

  const PropertyMapView({
    super.key,
    required this.initialTarget,
    this.initialZoom = 12.5,
    this.markers = const [],
    this.markerScale = 1.0,
    this.interactive = true,
    this.showCompass = true,
    this.onMapReady,
    this.onCameraMove,
  });

  @override
  State<PropertyMapView> createState() => _PropertyMapViewState();
}

typedef _SymbolEntry = ({Symbol symbol, String iconName, GeoPoint position});

class _PropertyMapViewState extends State<PropertyMapView> {
  final PropertyMapMarkerIcons _iconFactory = PropertyMapMarkerIcons();
  final Map<String, double> _iconSizeByName = {};
  final Map<String, _SymbolEntry> _symbols = {};
  Map<String, PropertyMapMarkerData> _markersById = {};
  MapLibreMapController? _controller;
  int _syncGeneration = 0;

  @override
  void didUpdateWidget(covariant PropertyMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMarkers();
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
    await _syncMarkers();
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

  Future<void> _syncMarkers() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final generation = ++_syncGeneration;
    _markersById = {for (final m in widget.markers) m.id: m};
    final dpr = MediaQuery.devicePixelRatioOf(context);

    final incomingIds = _markersById.keys.toSet();
    for (final id in _symbols.keys.toList()) {
      if (!incomingIds.contains(id)) {
        final removed = _symbols.remove(id);
        if (removed != null) await controller.removeSymbol(removed.symbol);
        if (generation != _syncGeneration || !mounted) return;
      }
    }

    for (final marker in widget.markers) {
      final String iconName;
      final double iconSize;
      if (marker.isCurrentLocation) {
        iconName = _iconFactory.currentLocationCacheKey(dpr);
        iconSize = await _ensureIcon(
          iconName,
          () => _iconFactory.currentLocationIcon(devicePixelRatio: dpr),
        );
      } else {
        iconName = _iconFactory.cacheKey(marker.status!, widget.markerScale, dpr);
        iconSize = await _ensureIcon(
          iconName,
          () => _iconFactory.iconFor(
            status: marker.status!,
            scale: widget.markerScale,
            devicePixelRatio: dpr,
          ),
        );
      }
      if (generation != _syncGeneration || !mounted) return;

      final existing = _symbols[marker.id];
      final latLng = LatLng(marker.position.latitude, marker.position.longitude);
      if (existing == null) {
        final symbol = await controller.addSymbol(
          SymbolOptions(geometry: latLng, iconImage: iconName, iconSize: iconSize),
          {'markerId': marker.id},
        );
        if (generation != _syncGeneration || !mounted) return;
        _symbols[marker.id] = (
          symbol: symbol,
          iconName: iconName,
          position: marker.position,
        );
      } else if (existing.iconName != iconName ||
          existing.position.latitude != marker.position.latitude ||
          existing.position.longitude != marker.position.longitude) {
        await controller.updateSymbol(
          existing.symbol,
          SymbolOptions(geometry: latLng, iconImage: iconName, iconSize: iconSize),
        );
        if (generation != _syncGeneration || !mounted) return;
        _symbols[marker.id] = (
          symbol: existing.symbol,
          iconName: iconName,
          position: marker.position,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: BasemapProviders.active.styleUri,
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.initialTarget.latitude, widget.initialTarget.longitude),
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
      onMapCreated: (controller) {
        _controller = controller;
        controller.onSymbolTapped.add(_handleSymbolTap);
        widget.onMapReady?.call(PropertyMapController._(controller));
      },
      onStyleLoadedCallback: _onStyleLoaded,
      onCameraMove: widget.onCameraMove == null
          ? null
          : (position) => widget.onCameraMove!(
              GeoPoint(
                latitude: position.target.latitude,
                longitude: position.target.longitude,
              ),
            ),
    );
  }
}
