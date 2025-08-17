import '../domain/gateways/geofence_registrar.dart';
import '../data/models/alarm_model.dart';
import '../platform/geofencing_platform.dart';

/// Implementation of GeofenceRegistrar that wraps the existing GeofencingPlatform
class PlatformGeofenceRegistrar implements GeofenceRegistrar {
  
  @override
  Future<bool> registerGeofence(AlarmModel alarm) async {
    return await GeofencingPlatform.addGeofence(
      alarmId: alarm.id,
      latitude: alarm.location.latitude,
      longitude: alarm.location.longitude,
      radius: alarm.radius,
    );
  }
  
  @override
  Future<bool> unregisterGeofence(String alarmId) async {
    return await GeofencingPlatform.removeGeofence(alarmId);
  }
  
  @override
  Future<bool> unregisterAllGeofences() async {
    return await GeofencingPlatform.removeAllGeofences();
  }
  
  @override
  Future<List<String>> getRegisteredGeofences() async {
    // The existing platform doesn't provide this functionality
    // This would need to be implemented by maintaining a local registry
    // or querying the platform for active geofences
    return [];
  }
  
  @override
  Future<bool> isGeofenceRegistered(String alarmId) async {
    // The existing platform doesn't provide this functionality
    // This would need to be implemented by querying the platform
    // or maintaining a local registry
    return false;
  }
  
  @override
  Future<bool> hasLocationPermissions() async {
    return await GeofencingPlatform.hasLocationPermission();
  }
  
  @override
  Future<bool> hasBackgroundLocationPermissions() async {
    return await GeofencingPlatform.hasBackgroundLocationPermission();
  }
}