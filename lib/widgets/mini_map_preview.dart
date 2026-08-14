import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/geo_point.dart';
import '../screens/map/map_constants.dart';
import '../screens/map/widgets/map_background_painter.dart';
import '../theme/app_colors.dart';

class MiniMapPreview extends StatelessWidget {
  final GeoPoint location;
  final bool useGoogleMaps;
  final double height;
  final BorderRadius borderRadius;
  final Color pinColor;
  final VoidCallback? onTap;

  const MiniMapPreview({
    super.key,
    required this.location,
    this.useGoogleMaps = false,
    this.height = 140,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.pinColor = AppColors.navy,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedPosition = location.toLegacyNormalized();
    return ClipRRect(
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: useGoogleMaps
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              location.latitude,
                              location.longitude,
                            ),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('property-preview'),
                              position: LatLng(
                                location.latitude,
                                location.longitude,
                              ),
                            ),
                          },
                          liteModeEnabled: true,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          myLocationButtonEnabled: false,
                        ),
                      ),
                    ),
                    if (onTap != null) _openMapLabel(),
                  ],
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final previewSize = constraints.biggest;
                    const scale = 2.2;
                    final dx =
                        previewSize.width / 2 -
                        mapCanvasSize.width * normalizedPosition.x * scale;
                    final dy =
                        previewSize.height / 2 -
                        mapCanvasSize.height * normalizedPosition.y * scale;
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ColoredBox(color: AppColors.mapLand),
                        ),
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
                        if (onTap != null) _openMapLabel(),
                      ],
                    );
                  },
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
