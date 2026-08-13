import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property.dart';
import '../../models/property_status.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_messenger.dart';
import '../../utils/formatters.dart';
import '../../widgets/area_picker_sheet.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/mini_map_preview.dart';
import '../../widgets/status_badge.dart';
import '../add_property/add_property_screen.dart';
import 'widgets/photo_gallery.dart';

class PropertyDetailScreen extends StatelessWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  Future<void> _changeStatus(BuildContext context, Property property) async {
    final state = context.read<AppState>();
    final result = await showModalBottomSheet<PropertyStatus>(
      context: context,
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Đổi trạng thái', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            for (final s in PropertyStatus.values)
              ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                ),
                title: Text(s.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: s == property.status
                    ? const Icon(Icons.check_rounded, color: AppColors.navy)
                    : null,
                onTap: () => Navigator.pop(context, s),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null && result != property.status) {
      state.changeStatus(property.id, result);
      showAppSnackBar('Đã đổi trạng thái sang "${result.label}"');
    }
  }

  Future<void> _changeArea(BuildContext context, Property property) async {
    final state = context.read<AppState>();
    final result = await showAreaPickerSheet(
      context,
      selectedAreaId: property.areaId,
    );
    if (result != null && result != property.areaId) {
      state.moveToArea(property.id, result);
      showAppSnackBar('Đã chuyển khu vực sang "${state.areaName(result)}"');
    }
  }

  Future<void> _delete(BuildContext context, Property property) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xoá bất động sản?',
      message:
          '"${property.title}" sẽ được chuyển vào Thùng rác và có thể khôi phục sau.',
      confirmLabel: 'Xoá',
    );
    if (confirmed && context.mounted) {
      context.read<AppState>().deleteProperty(property.id);
      Navigator.pop(context);
      showAppSnackBar('Đã chuyển vào thùng rác');
    }
  }

  Future<void> _openMenu(BuildContext context, Property property) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.sync_alt_rounded),
              title: const Text('Đổi trạng thái'),
              onTap: () => Navigator.pop(context, 'status'),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('Chuyển khu vực'),
              onTap: () => Navigator.pop(context, 'area'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.statusSelling),
              title: const Text('Xoá', style: TextStyle(color: AppColors.statusSelling)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'status':
        _changeStatus(context, property);
        break;
      case 'area':
        _changeArea(context, property);
        break;
      case 'delete':
        _delete(context, property);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final property = state.propertyById(propertyId);

    if (property == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text('Bất động sản không còn tồn tại.')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            title: Text(
              property.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: _CircleIconButton(
                  icon: Icons.more_horiz_rounded,
                  onTap: () => _openMenu(context, property),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: PhotoGallery(photoSeeds: property.photoSeeds),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          formatPriceShort(property.price),
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(color: AppColors.navy),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: StatusBadge(status: property.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(property.address, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: [
                      _MetaChip(icon: Icons.straighten_rounded, label: formatArea(property.landArea)),
                      _MetaChip(
                        icon: Icons.location_on_outlined,
                        label: state.areaName(property.areaId),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Thông tin'),
                  _InfoTable(property: property),
                  if (property.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionTitle('Tags'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: property.tags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _SectionTitle('Ghi chú'),
                  Text(
                    property.notes.isEmpty ? 'Chưa có ghi chú.' : property.notes,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 14.5,
                          color: property.notes.isEmpty
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Vị trí'),
                  MiniMapPreview(
                    normalizedPosition: Offset(property.mapX, property.mapY),
                    height: 160,
                    pinColor: property.status.color,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => showAppSnackBar('Mở chỉ đường (demo)'),
                          icon: const Icon(Icons.directions_rounded, size: 20),
                          label: const Text('Chỉ đường'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddPropertyScreen(existing: property),
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Chỉnh sửa'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.32),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _InfoTable extends StatelessWidget {
  final Property property;

  const _InfoTable({required this.property});

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String)>[
      (Icons.category_outlined, 'Loại BĐS', property.propertyType),
      if (property.frontage != null)
        (Icons.straighten_outlined, 'Mặt tiền', '${property.frontage} m'),
      if (property.floors != null)
        (Icons.layers_outlined, 'Số tầng', '${property.floors} tầng'),
      if (property.surveyDate != null)
        (Icons.event_outlined, 'Ngày khảo sát', formatDate(property.surveyDate!)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(rows[i].$1, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].$3,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (i != rows.length - 1)
              const Divider(height: 1, indent: 14, endIndent: 14),
          ],
        ],
      ),
    );
  }
}
