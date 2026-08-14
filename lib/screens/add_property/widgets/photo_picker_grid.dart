import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/mock_actions.dart';
import '../../../widgets/property_photo.dart';

/// Lưới ảnh lớn, trực quan cho form thêm nhanh. Không dùng camera/gallery
/// thật — chạm "Thêm ảnh" mở lựa chọn Chụp ảnh / Chọn từ thư viện (mock)
/// rồi thêm một ảnh placeholder mới. Cho phép nhiều ảnh.
class PhotoPickerGrid extends StatelessWidget {
  final List<int> photoSeeds;
  final ValueChanged<List<int>> onChanged;

  const PhotoPickerGrid({
    super.key,
    required this.photoSeeds,
    required this.onChanged,
  });

  Future<void> _addPhoto(BuildContext context) async {
    final source = await showImageSourceActionSheet(context);
    if (source == null) return;
    final nextSeed = (photoSeeds.isEmpty ? 0 : photoSeeds.last + 1) % 8;
    onChanged([...photoSeeds, nextSeed]);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == 'camera'
                ? 'Đã chụp ảnh (demo)'
                : 'Đã chọn ảnh từ thư viện (demo)',
          ),
        ),
      );
    }
  }

  void _removePhoto(int index) {
    final updated = [...photoSeeds]..removeAt(index);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photoSeeds.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == photoSeeds.length) {
            return _AddTile(
              onTap: () => _addPhoto(context),
              isFirst: photoSeeds.isEmpty,
            );
          }
          return Stack(
            children: [
              SizedBox(
                width: 108,
                height: 108,
                child: PropertyPhoto(
                  seed: photoSeeds[i],
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
