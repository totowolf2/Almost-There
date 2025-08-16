package com.vaas.almost_there

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL = "com.vaas.almost_there/main"
        private const val ALARM_SERVICE_CHANNEL = "notification_alarm_service"
        
        // Track if app is in foreground
        @Volatile
        var isAppInForeground = false
            private set
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
        
        // Setup alarm scheduler channel
        val alarmServiceChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_SERVICE_CHANNEL)
        AlarmSchedulerPlugin.setupMethodChannel(alarmServiceChannel, this)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "🚀 MainActivity onCreate called")
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        isAppInForeground = true
        Log.d(TAG, "📱 App is now in foreground")
    }

    override fun onPause() {
        super.onPause()
        isAppInForeground = false
        Log.d(TAG, "📱 App is now in background")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "🚀 MainActivity onNewIntent called")
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) {
            Log.d(TAG, "handleIntent called with null intent")
            return
        }

        val action = intent.action
        val alarmId = intent.getStringExtra("alarmId")

        Log.d(TAG, "🔥 HANDLING INTENT - Action: $action, AlarmId: $alarmId")
        Log.d(TAG, "🔥 Intent extras: ${intent.extras?.keySet()?.joinToString(", ")}")

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
            "SEND_FLUTTER_EVENT" -> {
                val eventType = intent.getStringExtra("eventType")
                Log.d(TAG, "Received SEND_FLUTTER_EVENT: $eventType for alarm: $alarmId")
                val snoozeMinutes = intent.getIntExtra("snoozeMinutes", 0)
                val triggerTime = intent.getLongExtra("triggerTime", 0)
                sendAlarmEventToFlutter(eventType ?: "", alarmId, if (snoozeMinutes > 0) snoozeMinutes else null, if (triggerTime > 0) triggerTime else null)
            }
        }
    }

    private fun sendAlarmEventToFlutter(eventType: String, alarmId: String?, snoozeMinutes: Int? = null, triggerTime: Long? = null) {
        if (alarmId == null) return

        try {
            val channel = MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger ?: return, CHANNEL)
            val arguments = mutableMapOf(
                "eventType" to eventType,
                "alarmId" to alarmId,
                "timestamp" to System.currentTimeMillis()
            )
            
            snoozeMinutes?.let { arguments["snoozeMinutes"] = it }
            triggerTime?.let { arguments["triggerTime"] = it }
            
            channel.invokeMethod("onAlarmEvent", arguments)
            Log.d(TAG, "Sent alarm event to Flutter: $eventType for alarm: $alarmId")
        } catch (e: Exception) {
            Log.e(TAG, "Error sending alarm event to Flutter", e)
        }
    }
}
