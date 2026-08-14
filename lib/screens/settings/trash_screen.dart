import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_messenger.dart';
import '../../utils/formatters.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/property_photo.dart';
import '../../widgets/status_badge.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final trash = state.trash;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thùng rác'),
        actions: [
          if (trash.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Xoá vĩnh viễn tất cả?',
                  message:
                      'Toàn bộ ${trash.length} bất động sản trong thùng rác sẽ bị xoá vĩnh viễn.',
                  confirmLabel: 'Xoá tất cả',
                );
                if (confirmed && context.mounted) {
                  try {
                    await context.read<AppState>().emptyTrash();
                    showAppSnackBar('Đã xoá vĩnh viễn tất cả');
                  } catch (_) {
                    showAppSnackBar('Không thể xoá thùng rác');
                  }
                }
              },
              child: const Text('Xoá tất cả'),
            ),
        ],
      ),
      body: trash.isEmpty
          ? const _EmptyTrash()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: trash.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = trash[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: PropertyPhoto(
                              seed: p.photoSeeds.first,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${formatPriceShort(p.price)} · ${formatArea(p.landArea)}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(status: p.status, dense: true),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  await context
                                      .read<AppState>()
                                      .restoreFromTrash(p.id);
                                  showAppSnackBar('Đã khôi phục "${p.title}"');
                                } catch (_) {
                                  showAppSnackBar('Không thể khôi phục');
                                }
                              },
                              icon: const Icon(Icons.restore_rounded, size: 18),
                              label: const Text('Khôi phục'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.statusSelling,
                                side: const BorderSide(
                                  color: AppColors.statusSellingBg,
                                ),
                              ),
                              onPressed: () async {
                                final confirmed = await showConfirmDialog(
                                  context,
                                  title: 'Xoá vĩnh viễn?',
                                  message:
                                      '"${p.title}" sẽ bị xoá vĩnh viễn và không thể khôi phục.',
                                );
                                if (confirmed && context.mounted) {
                                  try {
                                    await context
                                        .read<AppState>()
                                        .deletePermanently(p.id);
                                    showAppSnackBar('Đã xoá vĩnh viễn');
                                  } catch (_) {
                                    showAppSnackBar('Không thể xoá vĩnh viễn');
                                  }
                                }
                              },
                              icon: const Icon(
                                Icons.delete_forever_outlined,
                                size: 18,
                              ),
                              label: const Text('Xoá vĩnh viễn'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyTrash extends StatelessWidget {
  const _EmptyTrash();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.textTertiary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Thùng rác trống',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Bất động sản đã xoá sẽ xuất hiện ở đây.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
