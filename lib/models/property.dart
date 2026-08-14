import 'contact.dart';
import 'property_status.dart';

/// Một bất động sản trong sổ tay cá nhân.
class Property {
  final String id;
  final String title;
  final String address;
  final String areaId;
  final PropertyStatus status;
  final double price;
  final double landArea;
  final String propertyType;
  final double? frontage;
  final int? floors;
  final List<String> tags;
  final String notes;
  final DateTime? surveyDate;
  final DateTime createdAt;

  /// Vị trí trên bản đồ mock, chuẩn hoá 0.0–1.0 theo chiều rộng/cao canvas.
  final double mapX;
  final double mapY;

  /// Chỉ số màu placeholder ảnh (mô phỏng thư viện ảnh, không dùng network).
  final List<int> photoSeeds;

  /// Tài liệu/hình bổ sung (sổ nhà, giấy tờ, sơ đồ...) — tách biệt với ảnh BĐS chính.
  final List<int> documentSeeds;

  /// Liên hệ gắn với bất động sản (chủ nhà, người môi giới khác...).
  final List<Contact> contacts;

  const Property({
    required this.id,
    required this.title,
    required this.address,
    required this.areaId,
    required this.status,
    required this.price,
    required this.landArea,
    required this.propertyType,
    required this.mapX,
    required this.mapY,
    this.frontage,
    this.floors,
    this.tags = const [],
    this.notes = '',
    this.surveyDate,
    required this.createdAt,
    this.photoSeeds = const [0],
    this.documentSeeds = const [],
    this.contacts = const [],
  });

  Property copyWith({
    String? title,
    String? address,
    String? areaId,
    PropertyStatus? status,
    double? price,
    double? landArea,
    String? propertyType,
    double? frontage,
    int? floors,
    List<String>? tags,
    String? notes,
    DateTime? surveyDate,
    List<int>? photoSeeds,
    List<int>? documentSeeds,
    List<Contact>? contacts,
  }) {
    return Property(
      id: id,
      title: title ?? this.title,
      address: address ?? this.address,
      areaId: areaId ?? this.areaId,
      status: status ?? this.status,
      price: price ?? this.price,
      landArea: landArea ?? this.landArea,
      propertyType: propertyType ?? this.propertyType,
      mapX: mapX,
      mapY: mapY,
      frontage: frontage ?? this.frontage,
      floors: floors ?? this.floors,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      surveyDate: surveyDate ?? this.surveyDate,
      createdAt: createdAt,
      photoSeeds: photoSeeds ?? this.photoSeeds,
      documentSeeds: documentSeeds ?? this.documentSeeds,
      contacts: contacts ?? this.contacts,
    );
  }
}
