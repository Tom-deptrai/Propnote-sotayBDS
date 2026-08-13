import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../map/map_constants.dart';
import '../../map/widgets/map_background_painter.dart';

/// Trả về toạ độ chuẩn hoá (0.0–1.0) trên canvas bản đồ mock, hoặc null nếu
/// người dùng huỷ.
Future<Offset?> showLocationPickerScreen(
  BuildContext context, {
  Offset? initial,
}) {
  return Navigator.push<Offset>(
    context,
    MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: initial)),
  );
}

class LocationPickerScreen extends StatefulWidget {
  final Offset? initial;

  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TransformationController _controller = TransformationController();
  Size _viewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = widget.initial ?? const Offset(0.40, 0.46);
      if (_viewportSize == Size.zero) return;
      const scale = 1.3;
      final tx = _viewportSize.width / 2 - mapCanvasSize.width * p.dx * scale;
      final ty = _viewportSize.height / 2 - mapCanvasSize.height * p.dy * scale;
      _controller.value = Matrix4(
        scale, 0, 0, 0,
        0, scale, 0, 0,
        0, 0, 1, 0,
        tx, ty, 0, 1,
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final inverse = Matrix4.tryInvert(_controller.value);
    if (inverse == null) return;
    final center = Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    final canvasPoint = MatrixUtils.transformPoint(inverse, center);
    final normalized = Offset(
      (canvasPoint.dx / mapCanvasSize.width).clamp(0.02, 0.98),
      (canvasPoint.dy / mapCanvasSize.height).clamp(0.02, 0.98),
    );
    Navigator.pop(context, normalized);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mapLand,
      appBar: AppBar(
        title: const Text('Chọn trên bản đồ'),
        backgroundColor: AppColors.mapLand,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _viewportSize = constraints.biggest;
                return ClipRect(
                  child: InteractiveViewer(
                    transformationController: _controller,
                    constrained: false,
                    minScale: 0.6,
                    maxScale: 2.6,
                    boundaryMargin: const EdgeInsets.all(400),
                    child: SizedBox(
                      width: mapCanvasSize.width,
                      height: mapCanvasSize.height,
                      child: const CustomPaint(
                        painter: MapBackgroundPainter(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 34),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.navy,
                  size: 44,
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text(
                        'Kéo bản đồ để đặt ghim vào đúng vị trí',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: ElevatedButton(
            onPressed: _confirm,
            child: const Text('Xác nhận vị trí'),
          ),
        ),
      ),
    );
  }
}
