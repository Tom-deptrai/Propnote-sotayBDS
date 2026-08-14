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
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      throw StateError(
        result.message.isEmpty ? 'Không thể mở tài liệu' : result.message,
      );
    }
  }
}
