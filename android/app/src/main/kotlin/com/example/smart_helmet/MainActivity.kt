package com.example.smart_helmet

import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "sms_plugin"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "sendSMS") {
                val number = call.argument<String>("number")
                val message = call.argument<String>("message")
                if (number != null && message != null) {
                    sendSMS(number, message)
                    result.success("SMS Sent")
                } else {
                    result.error("ERROR", "Invalid Arguments", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun sendSMS(number: String, message: String) {
        val smsManager = SmsManager.getDefault()
        smsManager.sendTextMessage(number, null, message, null, null)
    }
}
