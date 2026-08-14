import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/services/app_runtime.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_messenger.dart';
import '../../widgets/confirm_dialog.dart';
import 'area_management_screen.dart';
import 'static_info_screen.dart';
import 'trash_screen.dart';
import 'widgets/settings_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _createBackup(BuildContext context) async {
    final runtime = context.read<AppRuntime?>();
    if (runtime == null) return;
    showAppSnackBar('Đang tạo bản sao lưu...');
    try {
      final backup = await runtime.backupService.createBackup();
      if (!context.mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(backup.path, mimeType: 'application/zip')],
          subject: 'Sao lưu dữ liệu PropNote',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      showAppSnackBar('Không thể tạo bản sao lưu');
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final runtime = context.read<AppRuntime?>();
    final state = context.read<AppState>();
    if (runtime == null) return;
    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: 'Chọn tệp sao lưu PropNote',
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
      final path = picked?.path;
      if (path == null || !context.mounted) return;
      await runtime.backupService.validateBackup(path);
      if (!context.mounted) return;
      final confirmed = await showConfirmDialog(
        context,
        title: 'Khôi phục dữ liệu?',
        message:
            'Dữ liệu hiện tại sẽ được thay bằng nội dung trong bản sao lưu. '
            'PropNote sẽ giữ bản phục hồi cho tới khi quá trình hoàn tất.',
        confirmLabel: 'Khôi phục',
      );
      if (!confirmed) return;
      showAppSnackBar('Đang khôi phục dữ liệu...');
      await runtime.backupService.restoreBackup(path);
      await state.reload();
      await runtime.reconcileMedia();
      showAppSnackBar('Đã khôi phục dữ liệu');
    } catch (error) {
      showAppSnackBar(error.toString());
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final runtime = context.read<AppRuntime?>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text('Cài đặt', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 16),
            const _ProCard(),
            const SizedBox(height: 18),
            SettingsSection(
              title: 'Dữ liệu',
              children: [
                SettingsTile(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Sao lưu dữ liệu',
                  onTap: () => _createBackup(context),
                ),
                SettingsTile(
                  icon: Icons.cloud_download_outlined,
                  label: 'Khôi phục dữ liệu',
                  onTap: () => _restoreBackup(context),
                ),
                SettingsTile(
                  icon: Icons.pie_chart_outline_rounded,
                  label: 'Dung lượng đang sử dụng',
                  trailingWidget: runtime == null
                      ? const Text('—')
                      : FutureBuilder<int>(
                          future: runtime.directories.totalSize(),
                          builder: (context, snapshot) => Text(
                            snapshot.hasData
                                ? _formatBytes(snapshot.data!)
                                : 'Đang tính...',
                          ),
                        ),
                ),
                SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Thùng rác',
                  trailingText: state.trash.isEmpty
                      ? null
                      : '${state.trash.length}',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrashScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SettingsSection(
              title: 'Quản lý',
              children: [
                SettingsTile(
                  icon: Icons.map_outlined,
                  label: 'Quản lý khu vực',
                  trailingText: '${state.areas.length}',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AreaManagementScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SettingsSection(
              title: 'Ứng dụng',
              children: [
                const SettingsTile(
                  icon: Icons.info_outline_rounded,
                  label: 'Phiên bản',
                  trailingText: '1.0.0',
                ),
                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Chính sách riêng tư',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StaticInfoScreen(
                        title: 'Chính sách riêng tư',
                        body: kPrivacyPolicyText,
                      ),
                    ),
                  ),
                ),
                SettingsTile(
                  icon: Icons.apartment_rounded,
                  label: 'Giới thiệu PropNote',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StaticInfoScreen(
                        title: 'Giới thiệu PropNote',
                        body: kAboutText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'PropNote Pro',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '199.000đ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ năm',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Không giới hạn số lượng bất động sản, sao lưu đám mây, và nhiều hơn nữa.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.navy,
              ),
              onPressed: () => showAppSnackBar('Sắp ra mắt'),
              child: const Text('Nâng cấp lên Pro'),
            ),
          ),
        ],
      ),
    );
  }
}
