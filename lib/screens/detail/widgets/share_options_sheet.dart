import 'package:flutter/material.dart';

import '../../../models/property.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';

class _ShareItem {
  final String key;
  final String label;
  final bool defaultSelected;
  final bool sensitive;

  const _ShareItem(this.key, this.label, this.defaultSelected, {this.sensitive = false});
}

const List<_ShareItem> _kShareItems = [
  _ShareItem('photos', 'Ảnh BĐS', true),
  _ShareItem('price', 'Giá', true),
  _ShareItem('area', 'Diện tích', true),
  _ShareItem('address', 'Địa chỉ / khu vực', true),
  _ShareItem('type', 'Loại BĐS', true),
  _ShareItem('tags', 'Tags', true),
  _ShareItem('notes', 'Ghi chú', false, sensitive: true),
  _ShareItem('exactLocation', 'Vị trí chính xác', false, sensitive: true),
  _ShareItem('documents', 'Tài liệu / hình bổ sung', false, sensitive: true),
  _ShareItem('contacts', 'Số điện thoại liên hệ', false, sensitive: true),
];

/// Bottom sheet chọn nội dung muốn chia sẻ — các mục nhạy cảm (ghi chú, vị
/// trí chính xác, tài liệu, số điện thoại) mặc định KHÔNG được chọn.
Future<void> showShareOptionsSheet(
  BuildContext context, {
  required Property property,
  required String areaName,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ShareOptionsSheet(property: property, areaName: areaName),
  );
}

class _ShareOptionsSheet extends StatefulWidget {
  final Property property;
  final String areaName;

  const _ShareOptionsSheet({required this.property, required this.areaName});

  @override
  State<_ShareOptionsSheet> createState() => _ShareOptionsSheetState();
}

class _ShareOptionsSheetState extends State<_ShareOptionsSheet> {
  late final Map<String, bool> _selected = {
    for (final item in _kShareItems) item.key: item.defaultSelected,
  };

  void _continue() {
    Navigator.pop(context);
    _showPreview(context, widget.property, widget.areaName, _selected);
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Chọn thông tin muốn chia sẻ', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Thông tin nhạy cảm mặc định không được chọn.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _kShareItems.length,
                itemBuilder: (context, i) {
                  final item = _kShareItems[i];
                  return CheckboxListTile(
                    value: _selected[item.key],
                    onChanged: (v) => setState(() => _selected[item.key] = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: AppColors.navy,
                    title: Row(
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        if (item.sensitive) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.shield_outlined, size: 14, color: AppColors.textTertiary),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _continue,
                child: const Text('Tiếp tục chia sẻ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showPreview(
  BuildContext context,
  Property property,
  String areaName,
  Map<String, bool> selected,
) {
  final lines = <String>[];
  if (selected['photos'] == true) {
    lines.add('📷 Kèm ${property.photoSeeds.length} ảnh BĐS');
  }
  if (selected['price'] == true) lines.add('Giá: ${formatPriceShort(property.price)}');
  if (selected['area'] == true) lines.add('Diện tích: ${formatArea(property.landArea)}');
  if (selected['address'] == true) {
    lines.add('Địa chỉ: ${property.address} · $areaName');
  }
  if (selected['type'] == true) lines.add('Loại BĐS: ${property.propertyType}');
  if (selected['tags'] == true && property.tags.isNotEmpty) {
    lines.add('Tags: ${property.tags.join(', ')}');
  }
  if (selected['notes'] == true && property.notes.isNotEmpty) {
    lines.add('Ghi chú: ${property.notes}');
  }
  if (selected['exactLocation'] == true) {
    lines.add(
      'Vị trí chính xác: ${property.mapX.toStringAsFixed(4)}, ${property.mapY.toStringAsFixed(4)}',
    );
  }
  if (selected['documents'] == true && property.documentSeeds.isNotEmpty) {
    lines.add('Tài liệu: ${property.documentSeeds.length} tệp đính kèm');
  }
  if (selected['contacts'] == true && property.contacts.isNotEmpty) {
    for (final c in property.contacts) {
      lines.add('${c.label}: ${c.phone}');
    }
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Xem trước — ${property.title}'),
      content: SingleChildScrollView(
        child: Text(
          lines.isEmpty ? 'Chưa chọn nội dung nào để chia sẻ.' : lines.join('\n'),
          style: const TextStyle(fontSize: 13.5, height: 1.6),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã chia sẻ (demo)')),
            );
          },
          child: const Text('Chia sẻ'),
        ),
      ],
    ),
  );
}
