import 'package:flutter/material.dart';

import '../../../data/services/map/map_coverage_policy.dart';
import '../../../theme/app_colors.dart';

/// Lựa chọn nhanh "Khu vực bản đồ" (TP.HCM / Hà Nội) — dùng chung giữa Map
/// Screen, Advanced Filter Sheet, và Location Picker. Đây là chọn VÙNG
/// BASEMAP đang hiển thị, KHÔNG phải lọc BĐS theo khu vực — không đụng tới
/// filter/dữ liệu BĐS.
class MapRegionSelector extends StatelessWidget {
  final String? activeRegionId;
  final ValueChanged<SupportedMapRegion> onSelect;
  final EdgeInsetsGeometry padding;

  const MapRegionSelector({
    super.key,
    required this.activeRegionId,
    required this.onSelect,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          for (final region in MapCoveragePolicy.allRegions) ...[
            Expanded(
              child: _RegionChip(
                label: region.displayName,
                selected: region.id == activeRegionId,
                onTap: () => onSelect(region),
              ),
            ),
            if (region != MapCoveragePolicy.allRegions.last)
              const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RegionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy : AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
