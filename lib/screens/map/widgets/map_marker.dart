import 'package:flutter/material.dart';

import '../../../models/property_status.dart';
import '../../../theme/app_colors.dart';

class PropertyMarker extends StatelessWidget {
  final PropertyStatus status;
  final bool selected;
  final VoidCallback onTap;

  const PropertyMarker({
    super.key,
    required this.status,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = selected ? 22.0 : 16.0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36,
        height: 36,
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

  const MapClusterMarker({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = 34.0 + (count > 20 ? 10 : count > 10 ? 5 : 0);
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
                        color: Color(0xFF2F6FE4),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F6FE4),
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
