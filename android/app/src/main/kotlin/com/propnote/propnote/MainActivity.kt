package com.propnote.propnote

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "propnote/config",
        ).setMethodCallHandler { call, result ->
            if (call.method == "isGoogleMapsConfigured") {
                result.success(BuildConfig.GOOGLE_MAPS_CONFIGURED)
            } else {
                result.notImplemented()
            }
        }
    }
}
