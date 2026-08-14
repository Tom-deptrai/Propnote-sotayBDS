import 'package:flutter/material.dart';

import '../../../models/contact.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/confirm_dialog.dart';

/// Danh sách liên hệ gắn với BĐS — thêm / sửa / xoá, lưu bằng in-memory
/// state của form (mock, chưa gắn danh bạ thật).
class ContactsEditor extends StatelessWidget {
  final List<Contact> contacts;
  final ValueChanged<List<Contact>> onChanged;

  const ContactsEditor({
    super.key,
    required this.contacts,
    required this.onChanged,
  });

  Future<void> _editContact(BuildContext context, {Contact? existing}) async {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final result = await showDialog<Contact>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Thêm liên hệ' : 'Sửa liên hệ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Tên / nhãn (VD: Chủ nhà)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'Số điện thoại'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () {
              final label = labelController.text.trim();
              final phone = phoneController.text.trim();
              if (label.isEmpty || phone.isEmpty) {
                Navigator.pop(context);
                return;
              }
              Navigator.pop(
                context,
                Contact(
                  id:
                      existing?.id ??
                      'contact_${DateTime.now().millisecondsSinceEpoch}',
                  label: label,
                  phone: phone,
                ),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final updated = [...contacts];
    if (existing == null) {
      updated.add(result);
    } else {
      final index = updated.indexWhere((c) => c.id == existing.id);
      if (index != -1) updated[index] = result;
    }
    onChanged(updated);
  }

  Future<void> _deleteContact(BuildContext context, Contact contact) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xoá liên hệ?',
      message: '"${contact.label}" sẽ bị xoá khỏi danh sách liên hệ.',
    );
    if (confirmed) {
      onChanged(contacts.where((c) => c.id != contact.id).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final contact in contacts) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        contact.phone,
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
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => _editContact(context, existing: contact),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.statusSelling,
                  ),
                  onPressed: () => _deleteContact(context, contact),
                ),
              ],
            ),
          ),
        ],
        OutlinedButton.icon(
          onPressed: () => _editContact(context),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Thêm số điện thoại'),
        ),
      ],
    );
  }
}
