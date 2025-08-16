package com.vaas.almost_there

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class AlarmScheduler {
    companion object {
        private const val TAG = "AlarmScheduler"
        
        fun scheduleAlarmActivation(
            context: Context,
            alarmId: String,
            alarmLabel: String,
            triggerTimeMillis: Long
        ) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(context, AlarmActivationReceiver::class.java).apply {
                putExtra("alarmId", alarmId)
                putExtra("alarmLabel", alarmLabel)
                putExtra("triggerTime", triggerTimeMillis)
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                alarmId.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // Use setExactAndAllowWhileIdle for precise timing even in Doze mode
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTimeMillis,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerTimeMillis,
                    pendingIntent
                )
            }
            
            Log.d(TAG, "✅ Scheduled alarm activation for $alarmLabel at $triggerTimeMillis")
        }
        
        fun cancelAlarmActivation(context: Context, alarmId: String) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(context, AlarmActivationReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                alarmId.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            alarmManager.cancel(pendingIntent)
            Log.d(TAG, "❌ Cancelled alarm activation for $alarmId")
        }
    }
}

class AlarmActivationReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AlarmActivationReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getStringExtra("alarmId") ?: return
        val alarmLabel = intent.getStringExtra("alarmLabel") ?: "Alarm"
        val triggerTime = intent.getLongExtra("triggerTime", 0)
        
        Log.d(TAG, "⏰ ALARM ACTIVATION TRIGGERED: $alarmLabel (ID: $alarmId)")
        
        // Send explicit broadcast to AlarmEventReceiver
        Log.d(TAG, "⏰ Sending explicit broadcast for alarm activation")
        val broadcastIntent = Intent(context, AlarmEventReceiver::class.java).apply {
            action = AlarmEventReceiver.ACTION_ALARM_ACTIVATED
            putExtra("alarmId", alarmId)
            putExtra("alarmLabel", alarmLabel)
            putExtra("triggerTime", triggerTime)
        }
        
        try {
            context.sendBroadcast(broadcastIntent)
            Log.d(TAG, "✅ Successfully sent explicit alarm activation broadcast")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to send alarm activation broadcast", e)
        }
    }
}

class AlarmSchedulerPlugin {
    companion object {
        private const val TAG = "AlarmSchedulerPlugin"
        
        fun setupMethodChannel(methodChannel: MethodChannel, context: Context) {
            methodChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleAlarmActivation" -> {
                        try {
                            val alarmId = call.argument<String>("alarmId")
                            val alarmLabel = call.argument<String>("alarmLabel")
                            val triggerTimeMillis = call.argument<Long>("triggerTimeMillis")
                            
                            if (alarmId != null && alarmLabel != null && triggerTimeMillis != null) {
                                AlarmScheduler.scheduleAlarmActivation(
                                    context,
                                    alarmId,
                                    alarmLabel,
                                    triggerTimeMillis
                                )
                                result.success(null)
                            } else {
                                result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to schedule alarm activation", e)
                            result.error("SCHEDULE_ERROR", e.message, null)
                        }
                    }
                    
                    "cancelAlarmActivation" -> {
                        try {
                            val alarmId = call.argument<String>("alarmId")
                            if (alarmId != null) {
                                AlarmScheduler.cancelAlarmActivation(context, alarmId)
                                result.success(null)
                            } else {
                                result.error("INVALID_ARGUMENTS", "Missing alarmId", null)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to cancel alarm activation", e)
                            result.error("CANCEL_ERROR", e.message, null)
                        }
                    }
                    
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
    }
}