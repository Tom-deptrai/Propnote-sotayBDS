import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/utils/vn_number_formatter.dart';

void main() {
  const empty = TextEditingValue(selection: TextSelection.collapsed(offset: 0));

  TextEditingValue typeText(String input) {
    final formatter = VnThousandsInputFormatter();
    var value = empty;
    for (final character in input.split('')) {
      final nextText = '${value.text}$character';
      value = formatter.formatEditUpdate(
        value,
        TextEditingValue(
          text: nextText,
          selection: TextSelection.collapsed(offset: nextText.length),
        ),
      );
    }
    return value;
  }

  TextEditingValue pasteText(String input) {
    return VnThousandsInputFormatter().formatEditUpdate(
      empty,
      TextEditingValue(
        text: input,
        selection: TextSelection.collapsed(offset: input.length),
      ),
    );
  }

  test('formats integers with Vietnamese thousands separators', () {
    expect(typeText('12500').text, '12.500');
    expect(pasteText('12500').text, '12.500');
  });

  test('accepts comma and dot decimal input while typing', () {
    expect(typeText('4,2').text, '4,2');
    expect(typeText('4.2').text, '4,2');
    expect(typeText('12500,5').text, '12.500,5');
    expect(typeText('12500.5').text, '12.500,5');
  });

  test('normalizes pasted decimal input without changing grouped integers', () {
    expect(pasteText('12500,5').text, '12.500,5');
    expect(pasteText('12500.5').text, '12.500,5');
    expect(pasteText('12.500').text, '12.500');
    expect(pasteText('12.500,5').text, '12.500,5');
  });

  test('formats existing values without adding a zero decimal', () {
    expect(VnThousandsInputFormatter.formatEditUpdateStatic(12500), '12.500');
    expect(
      VnThousandsInputFormatter.formatEditUpdateStatic(12500.5),
      '12.500,5',
    );
    expect(VnThousandsInputFormatter.formatEditUpdateStatic(4.2), '4,2');
  });

  test('parses Vietnamese formatted values', () {
    expect(parseVnNumber('12.500'), 12500);
    expect(parseVnNumber('12.500,5'), 12500.5);
    expect(parseVnNumber('4,2'), 4.2);
  });
}
