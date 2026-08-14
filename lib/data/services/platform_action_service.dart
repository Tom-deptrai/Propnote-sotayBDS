import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/geo_point.dart';

class PlatformActionService {
  const PlatformActionService();

  Future<void> callPhone(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (normalized.length < 3) {
      throw ArgumentError.value(phone, 'phone', 'Số điện thoại không hợp lệ');
    }
    final uri = Uri(scheme: 'tel', path: normalized);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Thiết bị không thể mở trình gọi điện');
    }
  }

  Future<void> openDirections(GeoPoint destination) async {
    final coordinate = '${destination.latitude},${destination.longitude}';
    final nativeUri = Uri.parse(
      'comgooglemaps://?daddr=$coordinate&directionsmode=driving',
    );
    if (await canLaunchUrl(nativeUri)) {
      await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      return;
    }
    final browserUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': coordinate,
      'travelmode': 'driving',
    });
    if (!await launchUrl(browserUri, mode: LaunchMode.externalApplication)) {
      throw StateError('Không thể mở ứng dụng bản đồ');
    }
  }

  Future<void> openFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw StateError('Không tìm thấy tệp tài liệu');
    }
    final result = await OpenFilex.open(path);
    switch (result.type) {
      case ResultType.done:
        return;
      case ResultType.noAppToOpen:
        throw StateError('Thiết bị không có ứng dụng phù hợp để mở tệp này');
      case ResultType.fileNotFound:
        throw StateError('Không tìm thấy tệp tài liệu');
      case ResultType.permissionDenied:
        throw StateError('Không có quyền truy cập tệp');
      case ResultType.error:
        throw StateError(
          result.message.isNotEmpty ? result.message : 'Không thể mở tài liệu',
        );
    }
  }
}
