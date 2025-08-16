package com.vaas.almost_there

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmAudioService : Service() {
    companion object {
        private const val TAG = "AlarmAudioService"
        private const val FOREGROUND_ID = 4000
        private const val CHANNEL_ID = "alarm_audio_service"
        
        const val ACTION_START_ALARM = "START_ALARM"
        const val ACTION_STOP_ALARM = "STOP_ALARM"
    }

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var currentAlarmId: String? = null
    private var isAlarmPlaying = false

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AlarmAudioService created")
        
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        Log.d(TAG, "Service started with action: $action")
        
        when (action) {
            ACTION_START_ALARM -> {
                val alarmId = intent.getStringExtra("alarmId")
                if (alarmId != null) {
                    // Start foreground immediately to prevent timeout
                    startForeground(FOREGROUND_ID, createForegroundNotification(alarmId))
                    startAlarm(alarmId)
                }
            }
            ACTION_STOP_ALARM -> {
                stopAlarm()
            }
        }
        
        return START_NOT_STICKY // Don't restart if killed
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        Log.d(TAG, "AlarmAudioService destroyed")
        stopAlarm()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Alarm Audio Service",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Handles alarm sound playback"
            setShowBadge(false)
            enableLights(false)
            enableVibration(false)
            setSound(null, null) // Silent notification
        }
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    private fun startAlarm(alarmId: String) {
        if (isAlarmPlaying && currentAlarmId == alarmId) {
            Log.d(TAG, "Alarm already playing for $alarmId")
            return
        }

        Log.d(TAG, "Starting alarm for: $alarmId")
        
        // Stop any existing alarm
        if (isAlarmPlaying) {
            stopAudioPlayback()
            stopVibration()
        }
        
        currentAlarmId = alarmId
        
        // Request audio focus
        if (requestAudioFocus()) {
            // Start audio playback
            startAudioPlayback()
            
            // Start vibration
            startVibration()
            
            isAlarmPlaying = true
            Log.d(TAG, "Alarm started successfully for: $alarmId")
        } else {
            Log.w(TAG, "Failed to get audio focus")
            stopSelf()
        }
    }

    private fun stopAlarm() {
        Log.d(TAG, "Stopping alarm")
        
        isAlarmPlaying = false
        currentAlarmId = null
        
        // Stop audio playback
        stopAudioPlayback()
        
        // Stop vibration
        stopVibration()
        
        // Release audio focus
        releaseAudioFocus()
        
        // Cancel the foreground notification explicitly
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(FOREGROUND_ID)
        
        // Stop foreground service
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        
        Log.d(TAG, "Alarm service stopped and notification cleared")
    }

    private fun requestAudioFocus(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
                
            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(audioAttributes)
                .setAcceptsDelayedFocusGain(false)
                .setOnAudioFocusChangeListener { focusChange ->
                    handleAudioFocusChange(focusChange)
                }
                .build()
                
            audioFocusRequest?.let { request ->
                audioManager?.requestAudioFocus(request) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            } ?: false
        } else {
            @Suppress("DEPRECATION")
            audioManager?.requestAudioFocus(
                { focusChange -> handleAudioFocusChange(focusChange) },
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
            ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    private fun releaseAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { request ->
                audioManager?.abandonAudioFocusRequest(request)
            }
        } else {
            @Suppress("DEPRECATION")
            audioManager?.abandonAudioFocus(null)
        }
    }

    private fun handleAudioFocusChange(focusChange: Int) {
        Log.d(TAG, "Audio focus changed: $focusChange")
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS -> {
                // Stop alarm completely if we lose focus permanently
                stopAlarm()
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                // Pause temporarily (e.g., incoming call)
                pauseAudioPlayback()
            }
            AudioManager.AUDIOFOCUS_GAIN -> {
                // Resume playback
                if (isAlarmPlaying) {
                    resumeAudioPlayback()
                }
            }
        }
    }

    private fun startAudioPlayback() {
        try {
            stopAudioPlayback() // Ensure clean state
            
            mediaPlayer = MediaPlayer().apply {
                // Configure AudioAttributes for alarm usage
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    val audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                    setAudioAttributes(audioAttributes)
                } else {
                    @Suppress("DEPRECATION")
                    setAudioStreamType(AudioManager.STREAM_ALARM)
                }

                // Get the system alarm sound (will use default alarm sound)
                val alarmUri = getSystemAlarmSound()
                try {
                    setDataSource(this@AlarmAudioService, alarmUri)
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to set alarm sound, using fallback: ${e.message}")
                    setDataSource(this@AlarmAudioService, Settings.System.DEFAULT_NOTIFICATION_URI)
                }
                
                // Configure looping for continuous alarm
                isLooping = true
                
                // Set volume to max for alarm
                setVolume(1.0f, 1.0f)
                
                // Prepare and start
                prepareAsync()
                setOnPreparedListener { player ->
                    try {
                        player.start()
                        Log.d(TAG, "System alarm audio playback started")
                    } catch (e: Exception) {
                        Log.e(TAG, "Error starting prepared player: ${e.message}")
                        startFallbackAudio()
                    }
                }
                
                setOnErrorListener { _, what, extra ->
                    Log.e(TAG, "MediaPlayer error: what=$what, extra=$extra")
                    // Try fallback sound
                    startFallbackAudio()
                    true
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting audio playback", e)
            startFallbackAudio()
        }
    }
    
    private fun getSystemAlarmSound(): Uri {
        // Try to get the actual system alarm sound
        return try {
            Settings.System.DEFAULT_ALARM_ALERT_URI 
                ?: Settings.System.DEFAULT_NOTIFICATION_URI
                ?: Settings.System.DEFAULT_RINGTONE_URI
                ?: android.provider.MediaStore.Audio.Media.INTERNAL_CONTENT_URI
        } catch (e: Exception) {
            Log.w(TAG, "Error getting system alarm sound: ${e.message}")
            Settings.System.DEFAULT_NOTIFICATION_URI
        }
    }

    private fun startFallbackAudio() {
        try {
            Log.d(TAG, "Starting fallback audio")
            stopAudioPlayback()
            
            mediaPlayer = MediaPlayer().apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    val audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                    setAudioAttributes(audioAttributes)
                } else {
                    @Suppress("DEPRECATION")
                    setAudioStreamType(AudioManager.STREAM_ALARM)
                }

                // Use system notification sound as fallback
                val fallbackUri = Settings.System.DEFAULT_NOTIFICATION_URI
                setDataSource(this@AlarmAudioService, fallbackUri)
                isLooping = true
                setVolume(1.0f, 1.0f)
                
                prepareAsync()
                setOnPreparedListener { player ->
                    player.start()
                    Log.d(TAG, "Fallback audio playback started")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting fallback audio", e)
        }
    }

    private fun stopAudioPlayback() {
        mediaPlayer?.let { player ->
            try {
                if (player.isPlaying) {
                    player.stop()
                }
                player.release()
                Log.d(TAG, "Audio playback stopped")
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping audio playback", e)
            }
        }
        mediaPlayer = null
    }

    private fun pauseAudioPlayback() {
        mediaPlayer?.let { player ->
            try {
                if (player.isPlaying) {
                    player.pause()
                    Log.d(TAG, "Audio playback paused")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error pausing audio playback", e)
            }
        }
    }

    private fun resumeAudioPlayback() {
        mediaPlayer?.let { player ->
            try {
                if (!player.isPlaying) {
                    player.start()
                    Log.d(TAG, "Audio playback resumed")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error resuming audio playback", e)
            }
        }
    }

    private fun startVibration() {
        vibrator?.let { vib ->
            try {
                if (vib.hasVibrator()) {
                    // Create alarm-style vibration pattern
                    val pattern = longArrayOf(0, 1000, 500, 1000, 500, 1000, 500, 1000)
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val vibrationEffect = VibrationEffect.createWaveform(
                            pattern, 
                            0 // Repeat from beginning
                        )
                        vib.vibrate(vibrationEffect)
                    } else {
                        @Suppress("DEPRECATION")
                        vib.vibrate(pattern, 0) // Repeat
                    }
                    Log.d(TAG, "Vibration started")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error starting vibration", e)
            }
        }
    }

    private fun stopVibration() {
        vibrator?.let { vib ->
            try {
                vib.cancel()
                Log.d(TAG, "Vibration stopped")
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping vibration", e)
            }
        }
    }


    private fun createForegroundNotification(alarmId: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Alarm Playing")
            .setContentText("Almost There alarm is active")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setSilent(true) // Don't play notification sound
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }
}