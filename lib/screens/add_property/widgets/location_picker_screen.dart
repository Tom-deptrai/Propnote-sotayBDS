import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/app_runtime.dart';
import '../../../data/services/location_service.dart';
import '../../../models/geo_point.dart';
import '../../../theme/app_colors.dart';
import '../../map/widgets/property_map_view.dart';

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

  PropertyMapController? _mapController;
  late GeoPoint _target = widget.initial ?? _hanoi;
  bool _locating = false;

  Future<void> _confirm() async {
    Navigator.pop(context, _target);
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    final runtime = context.read<AppRuntime?>();
    if (runtime == null) return;
    setState(() => _locating = true);
    try {
      final point = await runtime.locationService.currentLocation();
      _target = point;
      await _mapController?.animateTo(point, zoom: 17);
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
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mapLand,
      appBar: AppBar(
        title: const Text('Chọn trên bản đồ'),
        backgroundColor: AppColors.mapLand,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: PropertyMapView(
              initialTarget: _target,
              initialZoom: 16,
              onMapReady: (controller) => _mapController = controller,
              onCameraMove: (target) => _target = target,
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
                child: const Text(
                  'Kéo bản đồ để đặt ghim vào đúng vị trí',
                  style: TextStyle(
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
