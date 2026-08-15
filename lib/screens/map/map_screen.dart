import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/app_runtime.dart';
import '../../data/services/location_service.dart';
import '../../models/geo_point.dart';
import '../../models/property.dart';
import '../../models/property_status.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_search_bar.dart';
import 'widgets/advanced_filter_sheet.dart';
import 'widgets/property_bottom_sheet.dart';
import 'widgets/property_map_view.dart';

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
  static const GeoPoint _hanoi = GeoPoint(
    latitude: 21.0285,
    longitude: 105.8542,
  );

  final TextEditingController _searchController = TextEditingController();

  _StatusFilter _filter = _StatusFilter.all;
  MapAdvancedFilter _advancedFilter = const MapAdvancedFilter();
  String _query = '';
  PropertyMapController? _mapController;
  GeoPoint? _currentGeoLocation;
  bool _locating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation(AppRuntime? runtime) async {
    if (runtime == null || _locating) return;
    setState(() => _locating = true);
    try {
      final point = await runtime.locationService.currentLocation();
      _currentGeoLocation = point;
      await _mapController?.animateTo(point, zoom: 16);
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
    } finally {
      if (mounted) setState(() => _locating = false);
    }
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

  List<PropertyMapMarkerData> _buildMarkers(
    BuildContext context,
    List<Property> properties,
    AppState state,
  ) {
    final markers = <PropertyMapMarkerData>[
      for (final property in properties)
        if (property.location != null)
          PropertyMapMarkerData(
            id: property.id,
            position: property.location!,
            status: property.status,
            onTap: () => showPropertyPreviewSheet(
              context,
              property: property,
              areaName: state.areaName(property.areaId),
            ),
          ),
    ];
    final current = _currentGeoLocation;
    if (current != null) {
      markers.add(
        PropertyMapMarkerData(
          id: 'current-location',
          position: current,
          isCurrentLocation: true,
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final runtime = context.read<AppRuntime?>();
    final visibleProperties = state.properties
        .where((p) => _matches(p, state))
        .toList();
    final markerScale = state.markerScale;
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
            child: PropertyMapView(
              initialTarget: initialLocation,
              markers: _buildMarkers(context, visibleProperties, state),
              markerScale: markerScale,
              onMapReady: (controller) => _mapController = controller,
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
  final VoidCallback? onTap;

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
