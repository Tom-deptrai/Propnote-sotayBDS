import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../models/marker_size.dart';
import '../../models/property.dart';
import '../../models/property_status.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_search_bar.dart';
import 'map_constants.dart';
import 'widgets/advanced_filter_sheet.dart';
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

const Offset _currentLocation = Offset(0.40, 0.46);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController =
      TransformationController();
  late final AnimationController _animController;
  final TextEditingController _searchController = TextEditingController();

  _StatusFilter _filter = _StatusFilter.all;
  String _query = '';
  Size _viewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOn(
          Offset(mapCanvasSize.width * 0.44, mapCanvasSize.height * 0.46),
          scale: 0.62,
        ));
  }

  @override
  void dispose() {
    _animController.dispose();
    _transformController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _centerOn(Offset canvasPoint, {double scale = 1.4}) {
    if (_viewportSize == Size.zero) return;
    final tx = _viewportSize.width / 2 - canvasPoint.dx * scale;
    final ty = _viewportSize.height / 2 - canvasPoint.dy * scale;
    final target = Matrix4(
      scale, 0, 0, 0,
      0, scale, 0, 0,
      0, 0, 1, 0,
      tx, ty, 0, 1,
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
    if (_query.trim().isEmpty) return true;
    final q = _query.trim().toLowerCase();
    final area = state.areaName(p.areaId).toLowerCase();
    return p.title.toLowerCase().contains(q) ||
        p.address.toLowerCase().contains(q) ||
        area.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final visibleProperties =
        state.properties.where((p) => _matches(p, state)).toList();
    final markerScale = state.markerSize.scale;
    final clusterHalf = (34.0 * (0.7 + markerScale * 0.3)) / 2;
    final propertyHalf = (36.0 * markerScale).clamp(36.0, 52.0) / 2;

    return Scaffold(
      backgroundColor: AppColors.mapLand,
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
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
                            left: mapCanvasSize.width * _currentLocation.dx - 32,
                            top: mapCanvasSize.height * _currentLocation.dy - 32,
                            child: const CurrentLocationMarker(),
                          ),
                          for (final cluster in mockMapClusters)
                            Positioned(
                              left: mapCanvasSize.width * cluster.x - clusterHalf,
                              top: mapCanvasSize.height * cluster.y - clusterHalf,
                              child: MapClusterMarker(
                                count: cluster.count,
                                scale: markerScale,
                                onTap: () => _centerOn(
                                  Offset(
                                    mapCanvasSize.width * cluster.x,
                                    mapCanvasSize.height * cluster.y,
                                  ),
                                  scale: 2.0,
                                ),
                              ),
                            ),
                          for (final p in visibleProperties)
                            Positioned(
                              left: mapCanvasSize.width * p.mapX - propertyHalf,
                              top: mapCanvasSize.height * p.mapY - propertyHalf,
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
                      onTap: () => showAdvancedFilterSheet(context),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.tune_rounded,
                          color: AppColors.navy,
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
              onTap: () => _centerOn(
                Offset(
                  mapCanvasSize.width * _currentLocation.dx,
                  mapCanvasSize.height * _currentLocation.dy,
                ),
                scale: 1.3,
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
