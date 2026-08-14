import 'dart:io';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

import '../../models/property.dart';
import '../../utils/formatters.dart';
import 'app_directories.dart';

class PropertyShareService {
  final AppDirectories directories;

  const PropertyShareService(this.directories);

  String buildText({
    required Property property,
    required String areaName,
    required Map<String, bool> selected,
  }) {
    final lines = <String>[property.title];
    if (selected['price'] == true) {
      lines.add('Giá: ${formatPriceShort(property.price)}');
    }
    if (selected['area'] == true) {
      lines.add('Diện tích: ${formatArea(property.landArea)}');
    }
    if (selected['address'] == true) {
      lines.add('Địa chỉ: ${property.address} · $areaName');
    }
    if (selected['type'] == true) {
      lines.add('Loại BĐS: ${property.propertyType}');
    }
    if (selected['tags'] == true && property.tags.isNotEmpty) {
      lines.add('Tags: ${property.tags.join(', ')}');
    }
    if (selected['notes'] == true && property.notes.isNotEmpty) {
      lines.add('Ghi chú: ${property.notes}');
    }
    if (selected['exactLocation'] == true && property.location != null) {
      final location = property.location!;
      lines.add(
        'Vị trí chính xác: '
        'https://www.google.com/maps/search/?api=1&query='
        '${location.latitude},${location.longitude}',
      );
    }
    if (selected['contacts'] == true && property.contacts.isNotEmpty) {
      for (final contact in property.contacts) {
        lines.add('${contact.label}: ${contact.phone}');
      }
    }
    return lines.join('\n');
  }

  Future<ShareResult> share({
    required Property property,
    required String areaName,
    required Map<String, bool> selected,
    Rect? sharePositionOrigin,
  }) async {
    final files = <XFile>[];
    if (selected['photos'] == true) {
      for (final photo in property.photos) {
        final file = File(directories.resolve(photo.relativePath));
        if (await file.exists()) {
          files.add(XFile(file.path, mimeType: photo.mimeType));
        }
      }
    }
    if (selected['documents'] == true) {
      for (final document in property.documents) {
        final file = File(directories.resolve(document.relativePath));
        if (await file.exists()) {
          files.add(
            XFile(
              file.path,
              name: document.originalName,
              mimeType: document.mimeType,
            ),
          );
        }
      }
    }

    return SharePlus.instance.share(
      ShareParams(
        text: buildText(
          property: property,
          areaName: areaName,
          selected: selected,
        ),
        subject: property.title,
        files: files,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
