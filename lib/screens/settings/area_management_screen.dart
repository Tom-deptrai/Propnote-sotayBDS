import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_messenger.dart';
import '../../widgets/confirm_dialog.dart';

class AreaManagementScreen extends StatelessWidget {
  const AreaManagementScreen({super.key});

  Future<void> _addArea(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khu vực mới'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'VD: Long Biên'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      context.read<AppState>().addArea(name);
      showAppSnackBar('Đã thêm khu vực "$name"');
    }
  }

  Future<void> _renameArea(
    BuildContext context,
    String id,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên khu vực'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      context.read<AppState>().renameArea(id, name);
    }
  }

  Future<void> _deleteArea(
    BuildContext context,
    String id,
    String name,
    int count,
  ) async {
    if (count > 0) {
      showAppSnackBar('Không thể xoá "$name" vì còn $count bất động sản');
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xoá khu vực?',
      message: '"$name" sẽ bị xoá khỏi danh sách khu vực.',
    );
    if (confirmed && context.mounted) {
      context.read<AppState>().deleteArea(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final areas = state.areas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý khu vực'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _addArea(context),
          ),
        ],
      ),
      body: areas.isEmpty
          ? const Center(child: Text('Chưa có khu vực nào'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: areas.length,
              onReorderItem: (oldIndex, newIndex) {
                context.read<AppState>().reorderAreas(oldIndex, newIndex);
              },
              itemBuilder: (context, i) {
                final area = areas[i];
                final count = state.propertyCountInArea(area.id);
                return Container(
                  key: ValueKey(area.id),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.drag_indicator_rounded,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              area.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$count bất động sản',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            _renameArea(context, area.id, area.name),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.statusSelling,
                        ),
                        onPressed: () =>
                            _deleteArea(context, area.id, area.name, count),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
