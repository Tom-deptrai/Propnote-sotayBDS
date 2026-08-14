import 'dart:async';

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
  required FutureOr<void> Function(AppState, String) onAdd,
  required FutureOr<void> Function(AppState, String, String) onRename,
  required FutureOr<bool> Function(AppState, String) onDelete,
  bool canDeleteWhenUsed = true,
  required FutureOr<void> Function(AppState, int, int) onReorder,
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
      canDeleteWhenUsed: canDeleteWhenUsed,
      onReorder: onReorder,
    ),
  );
}

class _ManageOptionsSheet extends StatelessWidget {
  final String title;
  final String emptyHint;
  final List<String> Function(AppState) optionsOf;
  final int Function(AppState, String) usageCountOf;
  final FutureOr<void> Function(AppState, String) onAdd;
  final FutureOr<void> Function(AppState, String, String) onRename;
  final FutureOr<bool> Function(AppState, String) onDelete;
  final bool canDeleteWhenUsed;
  final FutureOr<void> Function(AppState, int, int) onReorder;

  const _ManageOptionsSheet({
    required this.title,
    required this.emptyHint,
    required this.optionsOf,
    required this.usageCountOf,
    required this.onAdd,
    required this.onRename,
    required this.onDelete,
    required this.canDeleteWhenUsed,
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
    if (name != null && name.isNotEmpty) {
      try {
        await onAdd(state, name);
      } catch (_) {
        showAppSnackBar('Không thể thêm "$name"');
      }
    }
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
      try {
        await onRename(state, old, name);
      } catch (_) {
        showAppSnackBar('Không thể đổi tên "$old"');
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    AppState state,
    String name,
  ) async {
    final count = usageCountOf(state, name);
    if (count > 0 && !canDeleteWhenUsed) {
      showAppSnackBar(
        'Không thể xoá "$name" vì đang được dùng ở $count bất động sản',
      );
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xoá "$name"?',
      message: count > 0
          ? 'Đang được dùng ở $count bất động sản. Xoá sẽ gỡ khỏi các mục đó.'
          : 'Mục này sẽ bị xoá khỏi danh sách.',
    );
    if (!confirmed) return;
    bool success;
    try {
      success = await onDelete(state, name);
    } catch (_) {
      success = false;
    }
    if (!success && context.mounted) {
      showAppSnackBar('Không thể xoá "$name"');
    }
  }

  Future<void> _reorder(AppState state, int oldIndex, int newIndex) async {
    try {
      await onReorder(state, oldIndex, newIndex);
    } catch (_) {
      showAppSnackBar('Không thể lưu thứ tự mới');
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
                      unawaited(_reorder(state, oldIndex, newIndex)),
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
