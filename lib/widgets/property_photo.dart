import 'dart:io';

import 'package:flutter/material.dart';

class PropertyPhotoView extends StatelessWidget {
  final String? filePath;
  final int seed;
  final BorderRadius? borderRadius;

  const PropertyPhotoView({
    super.key,
    this.filePath,
    this.seed = 0,
    this.borderRadius,
  });

  static const List<List<Color>> _gradients = [
    [Color(0xFFE8DCC8), Color(0xFFD3C0A0)],
    [Color(0xFFE3B7A0), Color(0xFFC5876A)],
    [Color(0xFFC9D6C3), Color(0xFFA3BB98)],
    [Color(0xFFC3D3DE), Color(0xFF95AFC2)],
    [Color(0xFFD9C2B0), Color(0xFFB89478)],
    [Color(0xFFD3D2B8), Color(0xFFB2B38D)],
    [Color(0xFFE6C8C8), Color(0xFFCA9A9A)],
    [Color(0xFFDADCE0), Color(0xFFB8BCC3)],
  ];

  static const List<IconData> _icons = [
    Icons.villa_outlined,
    Icons.apartment_outlined,
    Icons.home_work_outlined,
    Icons.cottage_outlined,
    Icons.house_outlined,
    Icons.domain_outlined,
    Icons.holiday_village_outlined,
    Icons.other_houses_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final path = filePath;
    if (path != null) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(),
        ),
      );
    }
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: _placeholder(),
    );
  }

  Widget _placeholder() {
    final colors = _gradients[seed % _gradients.length];
    final icon = _icons[seed % _icons.length];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Icon(
              icon,
              size: 42,
              color: Colors.white.withValues(alpha: 0.38),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
