import 'package:flutter/material.dart';

import '../../../data/mock_data.dart';
import '../../../theme/app_colors.dart';

Future<void> showAdvancedFilterSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _AdvancedFilterSheet(),
  );
}

class _AdvancedFilterSheet extends StatefulWidget {
  const _AdvancedFilterSheet();

  @override
  State<_AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<_AdvancedFilterSheet> {
  RangeValues _price = const RangeValues(0, 50);
  final Set<String> _types = {};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
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
            const SizedBox(height: 18),
            Text('Bộ lọc nâng cao', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
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
            const SizedBox(height: 8),
            Text('Loại bất động sản', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mockPropertyTypes.map((t) {
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
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _price = const RangeValues(0, 50);
                        _types.clear();
                      });
                    },
                    child: const Text('Đặt lại'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã áp dụng bộ lọc (demo)')),
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
