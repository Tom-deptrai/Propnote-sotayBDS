import 'package:flutter/material.dart';

import '../../../models/list_sort_option.dart';
import '../../../models/property_status.dart';
import '../../../theme/app_colors.dart';

class ListFilters {
  final Set<PropertyStatus> statuses;
  final RangeValues price;
  final RangeValues area;
  final ListSortOption sort;

  const ListFilters({
    this.statuses = const {},
    this.price = const RangeValues(0, 50),
    this.area = const RangeValues(0, 250),
    this.sort = ListSortOption.newest,
  });

  bool get isActive =>
      statuses.isNotEmpty ||
      price.start > 0 ||
      price.end < 50 ||
      area.start > 0 ||
      area.end < 250 ||
      sort != ListSortOption.newest;

  ListFilters copyWith({
    Set<PropertyStatus>? statuses,
    RangeValues? price,
    RangeValues? area,
    ListSortOption? sort,
  }) {
    return ListFilters(
      statuses: statuses ?? this.statuses,
      price: price ?? this.price,
      area: area ?? this.area,
      sort: sort ?? this.sort,
    );
  }
}

Future<ListFilters?> showListFilterSheet(
  BuildContext context,
  ListFilters current,
) {
  return showModalBottomSheet<ListFilters>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ListFilterSheet(initial: current),
  );
}

class _ListFilterSheet extends StatefulWidget {
  final ListFilters initial;

  const _ListFilterSheet({required this.initial});

  @override
  State<_ListFilterSheet> createState() => _ListFilterSheetState();
}

class _ListFilterSheetState extends State<_ListFilterSheet> {
  late final Set<PropertyStatus> _statuses = {...widget.initial.statuses};
  late RangeValues _price = widget.initial.price;
  late RangeValues _area = widget.initial.area;
  late ListSortOption _sort = widget.initial.sort;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bộ lọc', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () => setState(() {
                      _statuses.clear();
                      _price = const RangeValues(0, 50);
                      _area = const RangeValues(0, 250);
                      _sort = ListSortOption.newest;
                    }),
                    child: const Text('Đặt lại'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Sắp xếp', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ListSortOption.values.map((option) {
                  final selected = _sort == option;
                  return ChoiceChip(
                    label: Text(option.label),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _sort = option),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Trạng thái', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PropertyStatus.values.map((s) {
                  final selected = _statuses.contains(s);
                  return FilterChip(
                    label: Text(s.label),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: s.color.withValues(alpha: 0.14),
                    labelStyle: TextStyle(
                      color: selected ? s.color : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: selected ? s.color : AppColors.border,
                    ),
                    onSelected: (v) {
                      setState(
                        () => v ? _statuses.add(s) : _statuses.remove(s),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Khoảng giá: ${_price.start.toStringAsFixed(0)} - ${_price.end.toStringAsFixed(0)} tỷ',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              RangeSlider(
                values: _price,
                min: 0,
                max: 50,
                divisions: 25,
                activeColor: AppColors.navy,
                inactiveColor: AppColors.border,
                onChanged: (v) => setState(() => _price = v),
              ),
              const SizedBox(height: 8),
              Text(
                'Diện tích: ${_area.start.toStringAsFixed(0)} - ${_area.end.toStringAsFixed(0)} m²',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              RangeSlider(
                values: _area,
                min: 0,
                max: 250,
                divisions: 25,
                activeColor: AppColors.navy,
                inactiveColor: AppColors.border,
                onChanged: (v) => setState(() => _area = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      ListFilters(
                        statuses: _statuses,
                        price: _price,
                        area: _area,
                        sort: _sort,
                      ),
                    );
                  },
                  child: const Text('Áp dụng bộ lọc'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
