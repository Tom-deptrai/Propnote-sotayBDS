import 'dart:async' show unawaited;
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/app_runtime.dart';
import '../../data/services/location_service.dart';
import '../../data/services/map/map_coverage_policy.dart';
import '../../models/geo_point.dart';
import '../../models/property.dart';
import '../../models/property_status.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_search_bar.dart';
import 'widgets/advanced_filter_sheet.dart';
import 'widgets/map_marker.dart' show currentLocationColor;
import 'widgets/map_region_selector.dart';
import 'widgets/property_bottom_sheet.dart';
import 'widgets/property_map_view.dart';

/// Ánh xạ danh sách BĐS (đang hiển thị theo filter) + vị trí hiện tại thành
/// danh sách marker cho [PropertyMapView]. Tách khỏi [MapScreen] để test
/// được bằng Dart thuần — không cần dựng renderer bản đồ thật.
///
/// [properties] được đưa vào renderer theo thứ tự CŨ→MỚI (đảo ngược thứ tự
/// mới→cũ mặc định của [AppState.properties]) để BĐS mới hơn được vẽ sau,
/// nằm trên BĐS cũ hơn khi hai marker trùng/gần vị trí — không marker nào
/// bị ẩn, chỉ đơn giản là marker mới nổi lên trên.
@visibleForTesting
List<PropertyMapMarkerData> buildPropertyMarkers({
  required List<Property> properties,
  required GeoPoint? currentLocation,
  required void Function(Property property) onMarkerTap,
}) {
  final oldestFirst = properties.reversed;
  final markers = <PropertyMapMarkerData>[
    for (final property in oldestFirst)
      if (property.location != null)
        PropertyMapMarkerData(
          id: property.id,
          position: property.location!,
          status: property.status,
          price: property.price,
          onTap: () => onMarkerTap(property),
        ),
  ];
  if (currentLocation != null) {
    markers.add(
      PropertyMapMarkerData(
        id: 'current-location',
        position: currentLocation,
        isCurrentLocation: true,
      ),
    );
  }
  return markers;
}

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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _searchController = TextEditingController();

  _StatusFilter _filter = _StatusFilter.all;
  late MapAdvancedFilter _advancedFilter;
  String _query = '';
  PropertyMapController? _mapController;
  GeoPoint? _currentGeoLocation;
  bool _locating = false;

  /// Vùng bản đồ (PMTiles) đang hiển thị — cập nhật qua
  /// [PropertyMapView.onRegionChanged], dùng để tô sáng đúng nút trong
  /// [MapRegionSelector]. null trước khi map lần đầu báo cáo vùng (native
  /// style chưa load xong).
  String? _activeRegionId;

  /// Marker vị trí hiện tại là toggle, không phải hiển thị vĩnh viễn — nếu
  /// GPS trùng vị trí một BĐS, người dùng cần cách tắt nó đi để tap được
  /// marker BĐS bên dưới. Mặc định OFF mỗi khi Map Screen được dựng lại
  /// (không persist qua restart), tách biệt với [AppState.lastMapLocation]
  /// vốn vẫn luôn được cập nhật mỗi lần lấy GPS thành công.
  bool _showCurrentLocationMarker = false;

  @override
  void initState() {
    super.initState();
    // showPrice/showPriceUnit là lựa chọn đã persist qua AppState (mục 3) —
    // các trường filter khác (giá/loại BĐS) cố tình KHÔNG persist, chỉ áp
    // dụng trong phiên hiện tại, nên vẫn khởi tạo từ default của
    // MapAdvancedFilter.
    final appState = context.read<AppState>();
    _advancedFilter = MapAdvancedFilter(
      showPrice: appState.showPrice,
      showPriceUnit: appState.showPriceUnit,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation(AppRuntime? runtime) async {
    if (_locating) return;
    if (_showCurrentLocationMarker) {
      // Bấm lần 2: tắt marker, giữ nguyên camera — không cần gọi GPS lại.
      setState(() => _showCurrentLocationMarker = false);
      return;
    }
    if (runtime == null) return;
    setState(() => _locating = true);
    try {
      final point = await runtime.locationService.currentLocation();
      _currentGeoLocation = point;
      await _mapController?.animateTo(point, zoom: 16);
      if (mounted) context.read<AppState>().setLastMapLocation(point);
      if (mounted) setState(() => _showCurrentLocationMarker = true);
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

  void _onRegionChanged(SupportedMapRegion region) {
    if (mounted) setState(() => _activeRegionId = region.id);
    context.read<AppState>().setLastSupportedMapRegionId(region.id);
  }

  void _selectRegion(SupportedMapRegion region) {
    _mapController?.switchToRegion(region);
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final runtime = context.read<AppRuntime?>();
    final visibleProperties = state.properties
        .where((p) => _matches(p, state))
        .toList();
    final markerScale = state.markerScale;
    // Ưu tiên: (1) lastMapLocation NẾU còn nằm trong vùng phủ (HCM/Hà Nội)
    // → (2) vùng bản đồ ưu tiên đã lưu (lastSupportedMapRegionId) → (3) mặc
    // định TP.HCM. KHÔNG còn ưu tiên toạ độ BĐS đầu tiên đang hiển thị — đó
    // là dữ liệu filter/sort-dependent, không phải tín hiệu "vùng bản đồ
    // người dùng đang muốn xem", dễ gây mở app vào 1 vùng ngẫu nhiên tuỳ
    // BĐS nào lọt vào danh sách trước. Nếu lastMapLocation nằm NGOÀI vùng
    // phủ (vd. BĐS/vị trí cuối cùng ở Đà Lạt), KHÔNG mở app lần đầu vào nền
    // xám chỉ vì lý do đó — rơi về vùng ưu tiên đã lưu, không dùng toạ độ
    // ngoài vùng phủ làm initial camera. Không tự động gọi GPS chỉ để chọn
    // map mặc định lúc mở app (không popup permission bất ngờ).
    final lastMapLocation = state.lastMapLocation;
    final initialLocation =
        (lastMapLocation != null &&
            MapCoveragePolicy.isSupported(lastMapLocation))
        ? lastMapLocation
        : MapCoveragePolicy.regionById(
                state.lastSupportedMapRegionId,
              )?.defaultCenter ??
              MapCoveragePolicy.hcm.defaultCenter;

    return Scaffold(
      backgroundColor: AppColors.mapLand,
      body: Stack(
        children: [
          Positioned.fill(
            child: PropertyMapView(
              initialTarget: initialLocation,
              markers: buildPropertyMarkers(
                properties: visibleProperties,
                currentLocation: _showCurrentLocationMarker
                    ? _currentGeoLocation
                    : null,
                onMarkerTap: (property) => showPropertyPreviewSheet(
                  context,
                  property: property,
                  areaName: state.areaName(property.areaId),
                ),
              ),
              markerScale: markerScale,
              showPrice: _advancedFilter.showPrice,
              showPriceUnit: _advancedFilter.showPriceUnit,
              onMapReady: (controller) => _mapController = controller,
              onRegionChanged: _onRegionChanged,
              // Đẩy compass control gốc của MapLibre xuống dưới khối tìm
              // kiếm/filter chip/chọn vùng ở đầu màn hình — mặc định SDK đặt
              // sát góc trên-phải nên bị khối UI này che khuất hoàn toàn.
              compassViewMargins: const Point(8, 200),
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
                        final appState = context.read<AppState>();
                        final selected = await showAdvancedFilterSheet(
                          context,
                          initial: _advancedFilter,
                          activeMapRegionId: _activeRegionId,
                          onSelectMapRegion: _selectRegion,
                        );
                        if (selected != null && mounted) {
                          setState(() => _advancedFilter = selected);
                          unawaited(appState.setShowPrice(selected.showPrice));
                          unawaited(
                            appState.setShowPriceUnit(selected.showPriceUnit),
                          );
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
                  const SizedBox(height: 8),
                  MapRegionSelector(
                    activeRegionId: _activeRegionId,
                    onSelect: _selectRegion,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            // FAB "+ Thêm BĐS" (RootShell, ngoài MapScreen — MapScreen chỉ
            // là 1 cell trong IndexedStack, chia sẻ đúng vùng nội dung
            // Scaffold với RootShell) mặc định neo `endFloat`: cách đáy
            // vùng content (đúng bằng đáy Stack ở đây, vì MapScreen không
            // có bottomNavigationBar riêng) 16px, cao 56px chuẩn Material —
            // mép trên FAB cách đáy 16+56=72px. Đặt nút vị trí hiện tại
            // cách đáy 136px để mép dưới của nó cách mép trên FAB đúng 64px
            // (nằm giữa khoảng 60–70px yêu cầu) — đủ thoáng để không bấm
            // nhầm, đủ gần để bố cục gọn, và nằm THẲNG HÀNG NGANG với FAB
            // (cùng right: 16) để nhìn cân đối theo trục dọc.
            bottom: 136,
            child: _RoundIconButton(
              icon: Icons.my_location_rounded,
              iconColor: _showCurrentLocationMarker
                  ? currentLocationColor
                  : AppColors.navy,
              onTap: _locating ? null : () => _goToCurrentLocation(runtime),
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
  final Color iconColor;
  final VoidCallback? onTap;

  const _RoundIconButton({
    required this.icon,
    this.iconColor = AppColors.navy,
    required this.onTap,
  });

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
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}
