import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/app_state.dart';
import '../../../theme/app_colors.dart';

class MapAdvancedFilter {
  final double minimumPriceBillions;
  final double maximumPriceBillions;
  final Set<String> propertyTypes;

  const MapAdvancedFilter({
    this.minimumPriceBillions = 0,
    this.maximumPriceBillions = 50,
    this.propertyTypes = const {},
  });

  bool get isDefault =>
      minimumPriceBillions == 0 &&
      maximumPriceBillions == 50 &&
      propertyTypes.isEmpty;
}

Future<MapAdvancedFilter?> showAdvancedFilterSheet(
  BuildContext context, {
  MapAdvancedFilter initial = const MapAdvancedFilter(),
}) {
  return showModalBottomSheet<MapAdvancedFilter>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AdvancedFilterSheet(initial: initial),
  );
}

class _AdvancedFilterSheet extends StatefulWidget {
  final MapAdvancedFilter initial;

  const _AdvancedFilterSheet({required this.initial});

  @override
  State<_AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<_AdvancedFilterSheet> {
  late RangeValues _price = RangeValues(
    widget.initial.minimumPriceBillions,
    widget.initial.maximumPriceBillions,
  );
  late final Set<String> _types = Set.of(widget.initial.propertyTypes);

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
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _price = const RangeValues(0, 50);
                        _types.clear();
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
    );
  }
}
