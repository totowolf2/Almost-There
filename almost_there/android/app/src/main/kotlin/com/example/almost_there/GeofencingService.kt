package com.example.almost_there

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
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
    private var currentLocation: Location? = null
    private val activeAlarms = mutableMapOf<String, AlarmData>()
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

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
        createNotificationChannels()
        setupLocationCallback()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started with action: ${intent?.action}")
        
        when (intent?.action) {
            ACTION_START_LIVE_CARDS -> startLiveCardTracking()
            ACTION_STOP_LIVE_CARDS -> stopLiveCardTracking()
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
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shows when the app is tracking your location"
            setShowBadge(false)
        }
        
        // Live cards channel
        val liveCardChannel = NotificationChannel(
            LIVE_CARD_CHANNEL_ID,
            "Live Distance Cards",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Shows distance to your destinations"
            setShowBadge(true)
        }
        
        notificationManager.createNotificationChannel(serviceChannel)
        notificationManager.createNotificationChannel(liveCardChannel)
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

    private fun startLiveCardTracking() {
        Log.d(TAG, "Starting live card tracking")
        
        // Create foreground notification
        val notification = createForegroundNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(FOREGROUND_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
            startForeground(FOREGROUND_ID, notification)
        }
        
        // Load active alarms from shared preferences or database
        loadActiveAlarms()
        
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

    private fun loadActiveAlarms() {
        // In a real implementation, load from SharedPreferences or database
        // For demo, we'll use mock data
        serviceScope.launch {
            // This would load active alarms from the Flutter app's data
            // For now, we'll just log that we're loading
            Log.d(TAG, "Loading active alarms from storage")
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
        
        val notification = NotificationCompat.Builder(this, LIVE_CARD_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("${alarmData.label} — เหลือ $formattedDistance")
            .setContentText("จุดเตือน: ${formatRadius(alarmData.radius)} | ETA ~$eta")
            .setOngoing(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_NAVIGATION)
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
        activeAlarms.remove(alarmId)
        clearLiveCard(alarmId)
        
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
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
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
        return NotificationCompat.Action(android.R.drawable.ic_dialog_info, "Snooze 5m", pendingIntent)
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
        return NotificationCompat.Action(android.R.drawable.ic_dialog_info, "Hide today", pendingIntent)
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
        return NotificationCompat.Action(android.R.drawable.ic_dialog_info, "Stop", pendingIntent)
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
}