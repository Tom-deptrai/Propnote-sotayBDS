import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/document_photo.dart';
import '../../../widgets/mock_actions.dart';

/// Lưới tài liệu/hình bổ sung — tách biệt với ảnh BĐS chính. Mock chụp
/// ảnh/chọn thư viện, không dùng camera/gallery thật.
class DocumentPickerGrid extends StatelessWidget {
  final List<int> documentSeeds;
  final ValueChanged<List<int>> onChanged;

  const DocumentPickerGrid({
    super.key,
    required this.documentSeeds,
    required this.onChanged,
  });

  Future<void> _addDocument(BuildContext context) async {
    final source = await showImageSourceActionSheet(
      context,
      title: 'Thêm tài liệu / hình',
    );
    if (source == null) return;
    final nextSeed = (documentSeeds.isEmpty ? 0 : documentSeeds.last + 1) % 4;
    onChanged([...documentSeeds, nextSeed]);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == 'camera'
                ? 'Đã chụp ảnh tài liệu (demo)'
                : 'Đã chọn tài liệu từ thư viện (demo)',
          ),
        ),
      );
    }
  }

  void _removeDocument(int index) {
    final updated = [...documentSeeds]..removeAt(index);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: documentSeeds.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == documentSeeds.length) {
            return InkWell(
              onTap: () => _addDocument(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: AppColors.navy, size: 22),
                    SizedBox(height: 4),
                    Text(
                      'Thêm hình',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Stack(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: DocumentPhoto(
                  seed: documentSeeds[i],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: InkWell(
                  onTap: () => _removeDocument(i),
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
