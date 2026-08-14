import 'package:flutter/material.dart';

import '../models/property.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'media_path_scope.dart';
import 'property_photo.dart';
import 'status_badge.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final String areaName;
  final VoidCallback onTap;

  const PropertyCard({
    super.key,
    required this.property,
    required this.areaName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              height: 92,
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          formatPriceShort(property.price),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: property.status, dense: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatArea(property.landArea)} · $areaName',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    property.address,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 12.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (property.tags.isNotEmpty)
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 5,
                            children: property.tags.take(2).map((t) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      else
                        const Spacer(),
                      if (property.tags.isNotEmpty) const SizedBox(width: 6),
                      Text(
                        property.surveyDate != null
                            ? 'Khảo sát: ${formatDate(property.surveyDate!)}'
                            : 'Chưa khảo sát',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
