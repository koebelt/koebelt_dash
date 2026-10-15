package com.koebelt.dash

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // In-app updates (lib/core/updater_install.dart): hands a verified APK
        // to the system installer, which updates in place (same signing key).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.koebelt.dash/updater").setMethodCallHandler { call, result ->
            if (call.method != "installApk") return@setMethodCallHandler result.notImplemented()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !packageManager.canRequestPackageInstalls()) {
                startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")))
                return@setMethodCallHandler result.success("needs-permission")
            }
            val apk = File(call.argument<String>("path")!!)
            val uri = FileProvider.getUriForFile(this, "$packageName.updates", apk)
            startActivity(
                Intent(Intent.ACTION_VIEW)
                    .setDataAndType(uri, "application/vnd.android.package-archive")
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            result.success("started")
        }
    }
}
