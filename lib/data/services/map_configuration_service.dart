import 'package:flutter/services.dart';

class MapConfigurationService {
  static const MethodChannel _channel = MethodChannel('propnote/config');

  const MapConfigurationService();

  Future<bool> isGoogleMapsConfigured() async {
    try {
      final result = await _channel
          .invokeMethod<bool>('isGoogleMapsConfigured')
          .timeout(const Duration(seconds: 1), onTimeout: () => false);
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
