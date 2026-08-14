import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../data/services/app_runtime.dart';
import '../../../models/property_photo.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/media_path_scope.dart';
import '../../../widgets/mock_actions.dart';
import '../../../widgets/property_photo.dart';

class PhotoPickerGrid extends StatelessWidget {
  final String propertyId;
  final List<PropertyPhoto> photos;
  final List<int> photoSeeds;
  final ValueChanged<List<PropertyPhoto>> onPhotosChanged;
  final ValueChanged<List<int>> onChanged;

  const PhotoPickerGrid({
    super.key,
    required this.propertyId,
    required this.photos,
    required this.photoSeeds,
    required this.onPhotosChanged,
    required this.onChanged,
  });

  Future<void> _addPhoto(BuildContext context) async {
    final source = await showImageSourceActionSheet(context);
    if (source == null) return;
    if (!context.mounted) return;
    final runtime = context.read<AppRuntime?>();
    if (runtime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở thư viện ảnh lúc này')),
      );
      return;
    }
    try {
      final picked = await runtime.mediaStorage.pickPhotos(
        propertyId: propertyId,
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      );
      onPhotosChanged([
        ...photos,
        for (var i = 0; i < picked.length; i++)
          picked[i].copyWith(sortOrder: photos.length + i),
      ]);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể thêm ảnh')));
      }
    }
  }

  void _removePhoto(int index) {
    if (index < photos.length) {
      final updated = [...photos]..removeAt(index);
      onPhotosChanged(updated);
    } else {
      final updated = [...photoSeeds]..removeAt(index - photos.length);
      onChanged(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length + photoSeeds.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final mediaCount = photos.length + photoSeeds.length;
          if (i == mediaCount) {
            return _AddTile(
              onTap: () => _addPhoto(context),
              isFirst: mediaCount == 0,
            );
          }
          final photo = i < photos.length ? photos[i] : null;
          final seedIndex = i - photos.length;
          return Stack(
            children: [
              SizedBox(
                width: 108,
                height: 108,
                child: PropertyPhotoView(
                  filePath: MediaPathScope.resolve(
                    context,
                    photo?.thumbnailRelativePath ?? photo?.relativePath,
                  ),
                  seed: seedIndex >= 0 ? photoSeeds[seedIndex] : 0,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              if (i == 0)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Ảnh bìa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 4,
                top: 4,
                child: InkWell(
                  onTap: () => _removePhoto(i),
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  final bool isFirst;

  const _AddTile({required this.onTap, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderStrong,
            style: BorderStyle.solid,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_rounded,
              color: AppColors.navy,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              isFirst ? 'Thêm ảnh' : 'Thêm',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
