import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/data/services/app_directories.dart';
import 'package:propnote/data/services/property_share_service.dart';
import 'package:propnote/models/contact.dart';
import 'package:propnote/models/property.dart';
import 'package:propnote/models/property_status.dart';

void main() {
  test(
    'share text excludes sensitive fields unless explicitly selected',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'propnote_share_test_',
      );
      try {
        final directories = await AppDirectories.create(
          rootPath: temporary.path,
        );
        final service = PropertyShareService(directories);
        final property = Property(
          id: 'p',
          title: 'Nhà phố',
          address: 'Hà Nội',
          areaId: 'area',
          status: PropertyStatus.selling,
          price: 10e9,
          landArea: 70,
          propertyType: 'Nhà phố',
          notes: 'Ghi chú riêng',
          latitude: 21.03,
          longitude: 105.85,
          createdAt: DateTime(2026),
          contacts: const [
            Contact(id: 'c', label: 'Chủ nhà', phone: '0901234567'),
          ],
        );
        final defaults = {
          'price': true,
          'area': true,
          'address': true,
          'type': true,
          'tags': true,
          'notes': false,
          'exactLocation': false,
          'contacts': false,
        };

        final safeText = service.buildText(
          property: property,
          areaName: 'Cầu Giấy',
          selected: defaults,
        );
        expect(safeText, isNot(contains('Ghi chú riêng')));
        expect(safeText, isNot(contains('0901234567')));
        expect(safeText, isNot(contains('maps/search')));

        final sensitiveText = service.buildText(
          property: property,
          areaName: 'Cầu Giấy',
          selected: {
            ...defaults,
            'notes': true,
            'exactLocation': true,
            'contacts': true,
          },
        );
        expect(sensitiveText, contains('Ghi chú riêng'));
        expect(sensitiveText, contains('0901234567'));
        expect(sensitiveText, contains('maps/search'));
      } finally {
        await temporary.delete(recursive: true);
      }
    },
  );
}
