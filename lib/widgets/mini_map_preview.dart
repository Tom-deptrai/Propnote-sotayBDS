import 'package:flutter/material.dart';

import '../models/geo_point.dart';
import '../models/property_status.dart';
import '../screens/map/widgets/property_map_view.dart';
import '../theme/app_colors.dart';

class MiniMapPreview extends StatelessWidget {
  final GeoPoint location;
  final PropertyStatus status;
  final double height;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  const MiniMapPreview({
    super.key,
    required this.location,
    required this.status,
    this.height = 140,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
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
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: PropertyMapView(
                    initialTarget: location,
                    initialZoom: 15,
                    interactive: false,
                    showCompass: false,
                    markers: [
                      PropertyMapMarkerData(
                        id: 'preview',
                        position: location,
                        status: status,
                      ),
                    ],
                  ),
                ),
              ),
              if (onTap != null) _openMapLabel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _openMapLabel() {
    return Positioned(
      right: 10,
      bottom: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.open_in_full_rounded, size: 13, color: AppColors.navy),
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
    );
  }
}
