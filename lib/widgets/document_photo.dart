import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Placeholder cho tài liệu/hình bổ sung (sổ nhà, giấy tờ, sơ đồ...) —
/// cố ý trung tính, khác phong cách với [PropertyPhoto] để không lẫn với
/// ảnh BĐS chính.
class DocumentPhoto extends StatelessWidget {
  final int seed;
  final BorderRadius? borderRadius;

  const DocumentPhoto({super.key, required this.seed, this.borderRadius});

  static const List<IconData> _icons = [
    Icons.description_outlined,
    Icons.receipt_long_outlined,
    Icons.map_outlined,
    Icons.badge_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: ColoredBox(
        color: AppColors.surfaceAlt,
        child: Center(
          child: Icon(
            _icons[seed % _icons.length],
            size: 32,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
