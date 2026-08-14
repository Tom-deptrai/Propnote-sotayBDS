import '../models/property.dart';

/// Cách sắp xếp danh sách bất động sản ở màn hình Danh sách.
enum ListSortOption {
  newest,
  oldest,
  priceHighToLow,
  priceLowToHigh,
  areaLargeToSmall,
  areaSmallToLarge,
}

extension ListSortOptionX on ListSortOption {
  String get label {
    switch (this) {
      case ListSortOption.newest:
        return 'Mới nhất';
      case ListSortOption.oldest:
        return 'Cũ nhất';
      case ListSortOption.priceHighToLow:
        return 'Giá cao → thấp';
      case ListSortOption.priceLowToHigh:
        return 'Giá thấp → cao';
      case ListSortOption.areaLargeToSmall:
        return 'Diện tích lớn → nhỏ';
      case ListSortOption.areaSmallToLarge:
        return 'Diện tích nhỏ → lớn';
    }
  }

  /// Mốc thời gian đại diện cho một BĐS khi sắp theo mới/cũ nhất — ưu tiên
  /// ngày khảo sát, nếu chưa khảo sát thì lấy ngày tạo làm fallback.
  static DateTime _referenceDate(Property p) => p.surveyDate ?? p.createdAt;

  /// So sánh hai BĐS theo tiêu chí sắp xếp hiện tại. Khi hai mục bằng nhau,
  /// fallback theo ngày rồi theo id để kết quả luôn deterministic (Dart
  /// không đảm bảo `List.sort` là stable).
  int compare(Property a, Property b) {
    int primary;
    switch (this) {
      case ListSortOption.newest:
        primary = _referenceDate(b).compareTo(_referenceDate(a));
        break;
      case ListSortOption.oldest:
        primary = _referenceDate(a).compareTo(_referenceDate(b));
        break;
      case ListSortOption.priceHighToLow:
        primary = b.price.compareTo(a.price);
        break;
      case ListSortOption.priceLowToHigh:
        primary = a.price.compareTo(b.price);
        break;
      case ListSortOption.areaLargeToSmall:
        primary = b.landArea.compareTo(a.landArea);
        break;
      case ListSortOption.areaSmallToLarge:
        primary = a.landArea.compareTo(b.landArea);
        break;
    }
    if (primary != 0) return primary;

    final dateFallback = this == ListSortOption.oldest
        ? _referenceDate(a).compareTo(_referenceDate(b))
        : _referenceDate(b).compareTo(_referenceDate(a));
    if (dateFallback != 0) return dateFallback;

    final createdAtFallback = this == ListSortOption.oldest
        ? a.createdAt.compareTo(b.createdAt)
        : b.createdAt.compareTo(a.createdAt);
    if (createdAtFallback != 0) return createdAtFallback;
    return a.id.compareTo(b.id);
  }
}
