import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_messenger.dart';
import 'area_management_screen.dart';
import 'static_info_screen.dart';
import 'trash_screen.dart';
import 'widgets/settings_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

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
                  onTap: () => showAppSnackBar('Tính năng sẽ có trong bản đầy đủ'),
                ),
                SettingsTile(
                  icon: Icons.cloud_download_outlined,
                  label: 'Khôi phục dữ liệu',
                  onTap: () => showAppSnackBar('Tính năng sẽ có trong bản đầy đủ'),
                ),
                const SettingsTile(
                  icon: Icons.pie_chart_outline_rounded,
                  label: 'Dung lượng đang sử dụng',
                  trailingText: '8,2 MB',
                ),
                SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Thùng rác',
                  trailingText: state.trash.isEmpty ? null : '${state.trash.length}',
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
                    MaterialPageRoute(builder: (_) => const AreaManagementScreen()),
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
                  trailingText: '1.0.0 (UI Prototype)',
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
                child: const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'PropNote Pro',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
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
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
              ),
              const SizedBox(width: 4),
              Text(
                '/ năm',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Không giới hạn số lượng bất động sản, sao lưu đám mây, và nhiều hơn nữa.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5, height: 1.4),
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
