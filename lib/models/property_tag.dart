/// Tag do người dùng quản lý, dùng ID ổn định cho quan hệ nhiều-nhiều.
class PropertyTag {
  final String id;
  final String name;
  final int sortOrder;

  const PropertyTag({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  PropertyTag copyWith({String? name, int? sortOrder}) {
    return PropertyTag(
      id: id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
