import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';
import '../../utils/app_messenger.dart';

const String kSupportEmail = 'Timeforwork789@icloud.com';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _sendSupportEmail(BuildContext context) async {
    String subject = 'Hỗ trợ PropNote';
    String body = '';
    try {
      final info = await PackageInfo.fromPlatform();
      body = 'Phiên bản PropNote: ${info.version} (build ${info.buildNumber})\n\n';
    } catch (_) {
      // Không lấy được version — vẫn gửi mail được, chỉ thiếu dòng này.
    }
    final uri = Uri(
      scheme: 'mailto',
      path: kSupportEmail,
      query: Uri(
        queryParameters: {'subject': subject, 'body': body},
      ).query,
    );
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        showAppSnackBar('Không thể mở ứng dụng email — vui lòng copy email bên trên');
      }
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar('Không thể mở ứng dụng email — vui lòng copy email bên trên');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hỗ trợ & liên hệ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn cần hỗ trợ về PropNote?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gửi email cho chúng tôi nếu bạn gặp lỗi, cần hỗ trợ sử dụng, '
              'hoặc có góp ý cho PropNote.',
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    size: 20,
                    color: AppColors.navy,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectableText(
                      kSupportEmail,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _sendSupportEmail(context),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Gửi email hỗ trợ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
