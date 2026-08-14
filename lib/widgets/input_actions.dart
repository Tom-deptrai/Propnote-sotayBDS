import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../theme/app_colors.dart';

Future<String?> showImageSourceActionSheet(
  BuildContext context, {
  String title = 'Thêm ảnh',
  bool includeFiles = false,
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
        if (includeFiles)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'file'),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.insert_drive_file_outlined, size: 20),
                SizedBox(width: 8),
                Text('Chọn tệp từ Files'),
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

Future<String?> showVoiceInput(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    isScrollControlled: true,
    builder: (_) => const _VoiceInputSheet(),
  );
}

class _VoiceInputSheet extends StatefulWidget {
  const _VoiceInputSheet();

  @override
  State<_VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<_VoiceInputSheet>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  String _words = '';
  String _status = 'Đang chuẩn bị nhận giọng nói...';
  bool _available = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final available = await _speech.initialize(
        onError: (error) {
          if (mounted) {
            setState(() => _status = 'Không thể nhận giọng nói');
          }
        },
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'notListening' && _words.isNotEmpty) {
            setState(() => _status = 'Đã nhận xong');
          }
        },
      );
      if (!mounted) return;
      if (!available) {
        setState(() => _status = 'Thiết bị không hỗ trợ nhận giọng nói');
        return;
      }
      final locales = await _speech.locales();
      final vietnamese = locales
          .where((locale) => locale.localeId.toLowerCase().startsWith('vi'))
          .firstOrNull;
      setState(() {
        _available = true;
        _status = 'Đang nghe...';
      });
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _words = result.recognizedWords;
            _status = result.finalResult ? 'Đã nhận xong' : 'Đang nghe...';
          });
        },
        listenOptions: SpeechListenOptions(
          localeId: vietnamese?.localeId,
          listenFor: const Duration(minutes: 1),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Không thể truy cập microphone');
      }
    }
  }

  Future<void> _finish() async {
    await _speech.stop();
    if (mounted) Navigator.pop(context, _words.trim().nullIfEmpty);
  }

  @override
  void dispose() {
    _speech.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
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
                  final scale = _available ? 1.0 + _pulse.value * 0.18 : 1.0;
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
              Text(
                _status,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_words.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _words,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _speech.cancel();
                        Navigator.pop(context);
                      },
                      child: const Text('Huỷ'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _words.trim().isEmpty ? null : _finish,
                      child: const Text('Dùng nội dung'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
