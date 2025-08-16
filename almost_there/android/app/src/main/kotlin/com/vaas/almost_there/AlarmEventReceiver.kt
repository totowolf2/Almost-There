package com.vaas.almost_there

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmEventReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AlarmEventReceiver"
        const val ACTION_ALARM_ACTIVATED = "com.vaas.almost_there.ALARM_ACTIVATED"
        private const val ALARM_NOTIFICATION_CHANNEL = "alarm_activation_channel"
        private const val ALARM_NOTIFICATION_ID = 1001
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_ALARM_ACTIVATED -> {
                val alarmId = intent.getStringExtra("alarmId")
                val alarmLabel = intent.getStringExtra("alarmLabel")
                
                Log.d(TAG, "🔔 Received alarm activation broadcast: $alarmLabel (ID: $alarmId)")
                
                // Check if app is in foreground
                if (MainActivity.isAppInForeground) {
                    Log.d(TAG, "📱 App is in foreground, skipping alarm activation notification")
                } else {
                    // Create notification only if app is in background
                    Log.d(TAG, "🔔 App is in background, creating alarm activation notification...")
                    createAlarmNotification(context, alarmId, alarmLabel, intent.getLongExtra("triggerTime", 0))
                    Log.d(TAG, "✅ Successfully created alarm notification")
                }
            }
        }
    }
    
    private fun createAlarmNotification(context: Context, alarmId: String?, alarmLabel: String?, triggerTime: Long) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Create notification channel for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                ALARM_NOTIFICATION_CHANNEL,
                "Alarm Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for alarm activations"
                setBypassDnd(true)
                enableVibration(true)
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(channel)
        }
        
        // Create intent to open MainActivity when notification is tapped
        val appIntent = Intent(context, MainActivity::class.java).apply {
            action = "SEND_FLUTTER_EVENT"
            putExtra("eventType", "ALARM_ACTIVATION")
            putExtra("alarmId", alarmId)
            putExtra("alarmLabel", alarmLabel)
            putExtra("triggerTime", triggerTime)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            alarmId?.hashCode() ?: 0,
            appIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Create high-priority notification
        val notification = NotificationCompat.Builder(context, ALARM_NOTIFICATION_CHANNEL)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("✅ Alarm Active: ${alarmLabel ?: "Unnamed"}")
            .setContentText("Location monitoring is now active. Tap to view details.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setFullScreenIntent(pendingIntent, true) // Show full screen on locked device
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .build()
        
        // Show notification
        notificationManager.notify(ALARM_NOTIFICATION_ID, notification)
        Log.d(TAG, "🔔 Alarm notification displayed for: $alarmLabel")
    }
}