import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bottom sheet chọn nguồn ảnh — mock, không gọi camera/thư viện thật.
/// Trả về 'camera', 'gallery', hoặc null nếu huỷ.
Future<String?> showImageSourceActionSheet(
  BuildContext context, {
  String title = 'Thêm ảnh',
}) {
  return showCupertinoModalPopup<String>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: Text(title),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, 'camera'),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined, size: 20),
              SizedBox(width: 8),
              Text('Chụp ảnh'),
            ],
          ),
        ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, 'gallery'),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined, size: 20),
              SizedBox(width: 8),
              Text('Chọn từ thư viện'),
            ],
          ),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        isDestructiveAction: true,
        child: const Text('Huỷ'),
      ),
    ),
  );
}

/// Mock ghi âm giọng nói — hiện overlay "Đang nghe..." trong chốc lát rồi
/// trả về [demoText] để chèn vào field. Không tích hợp speech-to-text thật.
Future<String?> showVoiceInputMock(
  BuildContext context, {
  required String demoText,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (context) => _VoiceInputSheet(demoText: demoText),
  );
}

class _VoiceInputSheet extends StatefulWidget {
  final String demoText;

  const _VoiceInputSheet({required this.demoText});

  @override
  State<_VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<_VoiceInputSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) Navigator.pop(context, widget.demoText);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final scale = 1.0 + _pulse.value * 0.18;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.navy.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      child!,
                    ],
                  );
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đang nghe...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Nói nội dung bạn muốn nhập (demo)',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
