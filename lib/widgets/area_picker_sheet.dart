import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';

/// Trả về id khu vực được chọn, hoặc null nếu người dùng huỷ.
Future<String?> showAreaPickerSheet(
  BuildContext context, {
  String? selectedAreaId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AreaPickerSheet(selectedAreaId: selectedAreaId),
  );
}

class _AreaPickerSheet extends StatefulWidget {
  final String? selectedAreaId;

  const _AreaPickerSheet({this.selectedAreaId});

  @override
  State<_AreaPickerSheet> createState() => _AreaPickerSheetState();
}

class _AreaPickerSheetState extends State<_AreaPickerSheet> {
  String _query = '';

  Future<void> _createArea(BuildContext context) async {
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
      final state = context.read<AppState>();
      state.addArea(name);
      final created = state.areas.last;
      if (context.mounted) Navigator.pop(context, created.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final areas = state.areas
        .where((a) => a.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

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
            const SizedBox(height: 18),
            Text('Chọn khu vực', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Tìm khu vực...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: areas.length,
                itemBuilder: (context, i) {
                  final area = areas[i];
                  final selected = area.id == widget.selectedAreaId;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      area.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.navy)
                        : null,
                    onTap: () => Navigator.pop(context, area.id),
                  );
                },
              ),
            ),
            const Divider(height: 20),
            InkWell(
              onTap: () => _createArea(context),
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: AppColors.navy),
                    SizedBox(width: 10),
                    Text(
                      'Thêm khu vực mới',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
