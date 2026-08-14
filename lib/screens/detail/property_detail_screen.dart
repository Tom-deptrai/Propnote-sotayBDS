import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/app_runtime.dart';
import '../../models/geo_point.dart';
import '../../models/property.dart';
import '../../models/property_status.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_messenger.dart';
import '../../utils/formatters.dart';
import '../../widgets/area_picker_sheet.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/document_photo.dart';
import '../../widgets/media_path_scope.dart';
import '../../widgets/mini_map_preview.dart';
import '../../widgets/status_badge.dart';
import '../add_property/add_property_screen.dart';
import 'widgets/photo_gallery.dart';
import 'widgets/share_options_sheet.dart';

class PropertyDetailScreen extends StatelessWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  Future<void> _callPhone(BuildContext context, String phone) async {
    try {
      await context.read<AppRuntime?>()?.platformActions.callPhone(phone);
    } catch (_) {
      showAppSnackBar('Không thể mở trình gọi điện');
    }
  }

  Future<void> _openDirections(BuildContext context, GeoPoint location) async {
    try {
      await context.read<AppRuntime?>()?.platformActions.openDirections(
        location,
      );
    } catch (_) {
      showAppSnackBar('Không thể mở chỉ đường');
    }
  }

  Future<void> _openDocument(BuildContext context, String relativePath) async {
    final runtime = context.read<AppRuntime?>();
    if (runtime == null) return;
    try {
      await runtime.platformActions.openFile(
        runtime.directories.resolve(relativePath),
      );
    } catch (_) {
      showAppSnackBar('Không thể mở tài liệu');
    }
  }

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
                child: Text(
                  'Đổi trạng thái',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            for (final s in PropertyStatus.values)
              ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: s.color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  s.label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
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
      try {
        await state.changeStatus(property.id, result);
        showAppSnackBar('Đã đổi trạng thái sang "${result.label}"');
      } catch (_) {
        showAppSnackBar('Không thể đổi trạng thái');
      }
    }
  }

  Future<void> _changeArea(BuildContext context, Property property) async {
    final state = context.read<AppState>();
    final result = await showAreaPickerSheet(
      context,
      selectedAreaId: property.areaId,
    );
    if (result != null && result != property.areaId) {
      try {
        await state.moveToArea(property.id, result);
        showAppSnackBar('Đã chuyển khu vực sang "${state.areaName(result)}"');
      } catch (_) {
        showAppSnackBar('Không thể chuyển khu vực');
      }
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
      try {
        await context.read<AppState>().deleteProperty(property.id);
        if (!context.mounted) return;
        Navigator.pop(context);
        showAppSnackBar('Đã chuyển vào thùng rác');
      } catch (_) {
        showAppSnackBar('Không thể chuyển vào thùng rác');
      }
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
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.statusSelling,
              ),
              title: const Text(
                'Xoá',
                style: TextStyle(color: AppColors.statusSelling),
              ),
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
        await _changeStatus(context, property);
        break;
      case 'area':
        await _changeArea(context, property);
        break;
      case 'delete':
        await _delete(context, property);
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
    final propertyLocation =
        property.location ??
        GeoPoint.fromLegacyNormalized(property.mapX, property.mapY);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
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
              background: PhotoGallery(
                photos: property.photos,
                photoSeeds: property.photoSeeds,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                  const SizedBox(height: 6),
                  Text(
                    property.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    property.address,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 18,
                    runSpacing: 6,
                    children: [
                      _MetaChip(
                        icon: Icons.straighten_rounded,
                        label: formatArea(property.landArea),
                      ),
                      _MetaChip(
                        icon: Icons.location_on_outlined,
                        label: state.areaName(property.areaId),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle('Thông tin'),
                  _InfoTable(property: property),
                  if (property.tags.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const _SectionTitle('Tags'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: property.tags
                          .map(
                            (t) => Container(
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
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const _SectionTitle('Ghi chú'),
                  Text(
                    property.notes.isEmpty
                        ? 'Chưa có ghi chú.'
                        : property.notes,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 14.5,
                      color: property.notes.isEmpty
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle('Vị trí'),
                  MiniMapPreview(
                    location: propertyLocation,
                    useGoogleMaps:
                        context.read<AppRuntime?>()?.googleMapsConfigured ==
                        true,
                    height: 150,
                    pinColor: property.status.color,
                  ),
                  if (property.documents.isNotEmpty ||
                      property.documentSeeds.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const _SectionTitle('Tài liệu / Hình bổ sung'),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: property.documents.isNotEmpty
                          ? property.documents.length
                          : property.documentSeeds.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemBuilder: (context, i) {
                        final document = property.documents.isEmpty
                            ? null
                            : property.documents[i];
                        return InkWell(
                          onTap: document == null
                              ? null
                              : () => _openDocument(
                                  context,
                                  document.relativePath,
                                ),
                          borderRadius: BorderRadius.circular(10),
                          child: DocumentPhotoView(
                            filePath: MediaPathScope.resolve(
                              context,
                              document?.thumbnailRelativePath ??
                                  document?.relativePath,
                            ),
                            mimeType: document?.mimeType,
                            seed: property.documentSeeds.isEmpty
                                ? 0
                                : property.documentSeeds[i %
                                      property.documentSeeds.length],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      },
                    ),
                  ],
                  if (property.contacts.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const _SectionTitle('Liên hệ'),
                    for (final c in property.contacts)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
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
                                    c.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    c.phone,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => _callPhone(context, c.phone),
                              customBorder: const CircleBorder(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.navy,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.call_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: property.location == null
                              ? null
                              : () => _openDirections(
                                  context,
                                  property.location!,
                                ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 14,
                            ),
                          ),
                          child: const Icon(Icons.directions_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => showShareOptionsSheet(
                            context,
                            property: property,
                            areaName: state.areaName(property.areaId),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 14,
                            ),
                          ),
                          child: const Icon(Icons.ios_share_rounded, size: 19),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddPropertyScreen(existing: property),
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
      padding: const EdgeInsets.only(bottom: 8),
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
        (
          Icons.event_outlined,
          'Ngày khảo sát',
          formatDate(property.surveyDate!),
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
