import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

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

  bool get _isImage {
    if (mimeType?.startsWith('image/') == true) return true;
    if (filePath != null) {
      final ext = p.extension(filePath!).toLowerCase();
      return ext == '.jpg' ||
          ext == '.jpeg' ||
          ext == '.png' ||
          ext == '.webp' ||
          ext == '.gif' ||
          ext == '.heic';
    }
    return false;
  }

  bool get _isPdf {
    if (mimeType == 'application/pdf') return true;
    if (filePath != null) {
      return p.extension(filePath!).toLowerCase() == '.pdf';
    }
    return false;
  }

  bool get _isWord {
    if (mimeType == 'application/msword' ||
        mimeType ==
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
      return true;
    }
    if (filePath != null) {
      final ext = p.extension(filePath!).toLowerCase();
      return ext == '.doc' || ext == '.docx';
    }
    return false;
  }

  bool get _isExcel {
    if (mimeType == 'application/vnd.ms-excel' ||
        mimeType ==
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
      return true;
    }
    if (filePath != null) {
      final ext = p.extension(filePath!).toLowerCase();
      return ext == '.xls' || ext == '.xlsx';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final path = filePath;
    if (path != null && _isImage) {
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
    if (_isPdf) {
      return Container(
        color: const Color(0xFFFDE8E8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.picture_as_pdf_rounded,
              size: 32,
              color: Color(0xFFE02424),
            ),
            Positioned(
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFE02424),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PDF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isWord) {
      return Container(
        color: const Color(0xFFE1EFFE),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.article_rounded,
              size: 32,
              color: Color(0xFF1E429F),
            ),
            Positioned(
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E429F),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DOC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isExcel) {
      return Container(
        color: const Color(0xFFDEF7EC),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.table_chart_rounded,
              size: 32,
              color: Color(0xFF03543F),
            ),
            Positioned(
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF03543F),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'XLS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ColoredBox(
      color: AppColors.surfaceAlt,
      child: Center(
        child: Icon(
          _icons[seed % _icons.length],
          size: 30,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
