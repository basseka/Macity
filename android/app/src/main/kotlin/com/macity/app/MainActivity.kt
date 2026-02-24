package com.macity.app

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.macity.app/browser")
            .setMethodCallHandler { call, result ->
                if (call.method == "openInBrowser") {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        openInBrowser(url)
                        result.success(true)
                    } else {
                        result.error("INVALID_URL", "URL is null", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun openInBrowser(url: String) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        // Forcer l'ouverture dans le navigateur, pas dans l'app Instagram.
        intent.addCategory(Intent.CATEGORY_BROWSABLE)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK

        // Chercher un navigateur explicitement.
        val browsers = listOf(
            "com.android.chrome",
            "org.mozilla.firefox",
            "com.opera.browser",
            "com.brave.browser",
            "com.microsoft.emmx"
        )
        for (browser in browsers) {
            intent.setPackage(browser)
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                return
            }
        }

        // Fallback : chooser sans l'app Instagram.
        intent.setPackage(null)
        val chooser = Intent.createChooser(intent, "Ouvrir avec")
        startActivity(chooser)
    }
}
