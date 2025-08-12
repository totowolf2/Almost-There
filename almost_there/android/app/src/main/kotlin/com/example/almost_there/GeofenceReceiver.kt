package com.example.almost_there

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofenceStatusCodes
import com.google.android.gms.location.GeofencingEvent

class GeofenceReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "GeofenceReceiver"
        private const val CHANNEL_ID = "alarm_triggers"
        private const val NOTIFICATION_ID_BASE = 1000
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Geofence event received")
        
        val geofencingEvent = GeofencingEvent.fromIntent(intent)
        if (geofencingEvent == null) {
            Log.e(TAG, "GeofencingEvent is null")
            return
        }

        if (geofencingEvent.hasError()) {
            val errorMessage = GeofenceStatusCodes.getStatusCodeString(geofencingEvent.errorCode)
            Log.e(TAG, "Geofence error: $errorMessage")
            return
        }

        // Get the transition type
        val geofenceTransition = geofencingEvent.geofenceTransition

        // Test that the reported transition was of interest
        if (geofenceTransition == Geofence.GEOFENCE_TRANSITION_ENTER) {
            Log.d(TAG, "Geofence ENTER transition detected")
            
            // Get the geofences that were triggered
            val triggeringGeofences = geofencingEvent.triggeringGeofences
            if (triggeringGeofences != null) {
                for (geofence in triggeringGeofences) {
                    handleGeofenceEnter(context, geofence.requestId)
                }
            }
        } else {
            Log.e(TAG, "Invalid geofence transition type: $geofenceTransition")
        }
    }

    private fun handleGeofenceEnter(context: Context, geofenceId: String) {
        Log.d(TAG, "Processing geofence enter for: $geofenceId")
        
        // Extract alarm ID from geofence request ID
        val alarmId = geofenceId.removePrefix("alarm_")
        
        // Send trigger event to Flutter app through method channel
        sendTriggerToFlutter(context, alarmId)
        
        // Show immediate notification
        showTriggerNotification(context, alarmId)
        
        // Start/update the foreground service for live distance tracking
        val serviceIntent = Intent(context, GeofencingService::class.java).apply {
            action = GeofencingService.ACTION_ALARM_TRIGGERED
            putExtra("alarmId", alarmId)
        }
        context.startForegroundService(serviceIntent)
    }

    private fun sendTriggerToFlutter(context: Context, alarmId: String) {
        try {
            // This will be handled by the Flutter app when it's in foreground
            // For background processing, we rely on the foreground service
            val intent = Intent("com.example.almost_there.ALARM_TRIGGERED").apply {
                putExtra("alarmId", alarmId)
                putExtra("timestamp", System.currentTimeMillis())
            }
            context.sendBroadcast(intent)
            Log.d(TAG, "Sent trigger broadcast for alarm: $alarmId")
        } catch (e: Exception) {
            Log.e(TAG, "Error sending trigger to Flutter", e)
        }
    }

    private fun showTriggerNotification(context: Context, alarmId: String) {
        try {
            // Create full-screen intent สำหรับแสดงหน้าปลุกเต็มจอ
            val fullScreenIntent = Intent(context, MainActivity::class.java).apply {
                action = "ALARM_FULL_SCREEN"
                putExtra("alarmId", alarmId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val fullScreenPendingIntent = android.app.PendingIntent.getActivity(
                context,
                alarmId.hashCode() + 100,
                fullScreenIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_MUTABLE
            )

            // สร้าง notification แบบนาฬิกาปลุก - เสียงดัง ต่อเนื่อง
            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("⏰ ถึงปลายทางแล้ว! ⏰")
                .setContentText("🚨 คุณใกล้ถึงจุดหมายแล้ว! 🚨")
                .setPriority(NotificationCompat.PRIORITY_MAX) // สูงสุด
                .setCategory(NotificationCompat.CATEGORY_ALARM) // ประเภทปลุก
                .setAutoCancel(false) // ไม่หายเมื่อแตะ
                .setOngoing(true) // ไม่สามารถปัดทิ้งได้
                
                // ตั้งค่าเสียงและการสั่นแบบนาฬิกาปลุก
                .setDefaults(0) // ไม่ใช้ default เพื่อกำหนดเอง
                .setSound(android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI) // เสียงปลุก
                .setVibrate(longArrayOf(0, 1000, 500, 1000, 500, 1000, 500, 1000)) // สั่นต่อเนื่อง
                .setLights(0xFFFF0000.toInt(), 1000, 500) // ไฟกระพริบแดง
                
                // Full screen notification สำหรับหน้าจอล็อก
                .setFullScreenIntent(fullScreenPendingIntent, true)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC) // แสดงบนหน้าจอล็อก
                
                // Actions แบบนาฬิกาปลุก
                .addAction(
                    R.mipmap.ic_launcher,
                    "⏰ Snooze 5 นาที",
                    createSnoozeIntent(context, alarmId, 5)
                )
                .addAction(
                    R.mipmap.ic_launcher,
                    "✅ ปิดเตือน",
                    createDismissIntent(context, alarmId)
                )
                .addAction(
                    R.mipmap.ic_launcher,
                    "🗺️ ดูแผนที่",
                    createOpenMapIntent(context, alarmId)
                )
                
                // Style แบบ big text เพื่อแสดงข้อความเต็ม
                .setStyle(NotificationCompat.BigTextStyle()
                    .bigText("🚨 คุณมาถึงจุดหมายแล้ว! 🚨\n\nแตะเพื่อปิดการแจ้งเตือน หรือเลื่อนเตือนอีก 5 นาที")
                    .setBigContentTitle("⏰ Almost There - ถึงปลายทางแล้ว! ⏰"))
                .build()

            val notificationManager = NotificationManagerCompat.from(context)
            val notificationId = NOTIFICATION_ID_BASE + alarmId.hashCode()
            
            // Check notification permission (Android 13+)
            if (notificationManager.areNotificationsEnabled()) {
                notificationManager.notify(notificationId, notification)
                Log.d(TAG, "🚨 ALARM TRIGGER notification shown for alarm: $alarmId")
                
                // เพิ่มการสั่นเสริมผ่าน Vibrator (สำหรับอุปกรณ์ที่รองรับ)
                try {
                    val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? android.os.Vibrator
                    if (vibrator?.hasVibrator() == true) {
                        // สั่นแบบ pattern: pause, vibrate, pause, vibrate...
                        val vibratePattern = longArrayOf(0, 1000, 500, 1000, 500, 1000)
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                            vibrator.vibrate(android.os.VibrationEffect.createWaveform(vibratePattern, 0)) // repeat
                        } else {
                            @Suppress("DEPRECATION")
                            vibrator.vibrate(vibratePattern, 0) // repeat
                        }
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Could not trigger vibration: ${e.message}")
                }
                
            } else {
                Log.w(TAG, "Notification permission not granted - alarm might not be heard!")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error showing ALARM trigger notification", e)
        }
    }

    private fun createSnoozeIntent(context: Context, alarmId: String, minutes: Int): android.app.PendingIntent {
        val intent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = "SNOOZE_ALARM"
            putExtra("alarmId", alarmId)
            putExtra("snoozeMinutes", minutes)
        }
        return android.app.PendingIntent.getBroadcast(
            context,
            alarmId.hashCode(),
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_MUTABLE
        )
    }

    private fun createDismissIntent(context: Context, alarmId: String): android.app.PendingIntent {
        val intent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = "DISMISS_ALARM"
            putExtra("alarmId", alarmId)
        }
        return android.app.PendingIntent.getBroadcast(
            context,
            alarmId.hashCode() + 1,
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_MUTABLE
        )
    }

    private fun createOpenMapIntent(context: Context, alarmId: String): android.app.PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = "OPEN_ALARM_MAP"
            putExtra("alarmId", alarmId)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return android.app.PendingIntent.getActivity(
            context,
            alarmId.hashCode() + 2,
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_MUTABLE
        )
    }
}