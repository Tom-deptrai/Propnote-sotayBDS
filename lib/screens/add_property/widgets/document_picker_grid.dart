import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../data/services/app_runtime.dart';
import '../../../models/property_document.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/document_photo.dart';
import '../../../widgets/media_path_scope.dart';
import '../../../widgets/mock_actions.dart';

class DocumentPickerGrid extends StatelessWidget {
  final String propertyId;
  final List<PropertyDocument> documents;
  final List<int> documentSeeds;
  final ValueChanged<List<PropertyDocument>> onDocumentsChanged;
  final ValueChanged<List<int>> onChanged;

  const DocumentPickerGrid({
    super.key,
    required this.propertyId,
    required this.documents,
    required this.documentSeeds,
    required this.onDocumentsChanged,
    required this.onChanged,
  });

  Future<void> _addDocument(BuildContext context) async {
    final source = await showImageSourceActionSheet(
      context,
      title: 'Thêm tài liệu / hình',
      includeFiles: true,
    );
    if (source == null) return;
    if (!context.mounted) return;
    final runtime = context.read<AppRuntime?>();
    if (runtime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở trình chọn tài liệu')),
      );
      return;
    }
    try {
      final document = source == 'file'
          ? await runtime.mediaStorage.pickDocumentFile(propertyId: propertyId)
          : await runtime.mediaStorage.pickDocumentImage(
              propertyId: propertyId,
              source: source == 'camera'
                  ? ImageSource.camera
                  : ImageSource.gallery,
            );
      if (document != null) {
        onDocumentsChanged([
          ...documents,
          document.copyWith(sortOrder: documents.length),
        ]);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thêm tài liệu')),
        );
      }
    }
  }

  void _removeDocument(int index) {
    if (index < documents.length) {
      final updated = [...documents]..removeAt(index);
      onDocumentsChanged(updated);
    } else {
      final updated = [...documentSeeds]..removeAt(index - documents.length);
      onChanged(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: documents.length + documentSeeds.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final mediaCount = documents.length + documentSeeds.length;
          if (i == mediaCount) {
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
          final document = i < documents.length ? documents[i] : null;
          final seedIndex = i - documents.length;
          return Stack(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: DocumentPhotoView(
                  filePath: MediaPathScope.resolve(
                    context,
                    document?.thumbnailRelativePath ?? document?.relativePath,
                  ),
                  mimeType: document?.mimeType,
                  seed: seedIndex >= 0 ? documentSeeds[seedIndex] : 0,
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
