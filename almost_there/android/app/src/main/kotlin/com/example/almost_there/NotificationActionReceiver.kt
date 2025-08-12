package com.example.almost_there

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationManagerCompat

class NotificationActionReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "NotificationActionReceiver"
        private const val NOTIFICATION_ID_BASE = 1000
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        val alarmId = intent.getStringExtra("alarmId") ?: return
        
        Log.d(TAG, "Notification action received: $action for alarm: $alarmId")
        
        when (action) {
            "SNOOZE_ALARM" -> {
                val snoozeMinutes = intent.getIntExtra("snoozeMinutes", 5)
                handleSnoozeAlarm(context, alarmId, snoozeMinutes)
            }
            "DISMISS_ALARM" -> {
                handleDismissAlarm(context, alarmId)
            }
        }
    }

    private fun handleSnoozeAlarm(context: Context, alarmId: String, minutes: Int) {
        Log.d(TAG, "Snoozing alarm $alarmId for $minutes minutes")
        
        // Stop alarm audio service immediately
        stopAlarmAudioService(context)
        
        // Stop vibration immediately
        stopVibration(context)
        
        // Dismiss current notification
        val notificationManager = NotificationManagerCompat.from(context)
        val notificationId = NOTIFICATION_ID_BASE + alarmId.hashCode()
        notificationManager.cancel(notificationId)
        
        // Send snooze event to Flutter app
        val broadcastIntent = Intent("com.example.almost_there.ALARM_SNOOZED").apply {
            putExtra("alarmId", alarmId)
            putExtra("snoozeMinutes", minutes)
            putExtra("timestamp", System.currentTimeMillis())
        }
        context.sendBroadcast(broadcastIntent)
        
        // Schedule re-trigger with a smaller geofence for snooze functionality
        scheduleSnoozeAlarm(context, alarmId, minutes)
        
        Log.d(TAG, "Alarm $alarmId snoozed for $minutes minutes")
    }

    private fun handleDismissAlarm(context: Context, alarmId: String) {
        Log.d(TAG, "Dismissing alarm: $alarmId")
        
        // Stop alarm audio service immediately
        stopAlarmAudioService(context)
        
        // Stop vibration immediately
        stopVibration(context)
        
        // Dismiss current notification
        val notificationManager = NotificationManagerCompat.from(context)
        val notificationId = NOTIFICATION_ID_BASE + alarmId.hashCode()
        notificationManager.cancel(notificationId)
        
        // Send dismiss event to Flutter app
        val broadcastIntent = Intent("com.example.almost_there.ALARM_DISMISSED").apply {
            putExtra("alarmId", alarmId)
            putExtra("timestamp", System.currentTimeMillis())
        }
        context.sendBroadcast(broadcastIntent)
        
        // Stop the foreground service if no more active alarms
        val serviceIntent = Intent(context, GeofencingService::class.java).apply {
            action = GeofencingService.ACTION_ALARM_DISMISSED
            putExtra("alarmId", alarmId)
        }
        context.startForegroundService(serviceIntent)
        
        Log.d(TAG, "Alarm $alarmId dismissed")
    }

    private fun stopVibration(context: Context) {
        try {
            val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? android.os.Vibrator
            vibrator?.cancel()
            Log.d(TAG, "Vibration stopped")
        } catch (e: Exception) {
            Log.w(TAG, "Could not stop vibration: ${e.message}")
        }
    }

    private fun stopAlarmAudioService(context: Context) {
        try {
            val audioServiceIntent = Intent(context, AlarmAudioService::class.java).apply {
                action = AlarmAudioService.ACTION_STOP_ALARM
            }
            context.startService(audioServiceIntent)
            Log.d(TAG, "Alarm audio service stop requested")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping alarm audio service", e)
        }
    }

    private fun scheduleSnoozeAlarm(context: Context, alarmId: String, minutes: Int) {
        try {
            // Create a scheduled re-trigger using AlarmManager
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
            val triggerTime = System.currentTimeMillis() + (minutes * 60 * 1000)
            
            // Create intent for snooze re-trigger
            val snoozeIntent = Intent(context, GeofenceReceiver::class.java).apply {
                action = "SNOOZE_RETRIGGER"
                putExtra("alarmId", alarmId)
            }
            
            val pendingIntent = android.app.PendingIntent.getBroadcast(
                context,
                alarmId.hashCode() + 500, // Unique ID for snooze
                snoozeIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_MUTABLE
            )
            
            // Schedule the alarm with exact timing for reliability
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    android.app.AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            } else if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
                alarmManager.setExact(
                    android.app.AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            } else {
                @Suppress("DEPRECATION")
                alarmManager.set(
                    android.app.AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            }
            
            Log.d(TAG, "Snooze alarm scheduled for $minutes minutes")
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling snooze alarm", e)
        }
    }
}