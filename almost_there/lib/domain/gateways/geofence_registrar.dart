import '../../data/models/alarm_model.dart';

/// Interface for geofence management operations
abstract class GeofenceRegistrar {
  /// Register geofences for active alarms
  Future<bool> registerGeofence(AlarmModel alarm);
  
  /// Unregister geofence for specific alarm
  Future<bool> unregisterGeofence(String alarmId);
  
  /// Unregister all geofences
  Future<bool> unregisterAllGeofences();
  
  /// Get list of currently registered geofence IDs
  Future<List<String>> getRegisteredGeofences();
  
  /// Check if geofence is registered for alarm
  Future<bool> isGeofenceRegistered(String alarmId);
  
  /// Check location permissions
  Future<bool> hasLocationPermissions();
  
  /// Check background location permissions
  Future<bool> hasBackgroundLocationPermissions();
}