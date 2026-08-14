/// Một liên hệ gắn với bất động sản (VD: "Chủ nhà" — "0901 234 567").
class Contact {
  final String id;
  final String label;
  final String phone;

  const Contact({required this.id, required this.label, required this.phone});

  Contact copyWith({String? label, String? phone}) {
    return Contact(
      id: id,
      label: label ?? this.label,
      phone: phone ?? this.phone,
    );
  }
}
