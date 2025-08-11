import 'package:geolocator/geolocator.dart';

class LocationService {
  
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Check if background location permission is granted (Android 10+)
  Future<bool> isBackgroundLocationGranted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always;
  }

  /// Request background location permission (Android 10+)
  Future<bool> requestBackgroundPermission() async {
    final currentPermission = await Geolocator.checkPermission();
    
    // If we don't have basic permission, request it first
    if (currentPermission == LocationPermission.denied ||
        currentPermission == LocationPermission.deniedForever) {
      return false;
    }

    // If we already have always permission, return true
    if (currentPermission == LocationPermission.always) {
      return true;
    }

    // For whileInUse permission, we need to guide user to settings
    // as requestPermission() won't show the always option again
    if (currentPermission == LocationPermission.whileInUse) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await _hasLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get current position with custom accuracy
  Future<Position?> getCurrentPositionWithAccuracy(LocationAccuracy accuracy) async {
    try {
      final hasPermission = await _hasLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get position stream for real-time tracking
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate bearing between two points
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Open device location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Check if we have sufficient location permission
  Future<bool> _hasLocationPermission() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permission = await checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Get location accuracy description
  String getAccuracyDescription(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.lowest:
        return 'Lowest (1-5 km)';
      case LocationAccuracy.low:
        return 'Low (500m)';
      case LocationAccuracy.medium:
        return 'Medium (100-500m)';
      case LocationAccuracy.high:
        return 'High (10-100m)';
      case LocationAccuracy.best:
        return 'Best (1-10m)';
      case LocationAccuracy.bestForNavigation:
        return 'Navigation (~1m)';
      default:
        return 'Unknown';
    }
  }

  /// Format position for display
  String formatPosition(Position position) {
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  /// Format distance for display
  static String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  /// Estimate time to reach destination
  String estimateTimeToReach(double distanceMeters, {double speedKmh = 5.0}) {
    final timeHours = distanceMeters / 1000 / speedKmh;
    final timeMinutes = (timeHours * 60).round();
    
    if (timeMinutes < 1) {
      return '< 1 min';
    } else if (timeMinutes < 60) {
      return '$timeMinutes min';
    } else {
      final hours = timeMinutes ~/ 60;
      final minutes = timeMinutes % 60;
      if (minutes == 0) {
        return '$hours h';
      } else {
        return '$hours h ${minutes}m';
      }
    }
  }
}