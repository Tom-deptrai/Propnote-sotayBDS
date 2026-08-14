import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/app_runtime.dart';
import '../../../models/property.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../utils/app_messenger.dart';
import '../../../widgets/media_path_scope.dart';
import '../../../widgets/property_photo.dart';
import '../../../widgets/status_badge.dart';
import '../../detail/property_detail_screen.dart';

Future<void> showPropertyPreviewSheet(
  BuildContext context, {
  required Property property,
  required String areaName,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _PropertyPreviewSheet(property: property, areaName: areaName),
  );
}

class _PropertyPreviewSheet extends StatelessWidget {
  final Property property;
  final String areaName;

  const _PropertyPreviewSheet({required this.property, required this.areaName});

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
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: PropertyPhotoView(
                    filePath: MediaPathScope.resolve(
                      context,
                      property.photos.firstOrNull?.thumbnailRelativePath ??
                          property.photos.firstOrNull?.relativePath,
                    ),
                    seed: property.photoSeeds.firstOrNull ?? 0,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatPriceShort(property.price),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppColors.navy),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      StatusBadge(status: property.status, dense: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _MetaItem(
                  icon: Icons.straighten_rounded,
                  label: formatArea(property.landArea),
                ),
                _MetaItem(icon: Icons.location_on_outlined, label: areaName),
                if (property.surveyDate != null)
                  _MetaItem(
                    icon: Icons.event_outlined,
                    label: 'Khảo sát ${formatDate(property.surveyDate!)}',
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: property.location == null
                        ? null
                        : () async {
                            try {
                              await context
                                  .read<AppRuntime?>()
                                  ?.platformActions
                                  .openDirections(property.location!);
                            } catch (_) {
                              showAppSnackBar('Không thể mở chỉ đường');
                            }
                          },
                    icon: const Icon(Icons.directions_rounded, size: 20),
                    label: const Text('Chỉ đường'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PropertyDetailScreen(propertyId: property.id),
                        ),
                      );
                    },
                    child: const Text('Xem chi tiết'),
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

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

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
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
