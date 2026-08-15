import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../models/property_status.dart';
import 'map_marker.dart';

/// Sinh icon bitmap (PNG bytes) cho marker BĐS và marker vị trí hiện tại,
/// dùng để đăng ký với renderer bản đồ qua `addImage`.
///
/// Renderer-agnostic: chỉ vẽ pixel và trả về bytes + tên cache key ổn định,
/// không phụ thuộc SDK bản đồ cụ thể nào.
class PropertyMapMarkerIcons {
  final Map<String, Uint8List> _cache = {};

  int get cacheSize => _cache.length;

  String cacheKey(PropertyStatus status, double scale, double devicePixelRatio) {
    final scaleStep = (scale * 10).round();
    final pixelRatioStep = (devicePixelRatio * 10).round();
    return 'status:${status.name}:$scaleStep:$pixelRatioStep';
  }

  String currentLocationCacheKey(double devicePixelRatio) {
    final pixelRatioStep = (devicePixelRatio * 10).round();
    return 'current-location:$pixelRatioStep';
  }

  /// Trả về (bytes PNG, iconSize) — [iconSize] là hệ số cần truyền vào
  /// SymbolOptions.iconSize để bù lại devicePixelRatio, giữ kích thước hiển
  /// thị trên màn hình đúng bằng [PropertyMarker.hitBoxFor]/dot size mong
  /// muốn bất kể mật độ điểm ảnh thiết bị.
  Future<(Uint8List bytes, double iconSize)> iconFor({
    required PropertyStatus status,
    required double scale,
    required double devicePixelRatio,
  }) async {
    final key = cacheKey(status, scale, devicePixelRatio);
    final cached = _cache[key];
    final logicalSize = (PropertyMarker.hitBoxFor(scale) * 0.68).clamp(
      20.0,
      45.0,
    );
    if (cached != null) return (cached, 1 / devicePixelRatio);

    final bytes = await _renderDot(
      logicalSize: logicalSize,
      devicePixelRatio: devicePixelRatio,
      fillColor: status.color,
    );
    _cache[key] = bytes;
    return (bytes, 1 / devicePixelRatio);
  }

  Future<(Uint8List bytes, double iconSize)> currentLocationIcon({
    required double devicePixelRatio,
  }) async {
    final key = currentLocationCacheKey(devicePixelRatio);
    final cached = _cache[key];
    const logicalSize = 22.0;
    if (cached != null) return (cached, 1 / devicePixelRatio);

    final bytes = await _renderDot(
      logicalSize: logicalSize,
      devicePixelRatio: devicePixelRatio,
      fillColor: const Color(0xFF2F6FE4),
    );
    _cache[key] = bytes;
    return (bytes, 1 / devicePixelRatio);
  }

  Future<Uint8List> _renderDot({
    required double logicalSize,
    required double devicePixelRatio,
    required Color fillColor,
  }) async {
    final pixels = (logicalSize * devicePixelRatio).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(devicePixelRatio);

    final center = Offset(logicalSize / 2, logicalSize / 2);
    final radius = logicalSize * 0.32;
    canvas.drawCircle(
      center.translate(0, 1.5),
      radius + 3,
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawCircle(center, radius + 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius, Paint()..color = fillColor);

    final picture = recorder.endRecording();
    final image = await picture.toImage(pixels, pixels);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }
}
