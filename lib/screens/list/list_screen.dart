import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/list_sort_option.dart';
import '../../models/property.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/property_card.dart';
import '../detail/property_detail_screen.dart';
import 'widgets/list_filter_sheet.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedAreaId = 'all';
  ListFilters _filters = const ListFilters();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(Property p, AppState state) {
    if (_selectedAreaId != 'all' && p.areaId != _selectedAreaId) return false;
    if (_filters.statuses.isNotEmpty && !_filters.statuses.contains(p.status)) {
      return false;
    }
    if (p.price > 0 &&
        (p.price / 1e9 < _filters.price.start ||
            p.price / 1e9 > _filters.price.end)) {
      return false;
    }
    if (p.landArea < _filters.area.start || p.landArea > _filters.area.end) {
      return false;
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      final area = state.areaName(p.areaId).toLowerCase();
      final matchesText =
          p.title.toLowerCase().contains(q) ||
          p.address.toLowerCase().contains(q) ||
          area.contains(q) ||
          p.propertyType.toLowerCase().contains(q) ||
          p.notes.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
      if (!matchesText) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final results = state.properties.where((p) => _matches(p, state)).toList()
      ..sort(_filters.sort.compare);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Danh sách',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${results.length} bất động sản',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppSearchBar(
                controller: _searchController,
                hintText: 'Tìm bất động sản, địa chỉ, khu vực...',
                onChanged: (v) => setState(() => _query = v),
                elevated: false,
                trailing: InkWell(
                  onTap: () async {
                    final result = await showListFilterSheet(context, _filters);
                    if (result != null) setState(() => _filters = result);
                  },
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.tune_rounded,
                      color: _filters.isActive
                          ? AppColors.navy
                          : AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _AreaTab(
                    label: 'Tất cả',
                    selected: _selectedAreaId == 'all',
                    onTap: () => setState(() => _selectedAreaId = 'all'),
                  ),
                  const SizedBox(width: 8),
                  for (final area in state.areas) ...[
                    _AreaTab(
                      label: area.name,
                      selected: _selectedAreaId == area.id,
                      onTap: () => setState(() => _selectedAreaId = area.id),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),
            Expanded(
              child: results.isEmpty
                  ? const _EmptyResults()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final p = results[i];
                        return PropertyCard(
                          property: p,
                          areaName: state.areaName(p.areaId),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PropertyDetailScreen(propertyId: p.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AreaTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.textTertiary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy bất động sản',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Thử thay đổi từ khoá tìm kiếm hoặc bộ lọc.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
