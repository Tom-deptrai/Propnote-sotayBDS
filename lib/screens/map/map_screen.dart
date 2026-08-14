import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../data/services/app_runtime.dart';
import '../../data/services/location_service.dart';
import '../../models/geo_point.dart';
import '../../models/property.dart';
import '../../models/property_status.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_search_bar.dart';
import 'map_constants.dart';
import 'widgets/advanced_filter_sheet.dart';
import 'widgets/google_marker_icon_factory.dart';
import 'widgets/map_background_painter.dart';
import 'widgets/map_marker.dart';
import 'widgets/property_bottom_sheet.dart';

enum _StatusFilter { all, selling, unsurveyed, sold }

extension on _StatusFilter {
  String get label {
    switch (this) {
      case _StatusFilter.all:
        return 'Tất cả';
      case _StatusFilter.selling:
        return 'Đang bán';
      case _StatusFilter.unsurveyed:
        return 'Chưa khảo sát';
      case _StatusFilter.sold:
        return 'Đã bán';
    }
  }

  PropertyStatus? get status {
    switch (this) {
      case _StatusFilter.all:
        return null;
      case _StatusFilter.selling:
        return PropertyStatus.selling;
      case _StatusFilter.unsurveyed:
        return PropertyStatus.unsurveyed;
      case _StatusFilter.sold:
        return PropertyStatus.sold;
    }
  }
}

const Offset _defaultCurrentLocation = Offset(0.40, 0.46);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  static const GeoPoint _hanoi = GeoPoint(
    latitude: 21.0285,
    longitude: 105.8542,
  );

  final TransformationController _transformController =
      TransformationController();
  final GoogleMarkerIconFactory _googleMarkerFactory =
      GoogleMarkerIconFactory();
  late final AnimationController _animController;
  final TextEditingController _searchController = TextEditingController();

  _StatusFilter _filter = _StatusFilter.all;
  MapAdvancedFilter _advancedFilter = const MapAdvancedFilter();
  String _query = '';
  Size _viewportSize = Size.zero;
  GoogleMapController? _googleController;
  GeoPoint? _currentGeoLocation;
  Offset _currentCanvasLocation = _defaultCurrentLocation;
  Map<PropertyStatus, BitmapDescriptor> _googleMarkerIcons = {};
  String? _markerIconRequestKey;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _centerOn(
        Offset(mapCanvasSize.width * 0.44, mapCanvasSize.height * 0.46),
        scale: 0.62,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _googleController?.dispose();
    _transformController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadGoogleMarkerIcons(double scale) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final key = '${(scale * 10).round()}:${(pixelRatio * 10).round()}';
    if (_markerIconRequestKey == key) return;
    _markerIconRequestKey = key;
    Future.wait([
      for (final status in PropertyStatus.values)
        _googleMarkerFactory
            .iconFor(status: status, scale: scale, devicePixelRatio: pixelRatio)
            .then((icon) => MapEntry(status, icon)),
    ]).then((entries) {
      if (!mounted || _markerIconRequestKey != key) return;
      setState(() => _googleMarkerIcons = Map.fromEntries(entries));
    });
  }

  Future<void> _goToCurrentLocation(AppRuntime? runtime) async {
    if (runtime == null) {
      _centerOn(
        Offset(
          mapCanvasSize.width * _currentCanvasLocation.dx,
          mapCanvasSize.height * _currentCanvasLocation.dy,
        ),
        scale: 1.3,
      );
      return;
    }
    try {
      final point = await runtime.locationService.currentLocation();
      _currentGeoLocation = point;
      if (runtime.googleMapsConfigured) {
        await _googleController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(point.latitude, point.longitude),
            16,
          ),
        );
      } else {
        final normalized = point.toLegacyNormalized();
        _currentCanvasLocation = Offset(normalized.x, normalized.y);
        _centerOn(
          Offset(
            mapCanvasSize.width * _currentCanvasLocation.dx,
            mapCanvasSize.height * _currentCanvasLocation.dy,
          ),
          scale: 1.3,
        );
      }
      if (mounted) setState(() {});
    } on LocationFailure catch (error) {
      if (mounted) {
        final canOpenSettings =
            error.reason == LocationFailureReason.serviceDisabled ||
            error.reason == LocationFailureReason.permissionDeniedForever;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.userMessage),
            action: canOpenSettings
                ? SnackBarAction(
                    label: 'Cài đặt',
                    onPressed: () =>
                        runtime.locationService.openSettings(error.reason),
                  )
                : null,
          ),
        );
      }
    }
  }

  void _centerOn(Offset canvasPoint, {double scale = 1.4}) {
    if (_viewportSize == Size.zero) return;
    final tx = _viewportSize.width / 2 - canvasPoint.dx * scale;
    final ty = _viewportSize.height / 2 - canvasPoint.dy * scale;
    final target = Matrix4(
      scale,
      0,
      0,
      0,
      0,
      scale,
      0,
      0,
      0,
      0,
      1,
      0,
      tx,
      ty,
      0,
      1,
    );

    final tween = Matrix4Tween(begin: _transformController.value, end: target);
    _animController
      ..reset()
      ..addListener(() {
        _transformController.value = tween.transform(_animController.value);
      })
      ..forward();
  }

  bool _matches(Property p, AppState state) {
    if (_filter != _StatusFilter.all && p.status != _filter.status) {
      return false;
    }
    final priceBillions = p.price / 1e9;
    if (_advancedFilter.minimumPriceBillions > 0 &&
        priceBillions < _advancedFilter.minimumPriceBillions) {
      return false;
    }
    if (_advancedFilter.maximumPriceBillions < 50 &&
        priceBillions > _advancedFilter.maximumPriceBillions) {
      return false;
    }
    if (_advancedFilter.propertyTypes.isNotEmpty &&
        !_advancedFilter.propertyTypes.contains(p.propertyType)) {
      return false;
    }
    if (_query.trim().isEmpty) return true;
    final q = _query.trim().toLowerCase();
    final area = state.areaName(p.areaId).toLowerCase();
    return p.title.toLowerCase().contains(q) ||
        p.address.toLowerCase().contains(q) ||
        area.contains(q) ||
        p.propertyType.toLowerCase().contains(q) ||
        p.notes.toLowerCase().contains(q) ||
        p.tags.any((tag) => tag.toLowerCase().contains(q));
  }

  Offset _canvasLocation(Property property) {
    final location = property.location;
    if (location == null) return Offset(property.mapX, property.mapY);
    final normalized = location.toLegacyNormalized();
    return Offset(normalized.x, normalized.y);
  }

  Set<Marker> _buildGoogleMarkers(
    BuildContext context,
    List<Property> properties,
    AppState state,
  ) {
    final markers = <Marker>{};
    for (final property in properties) {
      final location = property.location;
      if (location == null) continue;
      markers.add(
        Marker(
          markerId: MarkerId(property.id),
          position: LatLng(location.latitude, location.longitude),
          icon:
              _googleMarkerIcons[property.status] ??
              BitmapDescriptor.defaultMarker,
          onTap: () => showPropertyPreviewSheet(
            context,
            property: property,
            areaName: state.areaName(property.areaId),
          ),
        ),
      );
    }
    final current = _currentGeoLocation;
    if (current != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current-location'),
          position: LatLng(current.latitude, current.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          zIndexInt: 1000,
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final runtime = context.read<AppRuntime?>();
    final useGoogleMaps = runtime?.googleMapsConfigured == true;
    final visibleProperties = state.properties
        .where((p) => _matches(p, state))
        .toList();
    final markerScale = state.markerScale;
    final propertyHalf = PropertyMarker.hitBoxFor(markerScale) / 2;
    if (useGoogleMaps) _loadGoogleMarkerIcons(markerScale);
    final initialLocation =
        visibleProperties
            .map((property) => property.location)
            .nonNulls
            .firstOrNull ??
        _hanoi;

    return Scaffold(
      backgroundColor: AppColors.mapLand,
      body: Stack(
        children: [
          Positioned.fill(
            child: useGoogleMaps
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        initialLocation.latitude,
                        initialLocation.longitude,
                      ),
                      zoom: 12.5,
                    ),
                    onMapCreated: (controller) =>
                        _googleController = controller,
                    markers: _buildGoogleMarkers(
                      context,
                      visibleProperties,
                      state,
                    ),
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      _viewportSize = constraints.biggest;
                      return ClipRect(
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          constrained: false,
                          minScale: 0.6,
                          maxScale: 2.6,
                          boundaryMargin: const EdgeInsets.all(400),
                          child: SizedBox(
                            width: mapCanvasSize.width,
                            height: mapCanvasSize.height,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: const MapBackgroundPainter(),
                                  ),
                                ),
                                Positioned(
                                  left:
                                      mapCanvasSize.width *
                                          _currentCanvasLocation.dx -
                                      32,
                                  top:
                                      mapCanvasSize.height *
                                          _currentCanvasLocation.dy -
                                      32,
                                  child: const CurrentLocationMarker(),
                                ),
                                for (final p in visibleProperties)
                                  Positioned(
                                    left:
                                        mapCanvasSize.width *
                                            _canvasLocation(p).dx -
                                        propertyHalf,
                                    top:
                                        mapCanvasSize.height *
                                            _canvasLocation(p).dy -
                                        propertyHalf,
                                    child: PropertyMarker(
                                      status: p.status,
                                      scale: markerScale,
                                      onTap: () => showPropertyPreviewSheet(
                                        context,
                                        property: p,
                                        areaName: state.areaName(p.areaId),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  AppSearchBar(
                    controller: _searchController,
                    hintText: 'Tìm bất động sản, khu vực...',
                    onChanged: (v) => setState(() => _query = v),
                    trailing: InkWell(
                      onTap: () async {
                        final selected = await showAdvancedFilterSheet(
                          context,
                          initial: _advancedFilter,
                        );
                        if (selected != null && mounted) {
                          setState(() => _advancedFilter = selected);
                        }
                      },
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.tune_rounded,
                          color: _advancedFilter.isDefault
                              ? AppColors.navy
                              : AppColors.statusSelling,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FilterChipRow(
                    selected: _filter,
                    onSelected: (f) => setState(() => _filter = f),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 150,
            child: _RoundIconButton(
              icon: Icons.my_location_rounded,
              onTap: () => _goToCurrentLocation(runtime),
            ),
          ),
          if (!useGoogleMaps)
            Positioned(
              left: 16,
              right: 72,
              bottom: 150,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(
                      'Chưa cấu hình Google Maps — đang dùng bản đồ dự phòng',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  final _StatusFilter selected;
  final ValueChanged<_StatusFilter> onSelected;

  const _FilterChipRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _StatusFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = _StatusFilter.values[i];
          final isSelected = f == selected;
          return ChoiceChip(
            label: Text(f.label),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(f),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.navy,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.navy : AppColors.border,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: AppColors.navy, size: 22),
        ),
      ),
    );
  }
}
