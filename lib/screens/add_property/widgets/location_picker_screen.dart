import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/app_runtime.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/map/map_coverage_policy.dart';
import '../../../models/geo_point.dart';
import '../../../state/app_state.dart';
import '../../../theme/app_colors.dart';
import '../../map/widgets/map_region_selector.dart';
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

/// Chọn toạ độ trả về khi người dùng xác nhận vị trí trên picker.
///
/// [actualCameraCenter] (đọc trực tiếp từ renderer tại thời điểm bấm xác
/// nhận, xem [PropertyMapController.getCameraCenter]) luôn được ưu tiên hơn
/// [cachedTarget] (giá trị tích luỹ từ các event `onCameraMove` trước đó,
/// có thể bị lỡ lần bắn cuối) — chỉ dùng [cachedTarget] khi không đọc được
/// camera thực tế hoặc giá trị đọc được không hợp lệ.
@visibleForTesting
GeoPoint resolveConfirmedLocation({
  required GeoPoint cachedTarget,
  required GeoPoint? actualCameraCenter,
}) {
  if (actualCameraCenter != null && actualCameraCenter.isValid) {
    return actualCameraCenter;
  }
  return cachedTarget;
}

class LocationPickerScreen extends StatefulWidget {
  final GeoPoint? initial;

  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  PropertyMapController? _mapController;
  late GeoPoint _target = widget.initial ?? _defaultTarget();
  bool _locating = false;
  String? _activeRegionId;

  /// Không có [widget.initial] rõ ràng (BĐS mới, chưa có vị trí) — mở picker
  /// tại vùng bản đồ ưu tiên gần nhất người dùng từng dùng, nếu có; nếu
  /// không, mặc định TP.HCM. Cùng nguyên tắc ưu tiên với Map Screen (xem
  /// map_screen.dart) — không tự động gọi GPS chỉ để chọn vị trí mở picker.
  GeoPoint _defaultTarget() {
    final lastRegionId = context.read<AppState>().lastSupportedMapRegionId;
    return MapCoveragePolicy.regionById(lastRegionId)?.defaultCenter ??
        MapCoveragePolicy.hcm.defaultCenter;
  }

  void _onRegionChanged(SupportedMapRegion region) {
    if (mounted) setState(() => _activeRegionId = region.id);
    context.read<AppState>().setLastSupportedMapRegionId(region.id);
  }

  void _selectRegion(SupportedMapRegion region) {
    _mapController?.switchToRegion(region);
  }

  Future<void> _confirm() async {
    GeoPoint? actualCenter;
    try {
      actualCenter = await _mapController?.getCameraCenter();
    } catch (_) {
      // Không đọc được camera thực tế (vd. style chưa sẵn sàng) — rơi về
      // _target tích luỹ từ onCameraMove, vẫn tốt hơn là chặn xác nhận.
      actualCenter = null;
    }
    if (!mounted) return;
    final selected = resolveConfirmedLocation(
      cachedTarget: _target,
      actualCameraCenter: actualCenter,
    );
    Navigator.pop(context, selected);
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: MapRegionSelector(
              activeRegionId: _activeRegionId,
              onSelect: _selectRegion,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: PropertyMapView(
              initialTarget: _target,
              initialZoom: 16,
              onMapReady: (controller) => _mapController = controller,
              onCameraMove: (target) => _target = target,
              onRegionChanged: _onRegionChanged,
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
