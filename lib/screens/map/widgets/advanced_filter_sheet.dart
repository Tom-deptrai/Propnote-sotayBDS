import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/map/map_coverage_policy.dart';
import '../../../state/app_state.dart';
import '../../../theme/app_colors.dart';
import 'map_region_selector.dart';

class MapAdvancedFilter {
  final double minimumPriceBillions;
  final double maximumPriceBillions;
  final Set<String> propertyTypes;
  final bool showPrice;
  final bool showPriceUnit;

  const MapAdvancedFilter({
    this.minimumPriceBillions = 0,
    this.maximumPriceBillions = 50,
    this.propertyTypes = const {},
    this.showPrice = true,
    this.showPriceUnit = true,
  });

  bool get isDefault =>
      minimumPriceBillions == 0 &&
      maximumPriceBillions == 50 &&
      propertyTypes.isEmpty &&
      showPrice == true &&
      showPriceUnit == true;
}

Future<MapAdvancedFilter?> showAdvancedFilterSheet(
  BuildContext context, {
  MapAdvancedFilter initial = const MapAdvancedFilter(),
  String? activeMapRegionId,
  ValueChanged<SupportedMapRegion>? onSelectMapRegion,
}) {
  return showModalBottomSheet<MapAdvancedFilter>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AdvancedFilterSheet(
      initial: initial,
      activeMapRegionId: activeMapRegionId,
      onSelectMapRegion: onSelectMapRegion,
    ),
  );
}

class _AdvancedFilterSheet extends StatefulWidget {
  final MapAdvancedFilter initial;

  /// "Khu vực bản đồ" (TP.HCM/Hà Nội) là lựa chọn VÙNG BASEMAP, KHÔNG phải
  /// tiêu chí lọc BĐS — cố tình tách khỏi [MapAdvancedFilter]/nút Áp dụng:
  /// bấm là chuyển vùng ngay, không cần bấm "Áp dụng", và không ảnh hưởng gì
  /// tới danh sách BĐS/filter khác đang chọn.
  final String? activeMapRegionId;
  final ValueChanged<SupportedMapRegion>? onSelectMapRegion;

  const _AdvancedFilterSheet({
    required this.initial,
    this.activeMapRegionId,
    this.onSelectMapRegion,
  });

  @override
  State<_AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<_AdvancedFilterSheet> {
  late RangeValues _price = RangeValues(
    widget.initial.minimumPriceBillions,
    widget.initial.maximumPriceBillions,
  );
  late final Set<String> _types = Set.of(widget.initial.propertyTypes);
  late bool _showPrice = widget.initial.showPrice;
  late bool _showPriceUnit = widget.initial.showPriceUnit;
  late String? _activeMapRegionId = widget.activeMapRegionId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bộ lọc nâng cao',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (widget.onSelectMapRegion != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Khu vực bản đồ',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chuyển vùng bản đồ nền đang xem — không liên quan tới lọc '
                  'bất động sản.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 8),
                MapRegionSelector(
                  activeRegionId: _activeMapRegionId,
                  onSelect: (region) {
                    widget.onSelectMapRegion!(region);
                    setState(() => _activeMapRegionId = region.id);
                  },
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kích thước điểm đánh dấu',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  InkWell(
                    onTap: state.resetMarkerScale,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Đặt lại',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  Expanded(
                    child: Slider(
                      value: state.markerScale,
                      min: AppState.markerScaleMin,
                      max: AppState.markerScaleMax,
                      activeColor: AppColors.navy,
                      inactiveColor: AppColors.border,
                      onChanged: state.setMarkerScale,
                    ),
                  ),
                  const Icon(
                    Icons.location_on,
                    size: 26,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Khoảng giá (tỷ đồng)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              RangeSlider(
                values: _price,
                min: 0,
                max: 50,
                divisions: 25,
                activeColor: AppColors.navy,
                inactiveColor: AppColors.border,
                labels: RangeLabels(
                  _price.start.toStringAsFixed(0),
                  _price.end.toStringAsFixed(0),
                ),
                onChanged: (v) => setState(() => _price = v),
              ),
              const SizedBox(height: 4),
              Text(
                'Loại bất động sản',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.propertyTypes.map((t) {
                  final selected = _types.contains(t);
                  return FilterChip(
                    label: Text(t),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (v) {
                      setState(() => v ? _types.add(t) : _types.remove(t));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Hiển thị giá',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                value: _showPrice,
                onChanged: (v) => setState(() => _showPrice = v),
              ),
              if (_showPrice)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Hiển thị đơn vị tỷ',
                    style: TextStyle(fontSize: 13.5),
                  ),
                  value: _showPriceUnit,
                  onChanged: (v) => setState(() => _showPriceUnit = v),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _price = const RangeValues(0, 50);
                          _types.clear();
                          _showPrice = true;
                          _showPriceUnit = true;
                        });
                        state.resetMarkerScale();
                      },
                      child: const Text('Đặt lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          MapAdvancedFilter(
                            minimumPriceBillions: _price.start,
                            maximumPriceBillions: _price.end,
                            propertyTypes: Set.unmodifiable(_types),
                            showPrice: _showPrice,
                            showPriceUnit: _showPriceUnit,
                          ),
                        );
                      },
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
