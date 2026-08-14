/// Metadata của ảnh BĐS. File thật được lưu trong thư mục ứng dụng.
class PropertyPhoto {
  final String id;
  final String propertyId;
  final String relativePath;
  final String? thumbnailRelativePath;
  final String? mimeType;
  final int? width;
  final int? height;
  final int? fileSize;
  final int sortOrder;
  final DateTime createdAt;

  const PropertyPhoto({
    required this.id,
    required this.propertyId,
    required this.relativePath,
    required this.sortOrder,
    required this.createdAt,
    this.thumbnailRelativePath,
    this.mimeType,
    this.width,
    this.height,
    this.fileSize,
  });

  PropertyPhoto copyWith({
    String? relativePath,
    String? thumbnailRelativePath,
    String? mimeType,
    int? width,
    int? height,
    int? fileSize,
    int? sortOrder,
  }) {
    return PropertyPhoto(
      id: id,
      propertyId: propertyId,
      relativePath: relativePath ?? this.relativePath,
      thumbnailRelativePath:
          thumbnailRelativePath ?? this.thumbnailRelativePath,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }
}
