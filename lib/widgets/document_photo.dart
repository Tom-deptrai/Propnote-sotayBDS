import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DocumentPhotoView extends StatelessWidget {
  final String? filePath;
  final String? mimeType;
  final int seed;
  final BorderRadius? borderRadius;

  const DocumentPhotoView({
    super.key,
    this.filePath,
    this.mimeType,
    this.seed = 0,
    this.borderRadius,
  });

  static const List<IconData> _icons = [
    Icons.description_outlined,
    Icons.receipt_long_outlined,
    Icons.map_outlined,
    Icons.badge_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final path = filePath;
    if (path != null && mimeType?.startsWith('image/') == true) {
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
    return ColoredBox(
      color: AppColors.surfaceAlt,
      child: Center(
        child: Icon(
          mimeType == 'application/pdf'
              ? Icons.picture_as_pdf_outlined
              : _icons[seed % _icons.length],
          size: 32,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
