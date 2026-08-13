import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Vẽ một bản đồ cách điệu (visually realistic) hoàn toàn offline —
/// không dùng tile ảnh thật — gồm sông, công viên, khối nhà và mạng lưới
/// đường xá, cùng nhãn khu vực mờ để định hướng.
class MapBackgroundPainter extends CustomPainter {
  const MapBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = AppColors.mapLand,
    );

    _drawRiver(canvas, w, h);
    _drawParks(canvas, w, h);
    _drawRoads(canvas, w, h);
    _drawBlocks(canvas, w, h);
    _drawLabels(canvas, w, h);
  }

  void _drawRiver(Canvas canvas, double w, double h) {
    final path = Path()
      ..moveTo(w * 0.42, -10)
      ..cubicTo(w * 0.50, h * 0.15, w * 0.34, h * 0.28, w * 0.40, h * 0.42)
      ..cubicTo(w * 0.46, h * 0.55, w * 0.66, h * 0.60, w * 0.62, h * 0.75)
      ..cubicTo(w * 0.59, h * 0.86, w * 0.68, h * 0.94, w * 0.78, h + 10)
      ..lineTo(w * 0.86, h + 10)
      ..cubicTo(w * 0.74, h * 0.90, w * 0.68, h * 0.80, w * 0.70, h * 0.72)
      ..cubicTo(w * 0.74, h * 0.60, w * 0.54, h * 0.54, w * 0.48, h * 0.40)
      ..cubicTo(w * 0.44, h * 0.28, w * 0.58, h * 0.16, w * 0.52, -10)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.mapWater);
  }

  void _drawParks(Canvas canvas, double w, double h) {
    final paint = Paint()..color = AppColors.mapPark;
    _blob(canvas, Offset(w * 0.47, h * 0.52), w * 0.075, paint);
    _blob(canvas, Offset(w * 0.20, h * 0.68), w * 0.05, paint);
    _blob(canvas, Offset(w * 0.72, h * 0.20), w * 0.045, paint);
  }

  void _blob(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    const points = 10;
    for (int i = 0; i <= points; i++) {
      final angle = (i / points) * 2 * math.pi;
      final wob = 1.0 + 0.18 * math.sin(angle * 3 + center.dx);
      final p = Offset(
        center.dx + r * wob * math.cos(angle),
        center.dy + r * wob * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawRoads(Canvas canvas, double w, double h) {
    final casing = Paint()
      ..color = AppColors.mapRoadShade
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final surface = Paint()
      ..color = AppColors.mapRoad
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final majorRoads = <List<Offset>>[
      [Offset(0, h * 0.18), Offset(w, h * 0.22)],
      [Offset(0, h * 0.48), Offset(w, h * 0.50)],
      [Offset(0, h * 0.78), Offset(w, h * 0.74)],
      [Offset(w * 0.22, 0), Offset(w * 0.30, h)],
      [Offset(w * 0.55, 0), Offset(w * 0.50, h)],
      [Offset(w * 0.80, 0), Offset(w * 0.85, h)],
    ];

    for (final road in majorRoads) {
      casing.strokeWidth = 9;
      canvas.drawLine(road[0], road[1], casing);
      surface.strokeWidth = 5.5;
      canvas.drawLine(road[0], road[1], surface);
    }

    final minorCasing = Paint()
      ..color = AppColors.mapRoadShade.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final minorSurface = Paint()
      ..color = AppColors.mapRoad
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i < 10; i++) {
      final y = h * (i / 10);
      canvas.drawLine(Offset(0, y), Offset(w, y + 14), minorCasing);
      canvas.drawLine(Offset(0, y), Offset(w, y + 14), minorSurface);
    }
    for (int i = 1; i < 9; i++) {
      final x = w * (i / 9);
      canvas.drawLine(Offset(x, 0), Offset(x - 10, h), minorCasing);
      canvas.drawLine(Offset(x, 0), Offset(x - 10, h), minorSurface);
    }
  }

  void _drawBlocks(Canvas canvas, double w, double h) {
    final rng = math.Random(7);
    for (int i = 0; i < 46; i++) {
      final cx = rng.nextDouble() * w;
      final cy = rng.nextDouble() * h;
      final bw = 18.0 + rng.nextDouble() * 46;
      final bh = 18.0 + rng.nextDouble() * 30;
      final alt = rng.nextBool();
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: bw, height: bh),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        rrect,
        Paint()..color = alt ? AppColors.mapBlockAlt : AppColors.mapBlock,
      );
    }
  }

  void _drawLabels(Canvas canvas, double w, double h) {
    final labels = <String, Offset>{
      'CẦU GIẤY': Offset(w * 0.20, h * 0.10),
      'NAM TỪ LIÊM': Offset(w * 0.10, h * 0.40),
      'HÀ ĐÔNG': Offset(w * 0.56, h * 0.72),
      'THANH XUÂN': Offset(w * 0.42, h * 0.50),
      'ĐỐNG ĐA': Offset(w * 0.58, h * 0.26),
    };
    for (final entry in labels.entries) {
      final tp = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: TextStyle(
            color: AppColors.textTertiary.withValues(alpha: 0.55),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, entry.value);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
