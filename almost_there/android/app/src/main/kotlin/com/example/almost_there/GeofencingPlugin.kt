package com.example.almost_there

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import com.google.android.gms.location.*
import com.google.android.gms.tasks.Task
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class GeofencingPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    companion object {
        private const val CHANNEL = "com.example.almost_there/geofencing"
        private const val TAG = "GeofencingPlugin"
        private const val GEOFENCE_REQ_ID_PREFIX = "alarm_"
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var geofencingClient: GeofencingClient
    private var activityBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        geofencingClient = LocationServices.getGeofencingClient(context)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "addGeofence" -> addGeofence(call, result)
            "removeGeofence" -> removeGeofence(call, result)
            "removeAllGeofences" -> removeAllGeofences(result)
            "hasLocationPermission" -> hasLocationPermission(result)
            "hasBackgroundLocationPermission" -> hasBackgroundLocationPermission(result)
            "hasNotificationPermission" -> hasNotificationPermission(result)
            "startLiveCardService" -> startLiveCardService(call, result)
            "stopLiveCardService" -> stopLiveCardService(result)
            else -> result.notImplemented()
        }
    }

    private fun addGeofence(call: MethodCall, result: Result) {
        if (!checkLocationPermissions()) {
            result.error("PERMISSION_DENIED", "Location permissions not granted", null)
            return
        }

        try {
            val alarmId = call.argument<String>("alarmId") ?: ""
            val latitude = call.argument<Double>("latitude") ?: 0.0
            val longitude = call.argument<Double>("longitude") ?: 0.0
            val radius = call.argument<Double>("radius") ?: 100.0
            val expirationDuration = call.argument<Int>("expirationDuration")?.toLong() ?: Geofence.NEVER_EXPIRE

            val geofence = Geofence.Builder()
                .setRequestId(GEOFENCE_REQ_ID_PREFIX + alarmId)
                .setCircularRegion(latitude, longitude, radius.toFloat())
                .setExpirationDuration(expirationDuration)
                .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER)
                .build()

            val geofenceRequest = GeofencingRequest.Builder()
                .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
                .addGeofence(geofence)
                .build()

            geofencingClient.addGeofences(geofenceRequest, geofencePendingIntent)
                .addOnSuccessListener {
                    Log.d(TAG, "Geofence added successfully for alarm: $alarmId")
                    result.success(true)
                }
                .addOnFailureListener { exception ->
                    Log.e(TAG, "Failed to add geofence for alarm: $alarmId", exception)
                    result.error("GEOFENCE_ERROR", "Failed to add geofence: ${exception.message}", null)
                }
        } catch (e: Exception) {
            Log.e(TAG, "Error adding geofence", e)
            result.error("UNKNOWN_ERROR", e.message, null)
        }
    }

    private fun removeGeofence(call: MethodCall, result: Result) {
        try {
            val alarmId = call.argument<String>("alarmId") ?: ""
            val geofenceId = GEOFENCE_REQ_ID_PREFIX + alarmId

            geofencingClient.removeGeofences(listOf(geofenceId))
                .addOnSuccessListener {
                    Log.d(TAG, "Geofence removed successfully for alarm: $alarmId")
                    result.success(true)
                }
                .addOnFailureListener { exception ->
                    Log.e(TAG, "Failed to remove geofence for alarm: $alarmId", exception)
                    result.error("GEOFENCE_ERROR", "Failed to remove geofence: ${exception.message}", null)
                }
        } catch (e: Exception) {
            Log.e(TAG, "Error removing geofence", e)
            result.error("UNKNOWN_ERROR", e.message, null)
        }
    }

    private fun removeAllGeofences(result: Result) {
        try {
            geofencingClient.removeGeofences(geofencePendingIntent)
                .addOnSuccessListener {
                    Log.d(TAG, "All geofences removed successfully")
                    result.success(true)
                }
                .addOnFailureListener { exception ->
                    Log.e(TAG, "Failed to remove all geofences", exception)
                    result.error("GEOFENCE_ERROR", "Failed to remove all geofences: ${exception.message}", null)
                }
        } catch (e: Exception) {
            Log.e(TAG, "Error removing all geofences", e)
            result.error("UNKNOWN_ERROR", e.message, null)
        }
    }

    private fun hasLocationPermission(result: Result) {
        val hasPermission = ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        result.success(hasPermission)
    }

    private fun hasBackgroundLocationPermission(result: Result) {
        val hasPermission = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            // Background location is included in ACCESS_FINE_LOCATION on older versions
            true
        }
        result.success(hasPermission)
    }

    private fun checkLocationPermissions(): Boolean {
        val fineLocationGranted = ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        val backgroundLocationGranted = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }

        return fineLocationGranted && backgroundLocationGranted
    }

    private fun hasNotificationPermission(result: Result) {
        val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            // Notification permission is granted by default on older versions
            NotificationManagerCompat.from(context).areNotificationsEnabled()
        }
        result.success(hasPermission)
    }

    private fun startLiveCardService(call: MethodCall, result: Result) {
        try {
            val alarms = call.argument<List<Map<String, Any>>>("alarms")
            val intent = Intent(context, GeofencingService::class.java).apply {
                action = GeofencingService.ACTION_START_LIVE_CARDS
                if (alarms != null) {
                    putExtra("alarms", ArrayList(alarms))
                }
            }
            context.startForegroundService(intent)
            Log.d(TAG, "Started live card service with ${alarms?.size ?: 0} alarms")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting live card service", e)
            result.error("SERVICE_ERROR", "Failed to start live card service: ${e.message}", null)
        }
    }

    private fun stopLiveCardService(result: Result) {
        try {
            val intent = Intent(context, GeofencingService::class.java).apply {
                action = GeofencingService.ACTION_STOP_LIVE_CARDS
            }
            context.startService(intent)
            Log.d(TAG, "Stopped live card service")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping live card service", e)
            result.error("SERVICE_ERROR", "Failed to stop live card service: ${e.message}", null)
        }
    }

    private val geofencePendingIntent: PendingIntent by lazy {
        val intent = Intent(context, GeofenceReceiver::class.java)
        PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
    }
}