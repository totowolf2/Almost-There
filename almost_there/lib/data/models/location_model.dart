import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';

part 'location_model.g.dart';

@HiveType(typeId: 2)
class LocationModel extends HiveObject {
  @HiveField(0)
  double latitude;

  @HiveField(1)
  double longitude;

  @HiveField(2)
  String? address;

  @HiveField(3)
  String? name; // Custom name for the location

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
  });

  // Calculate distance to another location in meters
  double distanceTo(LocationModel other) {
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }

  // Calculate distance to coordinates in meters
  double distanceToCoordinates(double lat, double lon) {
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      lat,
      lon,
    );
  }

  // Format distance for display
  static String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  // Calculate bearing to another location
  double bearingTo(LocationModel other) {
    return Geolocator.bearingBetween(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }

  // Create from Position (geolocator)
  factory LocationModel.fromPosition(Position position, {String? address, String? name}) {
    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
      name: name,
    );
  }

  // Create copy with modifications
  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? name,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      name: name ?? this.name,
    );
  }

  // Convert to string for display
  String get displayName {
    return name ?? address ?? '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  String get coordinates {
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  @override
  String toString() {
    return 'LocationModel(lat: $latitude, lon: $longitude, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}