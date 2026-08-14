import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var googleMapsConfigured = false
  private var configChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String ?? ""
    googleMapsConfigured = !apiKey.isEmpty && !apiKey.contains("$(")
    if googleMapsConfigured {
      GMSServices.provideAPIKey(apiKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard
      let registrar = engineBridge.pluginRegistry.registrar(
        forPlugin: "PropNoteConfigPlugin"
      )
    else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "propnote/config",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "isGoogleMapsConfigured" {
        result(self?.googleMapsConfigured ?? false)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    configChannel = channel
  }
}
