/// Một khu vực do người dùng tự tạo để nhóm bất động sản (VD: Cầu Giấy).
class PropertyArea {
  final String id;
  final String name;
  final int sortOrder;

  const PropertyArea({
    required this.id,
    required this.name,
    this.sortOrder = 0,
  });

  PropertyArea copyWith({String? name, int? sortOrder}) {
    return PropertyArea(
      id: id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
