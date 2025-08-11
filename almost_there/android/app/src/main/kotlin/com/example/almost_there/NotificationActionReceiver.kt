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
        
        // Schedule re-trigger after snooze period
        // This would typically reschedule the geofence or set an alarm
        // For now, we'll just log it
        Log.d(TAG, "Alarm $alarmId snoozed for $minutes minutes")
    }

    private fun handleDismissAlarm(context: Context, alarmId: String) {
        Log.d(TAG, "Dismissing alarm: $alarmId")
        
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
}