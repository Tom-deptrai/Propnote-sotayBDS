/// Loại bất động sản có ID ổn định để các lần đổi tên không làm mất liên kết.
class PropertyType {
  final String id;
  final String name;
  final int sortOrder;

  const PropertyType({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  PropertyType copyWith({String? name, int? sortOrder}) {
    return PropertyType(
      id: id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
