package com.example.air_send

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.air_send/app_info")
            .setMethodCallHandler { call, result ->
                if (call.method == "version") {
                    result.success(packageManager.getPackageInfo(packageName, 0).versionName)
                } else {
                    result.notImplemented()
                }
            }
    }
}
