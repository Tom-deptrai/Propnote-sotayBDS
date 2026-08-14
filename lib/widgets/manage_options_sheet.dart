import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/app_messenger.dart';
import 'confirm_dialog.dart';

/// Bottom sheet quản lý một danh sách tuỳ chọn dạng chuỗi (Loại BĐS, Tags...)
/// — cho phép thêm / sửa / xoá, không hard-code như dữ liệu bất biến.
Future<void> showManageOptionsSheet(
  BuildContext context, {
  required String title,
  required String emptyHint,
  required List<String> Function(AppState) optionsOf,
  required int Function(AppState, String) usageCountOf,
  required void Function(AppState, String) onAdd,
  required void Function(AppState, String, String) onRename,
  required bool Function(AppState, String) onDelete,
  required void Function(AppState, int, int) onReorder,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ManageOptionsSheet(
      title: title,
      emptyHint: emptyHint,
      optionsOf: optionsOf,
      usageCountOf: usageCountOf,
      onAdd: onAdd,
      onRename: onRename,
      onDelete: onDelete,
      onReorder: onReorder,
    ),
  );
}

class _ManageOptionsSheet extends StatelessWidget {
  final String title;
  final String emptyHint;
  final List<String> Function(AppState) optionsOf;
  final int Function(AppState, String) usageCountOf;
  final void Function(AppState, String) onAdd;
  final void Function(AppState, String, String) onRename;
  final bool Function(AppState, String) onDelete;
  final void Function(AppState, int, int) onReorder;

  const _ManageOptionsSheet({
    required this.title,
    required this.emptyHint,
    required this.optionsOf,
    required this.usageCountOf,
    required this.onAdd,
    required this.onRename,
    required this.onDelete,
    required this.onReorder,
  });

  Future<void> _add(BuildContext context, AppState state) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title mới'),
        content: TextField(controller: controller, autofocus: true),
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
    if (name != null && name.isNotEmpty) onAdd(state, name);
  }

  Future<void> _rename(BuildContext context, AppState state, String old) async {
    final controller = TextEditingController(text: old);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đổi tên "$old"'),
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
    if (name != null && name.isNotEmpty && name != old) {
      onRename(state, old, name);
    }
  }

  Future<void> _delete(
    BuildContext context,
    AppState state,
    String name,
  ) async {
    final count = usageCountOf(state, name);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xoá "$name"?',
      message: count > 0
          ? 'Đang được dùng ở $count bất động sản. Xoá sẽ gỡ khỏi các mục đó.'
          : 'Mục này sẽ bị xoá khỏi danh sách.',
    );
    if (!confirmed) return;
    final success = onDelete(state, name);
    if (!success && context.mounted) {
      showAppSnackBar('Không thể xoá "$name"');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final options = optionsOf(state);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                TextButton.icon(
                  onPressed: () => _add(context, state),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Thêm'),
                ),
              ],
            ),
            if (options.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 6),
                child: Text(
                  'Kéo để sắp xếp thứ tự hiển thị',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (options.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  emptyHint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              SizedBox(
                height: (MediaQuery.sizeOf(context).height * 0.5).clamp(
                  180.0,
                  340.0,
                ),
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: options.length,
                  onReorderItem: (oldIndex, newIndex) =>
                      onReorder(state, oldIndex, newIndex),
                  itemBuilder: (context, i) {
                    final name = options[i];
                    return Container(
                      key: ValueKey(name),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: i,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                size: 20,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 19,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => _rename(context, state, name),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 19,
                              color: AppColors.statusSelling,
                            ),
                            onPressed: () => _delete(context, state, name),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
