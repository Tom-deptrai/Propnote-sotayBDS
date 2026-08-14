import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../models/property_status.dart';

class GoogleMarkerIconFactory {
  final Map<String, BitmapDescriptor> _cache = {};

  int get cacheSize => _cache.length;

  String cacheKey(
    PropertyStatus status,
    double scale,
    double devicePixelRatio,
  ) {
    final scaleStep = (scale * 10).round();
    final pixelRatioStep = (devicePixelRatio * 10).round();
    return '${status.name}:$scaleStep:$pixelRatioStep';
  }

  Future<BitmapDescriptor> iconFor({
    required PropertyStatus status,
    required double scale,
    required double devicePixelRatio,
  }) async {
    final key = cacheKey(status, scale, devicePixelRatio);
    final cached = _cache[key];
    if (cached != null) return cached;

    final logicalSize = 42.0 * scale;
    final pixels = (logicalSize * devicePixelRatio).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(devicePixelRatio);

    final center = Offset(logicalSize / 2, logicalSize / 2 - 2);
    final radius = logicalSize * 0.28;
    canvas.drawCircle(
      center.translate(0, 2),
      radius + 3,
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawCircle(center, radius + 2, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius, Paint()..color = status.color);
    canvas.drawCircle(center, radius * 0.35, Paint()..color = Colors.white);

    final picture = recorder.endRecording();
    final image = await picture.toImage(pixels, pixels);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) {
      return BitmapDescriptor.defaultMarkerWithHue(_hueFor(status));
    }
    final descriptor = BitmapDescriptor.bytes(
      data.buffer.asUint8List(),
      width: logicalSize,
      height: logicalSize,
    );
    _cache[key] = descriptor;
    return descriptor;
  }

  double _hueFor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.selling:
        return BitmapDescriptor.hueRed;
      case PropertyStatus.unsurveyed:
        return BitmapDescriptor.hueGreen;
      case PropertyStatus.sold:
        return BitmapDescriptor.hueRose;
    }
  }
}
