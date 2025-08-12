package com.example.almost_there

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationManagerCompat

class AlarmActivity : Activity() {
    companion object {
        private const val TAG = "AlarmActivity"
        private const val NOTIFICATION_ID_BASE = 1000
    }

    private var alarmId: String? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "AlarmActivity created")
        
        // Extract alarm ID from intent
        alarmId = intent.getStringExtra("alarmId")
        if (alarmId == null) {
            Log.e(TAG, "No alarmId provided, finishing activity")
            finish()
            return
        }

        setupLockScreenDisplay()
        setupAudioFocus()
        setupAlarmUI()
        
        Log.d(TAG, "Alarm activity setup complete for alarm: $alarmId")
    }

    private fun setupLockScreenDisplay() {
        // Modern approach for Android 8.1+ (API 27+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            
            // Request to dismiss the keyguard
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                keyguardManager.requestDismissKeyguard(this, null)
            }
        } else {
            // Legacy approach for older versions
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }

        // Common flags for all versions
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
        )

        // Acquire wake lock to ensure device stays awake
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "$TAG:AlarmWakeLock"
        )
        wakeLock?.acquire(5 * 60 * 1000L) // Hold for max 5 minutes

        Log.d(TAG, "Lock screen display flags configured")
    }

    private fun setupAudioFocus() {
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
                
            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(audioAttributes)
                .setAcceptsDelayedFocusGain(false)
                .setOnAudioFocusChangeListener { focusChange ->
                    Log.d(TAG, "Audio focus changed: $focusChange")
                    when (focusChange) {
                        AudioManager.AUDIOFOCUS_LOSS -> {
                            // Stop alarm if we lose audio focus completely
                            handleDismissAlarm()
                        }
                        AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                            // Pause alarm temporarily (e.g., incoming call)
                            stopAudioService()
                        }
                        AudioManager.AUDIOFOCUS_GAIN -> {
                            // Resume alarm when focus returns
                            startAudioService()
                        }
                    }
                }
                .build()
                
            audioFocusRequest?.let { request ->
                val result = audioManager?.requestAudioFocus(request)
                if (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                    Log.d(TAG, "Audio focus granted")
                } else {
                    Log.w(TAG, "Audio focus request failed")
                }
            }
        } else {
            @Suppress("DEPRECATION")
            val result = audioManager?.requestAudioFocus(
                { focusChange ->
                    Log.d(TAG, "Audio focus changed: $focusChange")
                    when (focusChange) {
                        AudioManager.AUDIOFOCUS_LOSS -> handleDismissAlarm()
                        AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> stopAudioService()
                        AudioManager.AUDIOFOCUS_GAIN -> startAudioService()
                    }
                },
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
            )
            
            if (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                Log.d(TAG, "Audio focus granted (legacy)")
            } else {
                Log.w(TAG, "Audio focus request failed (legacy)")
            }
        }
    }

    private fun setupAlarmUI() {
        // For now, create a simple programmatic UI
        // In a real app, you would create a proper layout XML file
        setContentView(createAlarmLayout())
    }

    private fun createAlarmLayout(): View {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 64, 32, 64)
            setBackgroundColor(0xFF1A1A1A.toInt()) // Dark background
        }

        // Alarm title
        val titleText = TextView(this).apply {
            text = "⏰ Almost There!"
            textSize = 32f
            setTextColor(0xFFFFFFFF.toInt()) // White text
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }

        // Alarm message
        val messageText = TextView(this).apply {
            text = "🚨 You've reached your destination! 🚨\n\nChoose an action below:"
            textSize = 18f
            setTextColor(0xFFE0E0E0.toInt()) // Light gray text
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 48)
        }

        // Snooze button
        val snoozeButton = Button(this).apply {
            text = "⏰ Snooze 5 minutes"
            textSize = 18f
            setPadding(32, 24, 32, 24)
            setBackgroundColor(0xFF4CAF50.toInt()) // Green
            setTextColor(0xFFFFFFFF.toInt()) // White text
            setOnClickListener { handleSnoozeAlarm(5) }
        }

        // Dismiss button
        val dismissButton = Button(this).apply {
            text = "✅ Dismiss Alarm"
            textSize = 18f
            setPadding(32, 24, 32, 24)
            setBackgroundColor(0xFFF44336.toInt()) // Red
            setTextColor(0xFFFFFFFF.toInt()) // White text
            setOnClickListener { handleDismissAlarm() }
        }

        // Add spacing between buttons
        val buttonSpacing = 24

        layout.addView(titleText)
        layout.addView(messageText)
        layout.addView(snoozeButton)
        
        // Add space between buttons
        val spacer = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                buttonSpacing
            )
        }
        layout.addView(spacer)
        
        layout.addView(dismissButton)

        return layout
    }

    private fun handleSnoozeAlarm(minutes: Int) {
        Log.d(TAG, "Snoozing alarm for $minutes minutes")
        
        // Stop audio service
        stopAudioService()
        
        // Send snooze action
        val intent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = "SNOOZE_ALARM"
            putExtra("alarmId", alarmId)
            putExtra("snoozeMinutes", minutes)
        }
        sendBroadcast(intent)
        
        // Dismiss notification
        dismissNotification()
        
        // Finish activity
        finish()
    }

    private fun handleDismissAlarm() {
        Log.d(TAG, "Dismissing alarm")
        
        // Stop audio service
        stopAudioService()
        
        // Send dismiss action
        val intent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = "DISMISS_ALARM"
            putExtra("alarmId", alarmId)
        }
        sendBroadcast(intent)
        
        // Dismiss notification
        dismissNotification()
        
        // Finish activity
        finish()
    }

    private fun startAudioService() {
        alarmId?.let { id ->
            val intent = Intent(this, AlarmAudioService::class.java).apply {
                action = AlarmAudioService.ACTION_START_ALARM
                putExtra("alarmId", id)
            }
            startForegroundService(intent)
        }
    }

    private fun stopAudioService() {
        val intent = Intent(this, AlarmAudioService::class.java).apply {
            action = AlarmAudioService.ACTION_STOP_ALARM
        }
        startService(intent)
    }

    private fun dismissNotification() {
        alarmId?.let { id ->
            val notificationManager = NotificationManagerCompat.from(this)
            val notificationId = NOTIFICATION_ID_BASE + id.hashCode()
            notificationManager.cancel(notificationId)
        }
    }

    override fun onStart() {
        super.onStart()
        // Start audio service when activity becomes visible
        startAudioService()
    }

    override fun onStop() {
        super.onStop()
        // Don't stop audio service here - let user actions control it
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "AlarmActivity destroyed")
        
        // Release audio focus
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { request ->
                audioManager?.abandonAudioFocusRequest(request)
            }
        } else {
            @Suppress("DEPRECATION")
            audioManager?.abandonAudioFocus(null)
        }
        
        // Release wake lock
        wakeLock?.let { lock ->
            if (lock.isHeld) {
                lock.release()
            }
        }
    }

    override fun onBackPressed() {
        // Prevent back button from dismissing alarm - force user to choose snooze/dismiss
        Log.d(TAG, "Back button pressed - ignoring")
    }
}