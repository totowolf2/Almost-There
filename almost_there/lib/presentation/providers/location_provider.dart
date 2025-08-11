import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/location_model.dart';
import '../../data/services/location_service.dart';

// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// Current location provider
final currentLocationProvider = StateNotifierProvider<CurrentLocationNotifier, AsyncValue<LocationModel?>>((ref) {
  final service = ref.watch(locationServiceProvider);
  return CurrentLocationNotifier(service);
});

// Location permissions provider
final locationPermissionsProvider = StateNotifierProvider<LocationPermissionsNotifier, LocationPermissionStatus>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationPermissionsNotifier(service);
});

// Distance tracking provider for live cards
final distanceTrackingProvider = StateNotifierProvider<DistanceTrackingNotifier, Map<String, double>>((ref) {
  final service = ref.watch(locationServiceProvider);
  return DistanceTrackingNotifier(service);
});

class LocationPermissionStatus {
  final bool isLocationEnabled;
  final LocationPermission permission;
  final bool backgroundLocationGranted;
  
  const LocationPermissionStatus({
    required this.isLocationEnabled,
    required this.permission,
    required this.backgroundLocationGranted,
  });

  bool get hasBasicPermission => 
      isLocationEnabled && 
      (permission == LocationPermission.always || 
       permission == LocationPermission.whileInUse);

  bool get hasFullPermission => 
      hasBasicPermission && backgroundLocationGranted;

  bool get canRequestBackground => 
      hasBasicPermission && !backgroundLocationGranted;

  LocationPermissionStatus copyWith({
    bool? isLocationEnabled,
    LocationPermission? permission,
    bool? backgroundLocationGranted,
  }) {
    return LocationPermissionStatus(
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
      permission: permission ?? this.permission,
      backgroundLocationGranted: backgroundLocationGranted ?? this.backgroundLocationGranted,
    );
  }
}

class CurrentLocationNotifier extends StateNotifier<AsyncValue<LocationModel?>> {
  final LocationService _service;

  CurrentLocationNotifier(this._service) : super(const AsyncValue.loading()) {
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      state = const AsyncValue.loading();
      final position = await _service.getCurrentPosition();
      if (position != null) {
        state = AsyncValue.data(LocationModel.fromPosition(position));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshLocation() async {
    await _getCurrentLocation();
  }

  Future<LocationModel?> getLocationWithAddress() async {
    try {
      final position = await _service.getCurrentPosition();
      if (position != null) {
        // In a real app, you might reverse geocode here
        final location = LocationModel.fromPosition(position);
        state = AsyncValue.data(location);
        return location;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
    return null;
  }
}

class LocationPermissionsNotifier extends StateNotifier<LocationPermissionStatus> {
  final LocationService _service;

  LocationPermissionsNotifier(this._service) : super(
    const LocationPermissionStatus(
      isLocationEnabled: false,
      permission: LocationPermission.denied,
      backgroundLocationGranted: false,
    ),
  ) {
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final isEnabled = await _service.isLocationServiceEnabled();
    final permission = await _service.checkPermission();
    final backgroundGranted = await _service.isBackgroundLocationGranted();

    state = LocationPermissionStatus(
      isLocationEnabled: isEnabled,
      permission: permission,
      backgroundLocationGranted: backgroundGranted,
    );
  }

  Future<bool> requestLocationPermission() async {
    try {
      final granted = await _service.requestPermission();
      await _checkPermissions();
      return granted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestBackgroundPermission() async {
    try {
      final granted = await _service.requestBackgroundPermission();
      await _checkPermissions();
      return granted;
    } catch (e) {
      return false;
    }
  }

  Future<void> openLocationSettings() async {
    await _service.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await _service.openAppSettings();
  }

  Future<void> checkPermissions() async {
    await _checkPermissions();
  }
}

class DistanceTrackingNotifier extends StateNotifier<Map<String, double>> {
  final LocationService _service;

  DistanceTrackingNotifier(this._service) : super({});

  Future<void> updateDistances(List<LocationModel> destinations) async {
    try {
      final currentPosition = await _service.getCurrentPosition();
      if (currentPosition == null) return;

      final newDistances = <String, double>{};
      
      for (final destination in destinations) {
        final distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          destination.latitude,
          destination.longitude,
        );
        
        // Use coordinates as key for now, could use alarm ID in real implementation
        final key = '${destination.latitude},${destination.longitude}';
        newDistances[key] = distance;
      }

      state = newDistances;
    } catch (e) {
      // Handle error silently for background tracking
    }
  }

  double? getDistance(LocationModel location) {
    final key = '${location.latitude},${location.longitude}';
    return state[key];
  }

  void clearDistances() {
    state = {};
  }
}