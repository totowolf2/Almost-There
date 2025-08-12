package com.example.almost_there

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.android.gms.location.*
import kotlinx.coroutines.*
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.roundToInt

class GeofencingService : Service() {
    companion object {
        private const val TAG = "GeofencingService"
        private const val FOREGROUND_ID = 2000
        private const val LIVE_CARD_CHANNEL_ID = "live_cards"
        private const val LIVE_CARD_BASE_ID = 3000
        private const val LOCATION_UPDATE_INTERVAL = 45000L // 45 seconds
        private const val LOCATION_FASTEST_INTERVAL = 30000L // 30 seconds
        private const val MIN_DISTANCE_UPDATE = 200.0 // 200 meters
        
        const val ACTION_START_LIVE_CARDS = "START_LIVE_CARDS"
        const val ACTION_STOP_LIVE_CARDS = "STOP_LIVE_CARDS"
        const val ACTION_ALARM_TRIGGERED = "ALARM_TRIGGERED"
        const val ACTION_ALARM_DISMISSED = "ALARM_DISMISSED"
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    private lateinit var hiddenAlarmsPrefs: SharedPreferences
    private var currentLocation: Location? = null
    private val activeAlarms = mutableMapOf<String, AlarmData>()
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())

    data class AlarmData(
        val id: String,
        val label: String,
        val latitude: Double,
        val longitude: Double,
        val radius: Double,
        var lastDistance: Double? = null
    )

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "GeofencingService created")
        
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        hiddenAlarmsPrefs = getSharedPreferences("hidden_live_cards", Context.MODE_PRIVATE)
        createNotificationChannels()
        setupLocationCallback()
        cleanupExpiredHiddenAlarms()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started with action: ${intent?.action}")
        
        when (intent?.action) {
            ACTION_START_LIVE_CARDS -> {
                val alarms = intent.getSerializableExtra("alarms") as? ArrayList<Map<String, Any>>
                startLiveCardTracking(alarms)
            }
            ACTION_STOP_LIVE_CARDS -> stopLiveCardTracking()
            "HIDE_LIVE_CARD" -> {
                val alarmId = intent.getStringExtra("alarmId")
                if (alarmId != null) {
                    handleHideLiveCard(alarmId)
                }
            }
            ACTION_ALARM_TRIGGERED -> {
                val alarmId = intent.getStringExtra("alarmId")
                if (alarmId != null) {
                    handleAlarmTriggered(alarmId)
                }
            }
            ACTION_ALARM_DISMISSED -> {
                val alarmId = intent.getStringExtra("alarmId")
                if (alarmId != null) {
                    handleAlarmDismissed(alarmId)
                }
            }
        }
        
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        Log.d(TAG, "GeofencingService destroyed")
        stopLocationUpdates()
        serviceScope.cancel()
        super.onDestroy()
    }

    private fun createNotificationChannels() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Foreground service channel
        val serviceChannel = NotificationChannel(
            "geofencing_service",
            "Location Tracking Service",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Shows when the app is tracking your location"
            setShowBadge(true)
            enableLights(false)
            enableVibration(false)
        }
        
        // Live cards channel
        val liveCardChannel = NotificationChannel(
            LIVE_CARD_CHANNEL_ID,
            "Live Distance Cards",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Shows distance to your destinations"
            setShowBadge(true)
            enableLights(false)
            enableVibration(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        
        // Alarm triggers channel (used by GeofenceReceiver) - แบบนาฬิกาปลุก
        val alarmTriggersChannel = NotificationChannel(
            "alarm_triggers",
            "Alarm Triggers",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Alarm-style notifications when you reach destinations"
            setShowBadge(true)
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 1000, 500, 1000, 500, 1000) // สั่นแบบปลุก
            enableLights(true)
            lightColor = 0xFFFF0000.toInt() // แสงแดง
            setSound(
                android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI,
                android.media.AudioAttributes.Builder()
                    .setUsage(android.media.AudioAttributes.USAGE_ALARM)
                    .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC // แสดงบน lock screen
            setBypassDnd(true) // ข้าม Do Not Disturb mode
        }
        
        notificationManager.createNotificationChannel(serviceChannel)
        notificationManager.createNotificationChannel(liveCardChannel)
        notificationManager.createNotificationChannel(alarmTriggersChannel)
    }

    private fun setupLocationCallback() {
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    currentLocation = location
                    updateLiveCards(location)
                }
            }
        }
    }

    private fun startLiveCardTracking(alarmData: ArrayList<Map<String, Any>>?) {
        Log.d(TAG, "Starting live card tracking with ${alarmData?.size ?: 0} alarms")
        
        // Create foreground notification
        val notification = createForegroundNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(FOREGROUND_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
            startForeground(FOREGROUND_ID, notification)
        }
        
        // Load active alarms from Flutter
        loadActiveAlarms(alarmData)
        
        // Start location updates
        startLocationUpdates()
    }

    private fun stopLiveCardTracking() {
        Log.d(TAG, "Stopping live card tracking")
        stopLocationUpdates()
        clearAllLiveCards()
        stopSelf()
    }

    private fun startLocationUpdates() {
        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            Log.e(TAG, "Location permission not granted")
            return
        }

        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_BALANCED_POWER_ACCURACY, LOCATION_UPDATE_INTERVAL)
            .setMinUpdateIntervalMillis(LOCATION_FASTEST_INTERVAL)
            .setMinUpdateDistanceMeters(MIN_DISTANCE_UPDATE.toFloat())
            .build()

        fusedLocationClient.requestLocationUpdates(
            locationRequest,
            locationCallback,
            Looper.getMainLooper()
        )
        
        Log.d(TAG, "Location updates started")
    }

    private fun stopLocationUpdates() {
        fusedLocationClient.removeLocationUpdates(locationCallback)
        Log.d(TAG, "Location updates stopped")
    }

    private fun loadActiveAlarms(alarmData: ArrayList<Map<String, Any>>?) {
        serviceScope.launch {
            try {
                activeAlarms.clear()
                val todayKey = getTodayKey()
                
                alarmData?.forEach { alarmMap ->
                    val id = alarmMap["id"] as? String ?: return@forEach
                    val label = alarmMap["label"] as? String ?: "Unknown"
                    val latitude = alarmMap["latitude"] as? Double ?: return@forEach
                    val longitude = alarmMap["longitude"] as? Double ?: return@forEach
                    val radius = alarmMap["radius"] as? Double ?: 300.0
                    
                    // Skip if alarm is hidden for today
                    if (isAlarmHiddenToday(id)) {
                        Log.d(TAG, "Skipping hidden alarm for today: $label")
                        return@forEach
                    }
                    
                    val alarm = AlarmData(
                        id = id,
                        label = label,
                        latitude = latitude,
                        longitude = longitude,
                        radius = radius
                    )
                    activeAlarms[id] = alarm
                    Log.d(TAG, "Loaded alarm: $label at ($latitude, $longitude) radius: ${radius}m")
                }
                Log.d(TAG, "Loaded ${activeAlarms.size} active alarms (after filtering hidden)")
            } catch (e: Exception) {
                Log.e(TAG, "Error loading active alarms", e)
            }
        }
    }

    private fun updateLiveCards(location: Location) {
        serviceScope.launch {
            for ((alarmId, alarmData) in activeAlarms) {
                val distance = calculateDistance(
                    location.latitude, location.longitude,
                    alarmData.latitude, alarmData.longitude
                )
                
                // Only update if distance changed significantly
                if (alarmData.lastDistance == null || 
                    kotlin.math.abs(distance - alarmData.lastDistance!!) > MIN_DISTANCE_UPDATE) {
                    
                    alarmData.lastDistance = distance
                    showLiveCard(alarmData, distance)
                }
            }
        }
    }

    private fun showLiveCard(alarmData: AlarmData, distance: Double) {
        val formattedDistance = if (distance >= 1000) {
            "${(distance / 1000).toString().take(4)} กม."
        } else {
            "${distance.roundToInt()} ม."
        }
        
        val eta = estimateETA(distance)
        
        // Create intent to open the app when notification is tapped
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("alarmId", alarmData.id) // Pass alarm ID to potentially navigate to specific alarm
        }
        val pendingOpenAppIntent = PendingIntent.getActivity(
            this, 
            alarmData.id.hashCode(), 
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, LIVE_CARD_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("${alarmData.label} — เหลือ $formattedDistance")
            .setContentText("จุดเตือน: ${formatRadius(alarmData.radius)} | ETA ~$eta")
            .setContentIntent(pendingOpenAppIntent) // Add tap action
            .setOngoing(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_NAVIGATION)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(createSnoozeAction(alarmData.id))
            .addAction(createHideAction(alarmData.id))
            .addAction(createStopAction(alarmData.id))
            .build()
        
        val notificationId = LIVE_CARD_BASE_ID + alarmData.id.hashCode()
        NotificationManagerCompat.from(this).notify(notificationId, notification)
    }

    private fun handleAlarmTriggered(alarmId: String) {
        Log.d(TAG, "Alarm triggered: $alarmId")
        // Remove from active alarms as it's now triggered
        activeAlarms.remove(alarmId)
        clearLiveCard(alarmId)
    }

    private fun handleAlarmDismissed(alarmId: String) {
        Log.d(TAG, "Alarm dismissed: $alarmId")
        
        // Send event to Flutter FIRST, before any cleanup
        Log.d(TAG, "Sending LIVECARD_STOPPED event to Flutter...")
        sendEventToFlutter("LIVECARD_STOPPED", alarmId)
        
        // Then clean up
        activeAlarms.remove(alarmId)
        clearLiveCard(alarmId)
        
        // Stop service if no more active alarms
        if (activeAlarms.isEmpty()) {
            Log.d(TAG, "No more active alarms, stopping service")
            stopLiveCardTracking()
        }
    }

    private fun handleHideLiveCard(alarmId: String) {
        Log.d(TAG, "Hiding live card for today: $alarmId")
        
        // Persist hidden state for today
        setAlarmHiddenToday(alarmId)
        
        // Remove from active tracking for today only
        activeAlarms.remove(alarmId)
        clearLiveCard(alarmId)
        
        // Send event to Flutter for immediate UI update
        sendEventToFlutter("LIVECARD_HIDDEN", alarmId)
        
        // Note: For recurring alarms, this only hides for today
        // The alarm remains enabled and will show again tomorrow
        
        // Stop service if no more active alarms
        if (activeAlarms.isEmpty()) {
            stopLiveCardTracking()
        }
    }

    private fun clearLiveCard(alarmId: String) {
        val notificationId = LIVE_CARD_BASE_ID + alarmId.hashCode()
        NotificationManagerCompat.from(this).cancel(notificationId)
    }

    private fun clearAllLiveCards() {
        for (alarmId in activeAlarms.keys) {
            clearLiveCard(alarmId)
        }
        activeAlarms.clear()
    }

    private fun createForegroundNotification(): Notification {
        return NotificationCompat.Builder(this, "geofencing_service")
            .setContentTitle("Almost There!")
            .setContentText("กำลังติดตามตำแหน่งสำหรับการแจ้งเตือน")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    private fun createSnoozeAction(alarmId: String): NotificationCompat.Action {
        val intent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = "SNOOZE_ALARM"
            putExtra("alarmId", alarmId)
            putExtra("snoozeMinutes", 5)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this, alarmId.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        return NotificationCompat.Action(R.mipmap.ic_launcher, "Snooze 5m", pendingIntent)
    }

    private fun createHideAction(alarmId: String): NotificationCompat.Action {
        val intent = Intent(this, GeofencingService::class.java).apply {
            action = "HIDE_LIVE_CARD"
            putExtra("alarmId", alarmId)
        }
        val pendingIntent = PendingIntent.getService(
            this, alarmId.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        return NotificationCompat.Action(R.mipmap.ic_launcher, "Hide today", pendingIntent)
    }

    private fun createStopAction(alarmId: String): NotificationCompat.Action {
        val intent = Intent(this, GeofencingService::class.java).apply {
            action = ACTION_ALARM_DISMISSED
            putExtra("alarmId", alarmId)
        }
        val pendingIntent = PendingIntent.getService(
            this, alarmId.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        return NotificationCompat.Action(R.mipmap.ic_launcher, "Stop", pendingIntent)
    }

    private fun calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val results = FloatArray(1)
        Location.distanceBetween(lat1, lon1, lat2, lon2, results)
        return results[0].toDouble()
    }

    private fun estimateETA(distanceMeters: Double): String {
        val speedKmh = 5.0 // Assume walking speed
        val timeHours = distanceMeters / 1000 / speedKmh
        val timeMinutes = (timeHours * 60).roundToInt()
        
        return when {
            timeMinutes < 1 -> "< 1 นาที"
            timeMinutes < 60 -> "$timeMinutes นาที"
            else -> {
                val hours = timeMinutes / 60
                val minutes = timeMinutes % 60
                if (minutes == 0) "$hours ชม." else "$hours ชม. ${minutes}น."
            }
        }
    }

    private fun formatRadius(radius: Double): String {
        return if (radius >= 1000) {
            "${(radius / 1000).toString().take(4)} กม."
        } else {
            "${radius.roundToInt()} ม."
        }
    }

    // Helper methods for "Hide today" persistence
    private fun getTodayKey(): String {
        return dateFormat.format(Date())
    }

    private fun isAlarmHiddenToday(alarmId: String): Boolean {
        val todayKey = getTodayKey()
        return hiddenAlarmsPrefs.getStringSet(todayKey, emptySet())?.contains(alarmId) == true
    }

    private fun setAlarmHiddenToday(alarmId: String) {
        val todayKey = getTodayKey()
        val hiddenAlarms = hiddenAlarmsPrefs.getStringSet(todayKey, mutableSetOf())?.toMutableSet() ?: mutableSetOf()
        hiddenAlarms.add(alarmId)
        hiddenAlarmsPrefs.edit().putStringSet(todayKey, hiddenAlarms).apply()
        Log.d(TAG, "Marked alarm $alarmId as hidden for today ($todayKey)")
    }

    private fun cleanupExpiredHiddenAlarms() {
        // Remove hidden alarm entries older than 7 days to prevent storage bloat
        val allKeys = hiddenAlarmsPrefs.all.keys
        val sevenDaysAgo = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, -7)
        }.time
        val cutoffDate = dateFormat.format(sevenDaysAgo)

        val editor = hiddenAlarmsPrefs.edit()
        allKeys.forEach { key ->
            if (key < cutoffDate) {
                editor.remove(key)
                Log.d(TAG, "Cleaned up expired hidden alarms for date: $key")
            }
        }
        editor.apply()
    }

    private fun sendEventToFlutter(eventType: String, alarmId: String) {
        try {
            Log.d(TAG, "Creating intent to send $eventType event to Flutter...")
            val mainActivityIntent = Intent(this, MainActivity::class.java).apply {
                action = "SEND_FLUTTER_EVENT"
                putExtra("eventType", eventType)
                putExtra("alarmId", alarmId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            Log.d(TAG, "Starting activity with intent...")
            startActivity(mainActivityIntent)
            Log.d(TAG, "Successfully sent $eventType event to Flutter for alarm: $alarmId")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send $eventType event to Flutter for alarm: $alarmId", e)
        }
    }
}