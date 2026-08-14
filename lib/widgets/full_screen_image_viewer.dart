import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'property_photo.dart';

/// Trình xem ảnh toàn màn hình với hỗ trợ vuốt trái/phải, zoom/pan, double-tap zoom và aspect ratio chuẩn.
class FullScreenImageViewer extends StatefulWidget {
  final List<String?> filePaths;
  final List<int> seeds;
  final int initialIndex;
  final String? title;

  const FullScreenImageViewer({
    super.key,
    required this.filePaths,
    this.seeds = const [],
    this.initialIndex = 0,
    this.title,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String?> filePaths,
    List<int>? seeds,
    int initialIndex = 0,
    String? title,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          filePaths: filePaths,
          seeds: seeds ?? const [],
          initialIndex: initialIndex,
          title: title,
        ),
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late final PageController _controller;
  late int _currentIndex;
  bool _showControls = true;
  bool _isCurrentPageZoomed = false;

  @override
  void initState() {
    super.initState();
    final count = _itemCount;
    _currentIndex = (widget.initialIndex >= 0 && widget.initialIndex < count)
        ? widget.initialIndex
        : 0;
    _controller = PageController(initialPage: _currentIndex);
  }

  int get _itemCount {
    if (widget.filePaths.isNotEmpty) return widget.filePaths.length;
    if (widget.seeds.isNotEmpty) return widget.seeds.length;
    return 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    final count = _itemCount;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: count,
              physics: _isCurrentPageZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _isCurrentPageZoomed = false;
                });
              },
              itemBuilder: (context, index) {
                final filePath = index < widget.filePaths.length
                    ? widget.filePaths[index]
                    : null;
                final seed = index < widget.seeds.length
                    ? widget.seeds[index]
                    : (widget.seeds.isNotEmpty ? widget.seeds[0] : 0);

                Widget imageWidget;
                if (filePath != null && File(filePath).existsSync()) {
                  imageWidget = Image.file(
                    File(filePath),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => PropertyPhotoView(seed: seed),
                  );
                } else {
                  imageWidget = PropertyPhotoView(
                    filePath: filePath,
                    seed: seed,
                  );
                }

                return _ZoomablePhotoPage(
                  onTap: _toggleControls,
                  onZoomChanged: (zoomed) {
                    if (_isCurrentPageZoomed != zoomed) {
                      setState(() => _isCurrentPageZoomed = zoomed);
                    }
                  },
                  child: imageWidget,
                );
              },
            ),
            // Header controls overlay
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            tooltip: 'Đóng',
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          if (widget.title != null)
                            Expanded(
                              child: Text(
                                widget.title!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else
                            const Spacer(),
                          if (count > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${_currentIndex + 1} / $count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomablePhotoPage extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onZoomChanged;

  const _ZoomablePhotoPage({
    required this.child,
    this.onTap,
    this.onZoomChanged,
  });

  @override
  State<_ZoomablePhotoPage> createState() => _ZoomablePhotoPageState();
}

class _ZoomablePhotoPageState extends State<_ZoomablePhotoPage> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _isZoomed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_isZoomed) {
      _controller.value = Matrix4.identity();
      _setZoomed(false);
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      final x = -position.dx * (2.5 - 1);
      final y = -position.dy * (2.5 - 1);
      _controller.value = Matrix4.identity()
        ..translateByDouble(x, y, 0.0, 1.0)
        ..scaleByDouble(2.5, 2.5, 1.0, 1.0);
      _setZoomed(true);
    }
  }

  void _setZoomed(bool zoomed) {
    if (_isZoomed != zoomed) {
      setState(() => _isZoomed = zoomed);
      widget.onZoomChanged?.call(zoomed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1.0,
        maxScale: 4.0,
        onInteractionEnd: (details) {
          final scale = _controller.value.getMaxScaleOnAxis();
          if (scale <= 1.01) {
            _controller.value = Matrix4.identity();
            _setZoomed(false);
          } else {
            _setZoomed(true);
          }
        },
        child: Center(child: widget.child),
      ),
    );
  }
}
