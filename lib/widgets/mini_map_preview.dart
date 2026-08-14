import 'package:flutter/material.dart';

import '../screens/map/map_constants.dart';
import '../screens/map/widgets/map_background_painter.dart';
import '../theme/app_colors.dart';

/// Ảnh xem trước vị trí trên bản đồ mock — tĩnh, không tương tác, dùng ở
/// màn hình Thêm BĐS và Chi tiết BĐS.
class MiniMapPreview extends StatelessWidget {
  final Offset normalizedPosition;
  final double height;
  final BorderRadius borderRadius;
  final Color pinColor;
  final VoidCallback? onTap;

  const MiniMapPreview({
    super.key,
    required this.normalizedPosition,
    this.height = 140,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.pinColor = AppColors.navy,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final previewSize = constraints.biggest;
              const scale = 2.2;
              final dx =
                  previewSize.width / 2 -
                  mapCanvasSize.width * normalizedPosition.dx * scale;
              final dy =
                  previewSize.height / 2 -
                  mapCanvasSize.height * normalizedPosition.dy * scale;
              return Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: AppColors.mapLand)),
                  Positioned(
                    left: dx,
                    top: dy,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: mapCanvasSize.width,
                        height: mapCanvasSize.height,
                        child: const CustomPaint(
                          painter: MapBackgroundPainter(),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.location_on_rounded,
                      color: pinColor,
                      size: 34,
                    ),
                  ),
                  if (onTap != null)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.open_in_full_rounded,
                              size: 13,
                              color: AppColors.navy,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Xem bản đồ',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
