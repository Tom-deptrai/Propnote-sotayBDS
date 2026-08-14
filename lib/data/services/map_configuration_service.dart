import 'package:flutter/services.dart';

class MapConfigurationService {
  static const MethodChannel _channel = MethodChannel('propnote/config');

  const MapConfigurationService();

  Future<bool> isGoogleMapsConfigured() async {
    try {
      return await _channel.invokeMethod<bool>('isGoogleMapsConfigured') ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
