/// Metadata của tài liệu hoặc hình bổ sung. Binary không nằm trong SQLite.
class PropertyDocument {
  final String id;
  final String propertyId;
  final String relativePath;
  final String originalName;
  final String? thumbnailRelativePath;
  final String? mimeType;
  final int? fileSize;
  final int sortOrder;
  final DateTime createdAt;

  const PropertyDocument({
    required this.id,
    required this.propertyId,
    required this.relativePath,
    required this.originalName,
    required this.sortOrder,
    required this.createdAt,
    this.thumbnailRelativePath,
    this.mimeType,
    this.fileSize,
  });

  PropertyDocument copyWith({
    String? relativePath,
    String? originalName,
    String? thumbnailRelativePath,
    String? mimeType,
    int? fileSize,
    int? sortOrder,
  }) {
    return PropertyDocument(
      id: id,
      propertyId: propertyId,
      relativePath: relativePath ?? this.relativePath,
      originalName: originalName ?? this.originalName,
      thumbnailRelativePath:
          thumbnailRelativePath ?? this.thumbnailRelativePath,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }
}
