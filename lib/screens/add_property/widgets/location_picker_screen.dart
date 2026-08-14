import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../data/services/app_runtime.dart';
import '../../../data/services/location_service.dart';
import '../../../models/geo_point.dart';
import '../../../theme/app_colors.dart';
import '../../map/map_constants.dart';
import '../../map/widgets/map_background_painter.dart';

Future<GeoPoint?> showLocationPickerScreen(
  BuildContext context, {
  GeoPoint? initial,
}) {
  return Navigator.push<GeoPoint>(
    context,
    MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: initial)),
  );
}

class LocationPickerScreen extends StatefulWidget {
  final GeoPoint? initial;

  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const GeoPoint _hanoi = GeoPoint(
    latitude: 21.0285,
    longitude: 105.8542,
  );

  final TransformationController _fallbackController =
      TransformationController();
  GoogleMapController? _googleController;
  Size _viewportSize = Size.zero;
  late GeoPoint _target = widget.initial ?? _hanoi;
  bool _locating = false;

  bool get _useGoogleMaps =>
      context.read<AppRuntime?>()?.googleMapsConfigured == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _useGoogleMaps || _viewportSize == Size.zero) return;
      final normalized = _target.toLegacyNormalized();
      const scale = 1.3;
      final tx =
          _viewportSize.width / 2 - mapCanvasSize.width * normalized.x * scale;
      final ty =
          _viewportSize.height / 2 -
          mapCanvasSize.height * normalized.y * scale;
      _fallbackController.value = Matrix4(
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
    });
  }

  @override
  void dispose() {
    _googleController?.dispose();
    _fallbackController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_useGoogleMaps) {
      Navigator.pop(context, _target);
      return;
    }
    final inverse = Matrix4.tryInvert(_fallbackController.value);
    if (inverse == null) return;
    final center = Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    final canvasPoint = MatrixUtils.transformPoint(inverse, center);
    final x = (canvasPoint.dx / mapCanvasSize.width).clamp(0.02, 0.98);
    final y = (canvasPoint.dy / mapCanvasSize.height).clamp(0.02, 0.98);
    Navigator.pop(context, GeoPoint.fromLegacyNormalized(x, y));
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    final runtime = context.read<AppRuntime?>();
    if (runtime == null) return;
    setState(() => _locating = true);
    try {
      final point = await runtime.locationService.currentLocation();
      _target = point;
      if (_useGoogleMaps) {
        await _googleController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(point.latitude, point.longitude),
            17,
          ),
        );
      } else {
        final normalized = point.toLegacyNormalized();
        const scale = 1.3;
        final tx =
            _viewportSize.width / 2 -
            mapCanvasSize.width * normalized.x * scale;
        final ty =
            _viewportSize.height / 2 -
            mapCanvasSize.height * normalized.y * scale;
        _fallbackController.value = Matrix4(
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
      }
    } on LocationFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.userMessage)));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final useGoogleMaps = _useGoogleMaps;
    return Scaffold(
      backgroundColor: AppColors.mapLand,
      appBar: AppBar(
        title: const Text('Chọn trên bản đồ'),
        backgroundColor: AppColors.mapLand,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: useGoogleMaps
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_target.latitude, _target.longitude),
                      zoom: 16,
                    ),
                    onMapCreated: (controller) =>
                        _googleController = controller,
                    onCameraMove: (position) {
                      _target = GeoPoint(
                        latitude: position.target.latitude,
                        longitude: position.target.longitude,
                      );
                    },
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: true,
                    zoomControlsEnabled: false,
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      _viewportSize = constraints.biggest;
                      return ClipRect(
                        child: InteractiveViewer(
                          transformationController: _fallbackController,
                          constrained: false,
                          minScale: 0.6,
                          maxScale: 2.6,
                          boundaryMargin: const EdgeInsets.all(400),
                          child: SizedBox(
                            width: mapCanvasSize.width,
                            height: mapCanvasSize.height,
                            child: const CustomPaint(
                              painter: MapBackgroundPainter(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 34),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.navy,
                  size: 44,
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 90,
            child: FloatingActionButton.small(
              heroTag: 'location-picker-current',
              onPressed: _locating ? null : _useCurrentLocation,
              child: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  useGoogleMaps
                      ? 'Kéo bản đồ để đặt ghim vào đúng vị trí'
                      : 'Chưa có API key Google Maps — đang dùng bản đồ dự phòng',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: ElevatedButton(
            onPressed: _confirm,
            child: const Text('Xác nhận vị trí'),
          ),
        ),
      ),
    );
  }
}
