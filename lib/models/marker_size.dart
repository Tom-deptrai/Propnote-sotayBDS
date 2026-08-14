/// Kích thước hiển thị của marker trên bản đồ.
enum MarkerSize { small, medium, large }

extension MarkerSizeX on MarkerSize {
  String get label {
    switch (this) {
      case MarkerSize.small:
        return 'Nhỏ';
      case MarkerSize.medium:
        return 'Vừa';
      case MarkerSize.large:
        return 'Lớn';
    }
  }

  /// Hệ số scale áp dụng cho marker BĐS và cluster.
  double get scale {
    switch (this) {
      case MarkerSize.small:
        return 0.78;
      case MarkerSize.medium:
        return 1.0;
      case MarkerSize.large:
        return 1.3;
    }
  }
}
