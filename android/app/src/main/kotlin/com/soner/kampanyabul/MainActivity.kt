package com.soner.kampanyabul

import android.content.Intent
import android.net.Uri
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // "SMS ile katıl": seçici (WhatsApp vb.) çıkmasın, doğrudan varsayılan SMS uygulaması açılsın
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kampanyabul/sms").setMethodCallHandler { call, result ->
            if (call.method != "ac") { result.notImplemented(); return@setMethodCallHandler }
            val i = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:" + call.argument<String>("numara")))
                .putExtra("sms_body", call.argument<String>("govde"))
            Telephony.Sms.getDefaultSmsPackage(this)?.let { i.setPackage(it) }
            try { startActivity(i); result.success(true) } catch (e: Exception) { result.success(false) }
        }
    }
}
