/// Một khu vực do người dùng tự tạo để nhóm bất động sản (VD: Cầu Giấy).
class PropertyArea {
  final String id;
  final String name;

  const PropertyArea({required this.id, required this.name});

  PropertyArea copyWith({String? name}) {
    return PropertyArea(id: id, name: name ?? this.name);
  }
}
