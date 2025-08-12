import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

import '../../../data/models/location_model.dart';
import '../../providers/location_provider.dart';
import '../../theme/color_schemes.dart';
import '../../widgets/radius_slider.dart';

class MapPickerScreen extends ConsumerStatefulWidget {
  final LocationModel? initialLocation;
  final double initialRadius;

  const MapPickerScreen({
    super.key,
    this.initialLocation,
    this.initialRadius = 300.0,
  });

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  late MapController _mapController;
  late LatLng _selectedLocation;
  late double _selectedRadius;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedRadius = widget.initialRadius;

    // Set initial location or use Bangkok as default
    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
    } else {
      _selectedLocation = const LatLng(13.7563, 100.5018); // Bangkok
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorExtension = Theme.of(context).extension<AppColorExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกตำแหน่ง'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToCurrentLocation,
            tooltip: 'ไปยังตำแหน่งปัจจุบัน',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'ค้นหาสถานที่...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.clear),
              ),
              onSubmitted: _performSearch,
            ),
          ),

          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 15.0,
                minZoom: 5.0,
                maxZoom: 18.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedLocation = point;
                  });
                },
              ),
              children: [
                // OSM Tile Layer
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.vaas.almost_there',
                  maxZoom: 19,
                ),

                // Geofence circle
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selectedLocation,
                      radius: _selectedRadius,
                      useRadiusInMeter: true,
                      color: colorExtension.geofenceFill,
                      borderColor: colorExtension.geofenceStroke,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),

                // Center marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Radius slider
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'รัศมีการแจ้งเตือน: ${_formatRadius(_selectedRadius)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                RadiusSlider(
                  value: _selectedRadius,
                  onChanged: (value) {
                    setState(() {
                      _selectedRadius = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Location info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'พิกัดที่เลือก:',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          color: colorExtension.distanceText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ยกเลิก'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmLocation,
                    child: const Text('ยืนยัน'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goToCurrentLocation() async {
    final currentLocationAsync = ref.read(currentLocationProvider);

    currentLocationAsync.whenOrNull(
      data: (location) {
        if (location != null) {
          setState(() {
            _selectedLocation = LatLng(location.latitude, location.longitude);
          });
          _mapController.move(_selectedLocation, 16.0);
        }
      },
    );

    // Refresh current location
    ref.read(currentLocationProvider.notifier).refreshLocation();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('กำลังค้นหา...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Perform geocoding
      List<Location> locations = await locationFromAddress(query);

      if (!mounted) return;

      if (locations.isNotEmpty) {
        final location = locations.first;
        final newLocation = LatLng(location.latitude, location.longitude);

        setState(() {
          _selectedLocation = newLocation;
        });

        // Move map to the found location
        _mapController.move(newLocation, 16.0);

        // Clear the search field
        _searchController.clear();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('พบสถานที่แล้ว!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show not found message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบสถานที่ที่ค้นหา กรุณาลองใหม่'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการค้นหา: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmLocation() {
    final selectedLocationModel = LocationModel(
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
    );

    Navigator.of(
      context,
    ).pop({'location': selectedLocationModel, 'radius': _selectedRadius});
  }

  String _formatRadius(double radius) {
    if (radius >= 1000) {
      return '${(radius / 1000).toStringAsFixed(1)} กม.';
    }
    return '${radius.toInt()} ม.';
  }
}
