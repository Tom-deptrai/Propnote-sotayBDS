import 'package:flutter/services.dart';

/// Formatter nhập số kiểu Việt Nam: dấu "." phân cách hàng nghìn, dấu ","
/// cho phần thập phân — chỉ định dạng lại phần người dùng đã gõ, không tự
/// thêm phần thập phân khi không cần (`12500` → `12.500`, không phải
/// `12.500,0`).
class VnThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    if (!RegExp(r'^[0-9.,]*$').hasMatch(newValue.text)) return oldValue;

    final cursorIndex = newValue.selection.end.clamp(0, newValue.text.length);
    final contentBeforeCursor = newValue.text
        .substring(0, cursorIndex)
        .replaceAll('.', '')
        .length;

    final raw = newValue.text.replaceAll('.', '');
    if (','.allMatches(raw).length > 1) return oldValue;

    final commaIndex = raw.indexOf(',');
    final integerPart = commaIndex == -1 ? raw : raw.substring(0, commaIndex);
    final decimalPart = commaIndex == -1 ? null : raw.substring(commaIndex + 1);

    if (!RegExp(r'^[0-9]*$').hasMatch(integerPart) ||
        (decimalPart != null && !RegExp(r'^[0-9]*$').hasMatch(decimalPart))) {
      return oldValue;
    }

    final formattedInteger = _groupThousands(integerPart);
    final formatted = decimalPart == null
        ? formattedInteger
        : '$formattedInteger,$decimalPart';

    var contentSeen = 0;
    var newCursor = formatted.length;
    if (contentBeforeCursor == 0) {
      newCursor = 0;
    } else {
      for (var i = 0; i < formatted.length; i++) {
        if (formatted[i] != '.') contentSeen++;
        if (contentSeen == contentBeforeCursor) {
          newCursor = i + 1;
          break;
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  /// Định dạng một giá trị double sẵn có thành chuỗi kiểu VN, dùng để điền
  /// sẵn ô nhập khi mở form chỉnh sửa (VD: 12500.0 → "12.500", 4.2 → "4,2").
  static String formatEditUpdateStatic(double value) {
    final isWhole = value == value.roundToDouble();
    if (isWhole) {
      return _groupThousands(value.toInt().toString());
    }
    final text = value.toString();
    final parts = text.split('.');
    final integerPart = _groupThousands(parts[0]);
    var decimalPart = parts.length > 1 ? parts[1] : '';
    if (decimalPart.length > 2) decimalPart = decimalPart.substring(0, 2);
    decimalPart = decimalPart.replaceFirst(RegExp(r'0+$'), '');
    return decimalPart.isEmpty ? integerPart : '$integerPart,$decimalPart';
  }

  static String _groupThousands(String digits) {
    if (digits.length <= 3) return digits;
    final reversed = digits.split('').reversed.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < reversed.length; i++) {
      if (i != 0 && i % 3 == 0) buffer.write('.');
      buffer.write(reversed[i]);
    }
    return buffer.toString().split('').reversed.join();
  }
}

/// Chuyển chuỗi đã định dạng kiểu VN ("12.500,5") về double (12500.5).
double? parseVnNumber(String text) {
  if (text.trim().isEmpty) return null;
  final normalized = text.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(normalized);
}
