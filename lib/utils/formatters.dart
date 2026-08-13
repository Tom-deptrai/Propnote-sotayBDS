import 'package:intl/intl.dart';

/// Định dạng giá theo phong cách BĐS Việt Nam: "12,5 tỷ", "850 triệu".
String formatPriceShort(double price) {
  if (price <= 0) return 'Thoả thuận';
  if (price >= 1e9) {
    final value = price / 1e9;
    return '${_trimZero(value)} tỷ';
  }
  if (price >= 1e6) {
    final value = price / 1e6;
    return '${_trimZero(value)} triệu';
  }
  return '${NumberFormat.decimalPattern('vi').format(price)}đ';
}

String _trimZero(double value) {
  final rounded = (value * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) {
    return rounded.toInt().toString();
  }
  return rounded.toString().replaceFirst('.', ',');
}

String formatArea(double area) {
  final isWhole = area == area.roundToDouble();
  final text = isWhole
      ? area.toInt().toString()
      : area.toStringAsFixed(1).replaceFirst('.', ',');
  return '$text m²';
}

String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

String formatDateLong(DateTime date) {
  return DateFormat('dd/MM/yyyy • HH:mm').format(date);
}
