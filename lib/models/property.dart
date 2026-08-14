import 'contact.dart';
import 'property_document.dart';
import 'property_photo.dart';
import 'property_status.dart';

const Object _notProvided = Object();

/// Một bất động sản trong sổ tay cá nhân.
class Property {
  final String id;
  final String title;
  final String address;
  final String areaId;
  final PropertyStatus status;
  final double price;
  final double landArea;

  /// ID ổn định dùng cho persistence. [propertyType] chỉ là tên hiển thị.
  final String propertyTypeId;
  final String propertyType;
  final double? frontage;
  final int? floors;

  /// ID ổn định của tags; [tags] giữ tên hiển thị để tương thích UI hiện tại.
  final List<String> tagIds;
  final List<String> tags;
  final String notes;
  final DateTime? surveyDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Tọa độ domain thật, không phụ thuộc Google Maps.
  final double? latitude;
  final double? longitude;

  /// Metadata media thật; binary được lưu ngoài SQLite.
  final List<PropertyPhoto> photos;
  final List<PropertyDocument> documents;

  /// Chỉ giữ tạm trong giai đoạn migration UI mock, không được persistence.
  final double mapX;
  final double mapY;

  /// Chỉ giữ cho fixture/test cũ trong khi UI được migration sang [photos].
  final List<int> photoSeeds;

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
    this.propertyTypeId = '',
    this.mapX = 0.5,
    this.mapY = 0.5,
    this.frontage,
    this.floors,
    this.tagIds = const [],
    this.tags = const [],
    this.notes = '',
    this.surveyDate,
    required this.createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.latitude,
    this.longitude,
    this.photos = const [],
    this.documents = const [],
    this.photoSeeds = const [0],
    this.documentSeeds = const [],
    this.contacts = const [],
  }) : updatedAt = updatedAt ?? createdAt;

  Property copyWith({
    String? title,
    String? address,
    String? areaId,
    PropertyStatus? status,
    double? price,
    double? landArea,
    String? propertyTypeId,
    String? propertyType,
    Object? frontage = _notProvided,
    Object? floors = _notProvided,
    List<String>? tagIds,
    List<String>? tags,
    String? notes,
    Object? surveyDate = _notProvided,
    DateTime? updatedAt,
    Object? deletedAt = _notProvided,
    Object? latitude = _notProvided,
    Object? longitude = _notProvided,
    List<PropertyPhoto>? photos,
    List<PropertyDocument>? documents,
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
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      propertyType: propertyType ?? this.propertyType,
      mapX: mapX,
      mapY: mapY,
      frontage: identical(frontage, _notProvided)
          ? this.frontage
          : frontage as double?,
      floors: identical(floors, _notProvided) ? this.floors : floors as int?,
      tagIds: tagIds ?? this.tagIds,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      surveyDate: identical(surveyDate, _notProvided)
          ? this.surveyDate
          : surveyDate as DateTime?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, _notProvided)
          ? this.deletedAt
          : deletedAt as DateTime?,
      latitude: identical(latitude, _notProvided)
          ? this.latitude
          : latitude as double?,
      longitude: identical(longitude, _notProvided)
          ? this.longitude
          : longitude as double?,
      photos: photos ?? this.photos,
      documents: documents ?? this.documents,
      photoSeeds: photoSeeds ?? this.photoSeeds,
      documentSeeds: documentSeeds ?? this.documentSeeds,
      contacts: contacts ?? this.contacts,
    );
  }
}
