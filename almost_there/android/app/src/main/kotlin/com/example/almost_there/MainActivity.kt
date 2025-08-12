package com.example.almost_there

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL = "com.example.almost_there/main"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register the GeofencingPlugin
        flutterEngine.plugins.add(GeofencingPlugin())
        
        // Setup method channel for handling intents
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            // Handle any method calls from Flutter if needed
            result.notImplemented()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return

        val action = intent.action
        val alarmId = intent.getStringExtra("alarmId")

        Log.d(TAG, "Handling intent with action: $action, alarmId: $alarmId")

        when (action) {
            "ALARM_FULL_SCREEN" -> {
                Log.d(TAG, "Opening app from alarm full screen")
                // App will open automatically, Flutter will handle showing the appropriate screen
                sendAlarmEventToFlutter("ALARM_FULL_SCREEN", alarmId)
            }
            "OPEN_ALARM_MAP" -> {
                Log.d(TAG, "Opening app from alarm map action")
                sendAlarmEventToFlutter("OPEN_ALARM_MAP", alarmId)
            }
        }
    }

    private fun sendAlarmEventToFlutter(eventType: String, alarmId: String?) {
        if (alarmId == null) return

        try {
            val channel = MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger ?: return, CHANNEL)
            val arguments = mapOf(
                "eventType" to eventType,
                "alarmId" to alarmId,
                "timestamp" to System.currentTimeMillis()
            )
            
            channel.invokeMethod("onAlarmEvent", arguments)
            Log.d(TAG, "Sent alarm event to Flutter: $eventType for alarm: $alarmId")
        } catch (e: Exception) {
            Log.e(TAG, "Error sending alarm event to Flutter", e)
        }
    }
}
