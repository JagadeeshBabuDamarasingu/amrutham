package app.amrutham

import android.content.Intent
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * A FragmentActivity because the phone's biometric prompt needs one. It also
 * hides the app in the recent-apps list and from screenshots while the app lock
 * is on: that is a flag on the window, so it can only be set from here.
 */
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.amrutham/secure")
            .setMethodCallHandler { call, result ->
                if (call.method == "setSecure") {
                    if (call.argument<Boolean>("on") == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                } else if (call.method == "openSecuritySettings") {
                    startActivity(Intent(Settings.ACTION_SECURITY_SETTINGS))
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
