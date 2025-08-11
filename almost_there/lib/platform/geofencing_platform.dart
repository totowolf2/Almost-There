import 'package:flutter/services.dart';

class GeofencingPlatform {
  static const MethodChannel _channel = MethodChannel('com.example.almost_there/geofencing');

  /// Add a geofence for the given alarm
  static Future<bool> addGeofence({
    required String alarmId,
    required double latitude,
    required double longitude,
    required double radius,
    int? expirationDuration,
  }) async {
    try {
      print('🌍 [DEBUG] Adding geofence for alarm: $alarmId at ($latitude, $longitude) radius: ${radius}m');
      final result = await _channel.invokeMethod('addGeofence', {
        'alarmId': alarmId,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'expirationDuration': expirationDuration,
      });
      print('🌍 [DEBUG] Geofence add result: $result');
      return result == true;
    } catch (e) {
      print('🌍 [ERROR] Error adding geofence: $e');
      return false;
    }
  }

  /// Remove a geofence for the given alarm
  static Future<bool> removeGeofence(String alarmId) async {
    try {
      final result = await _channel.invokeMethod('removeGeofence', {
        'alarmId': alarmId,
      });
      return result == true;
    } catch (e) {
      print('Error removing geofence: $e');
      return false;
    }
  }

  /// Remove all geofences
  static Future<bool> removeAllGeofences() async {
    try {
      final result = await _channel.invokeMethod('removeAllGeofences');
      return result == true;
    } catch (e) {
      print('Error removing all geofences: $e');
      return false;
    }
  }

  /// Check if the app has location permission
  static Future<bool> hasLocationPermission() async {
    try {
      final result = await _channel.invokeMethod('hasLocationPermission');
      return result == true;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  /// Check if the app has background location permission
  static Future<bool> hasBackgroundLocationPermission() async {
    try {
      final result = await _channel.invokeMethod('hasBackgroundLocationPermission');
      return result == true;
    } catch (e) {
      print('Error checking background location permission: $e');
      return false;
    }
  }

  /// Check if the app has notification permission (Android 13+)
  static Future<bool> hasNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod('hasNotificationPermission');
      return result == true;
    } catch (e) {
      print('Error checking notification permission: $e');
      return false;
    }
  }

  /// Start live card tracking service
  static Future<bool> startLiveCardService(List<Map<String, dynamic>> alarms) async {
    try {
      print('📱 [DEBUG] Starting live card service with ${alarms.length} alarms');
      print('📱 [DEBUG] Alarm data: $alarms');
      final result = await _channel.invokeMethod('startLiveCardService', {
        'alarms': alarms,
      });
      print('📱 [DEBUG] Live card service start result: $result');
      return result == true;
    } catch (e) {
      print('📱 [ERROR] Error starting live card service: $e');
      return false;
    }
  }

  /// Stop live card tracking service
  static Future<bool> stopLiveCardService() async {
    try {
      final result = await _channel.invokeMethod('stopLiveCardService');
      return result == true;
    } catch (e) {
      print('Error stopping live card service: $e');
      return false;
    }
  }
}