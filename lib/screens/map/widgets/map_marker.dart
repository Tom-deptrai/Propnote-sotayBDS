import 'package:flutter/material.dart';

import '../../../models/property_status.dart';
import '../../../theme/app_colors.dart';

class PropertyMarker extends StatelessWidget {
  final PropertyStatus status;
  final bool selected;
  final VoidCallback onTap;
  final double scale;

  const PropertyMarker({
    super.key,
    required this.status,
    required this.onTap,
    this.selected = false,
    this.scale = 1.0,
  });

  /// Kích thước vùng chạm cho một marker BĐS ở [scale] cho trước — dùng cả
  /// khi vẽ marker lẫn khi tính offset căn giữa trên canvas bản đồ.
  static double hitBoxFor(double scale) => (40.0 * scale).clamp(30.0, 60.0);

  @override
  Widget build(BuildContext context) {
    final size = (selected ? 26.0 : 20.0) * scale;
    final hitBox = hitBoxFor(scale);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: hitBox,
        height: hitBox,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MapClusterMarker extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final double scale;

  const MapClusterMarker({
    super.key,
    required this.count,
    required this.onTap,
    this.scale = 1.0,
  });

  /// Cluster scale "dịu" hơn marker thường — tăng/giảm có cảm nhận được
  /// nhưng không lấn át bố cục bản đồ ở các mức scale lớn.
  static double sizeFor(int count, double scale) {
    final base =
        34.0 +
        (count > 20
            ? 10
            : count > 10
            ? 5
            : 0);
    return base * (0.5 + scale * 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final size = sizeFor(count, scale);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.navy,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Màu chấm vị trí hiện tại — dùng chung cho overlay marker và icon nút bật
/// GPS trên Map Screen để hai trạng thái nhìn nhất quán với nhau.
const Color currentLocationColor = Color(0xFF2F6FE4);

class CurrentLocationMarker extends StatefulWidget {
  const CurrentLocationMarker({super.key});

  @override
  State<CurrentLocationMarker> createState() => _CurrentLocationMarkerState();
}

class _CurrentLocationMarkerState extends State<CurrentLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0) * 0.35,
                    child: Container(
                      width: 20 + t * 40,
                      height: 20 + t * 40,
                      decoration: const BoxDecoration(
                        color: currentLocationColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: currentLocationColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                        ),
                      ],
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
