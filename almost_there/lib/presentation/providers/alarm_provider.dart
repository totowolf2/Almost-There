import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/alarm_model.dart';
import '../../data/models/location_model.dart';
import '../../data/services/location_service.dart';
import '../../platform/geofencing_platform.dart';

const _uuid = Uuid();

// Alarm repository provider
final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  return AlarmRepository();
});

// Alarms list provider - watches the Hive box
final alarmsProvider = StateNotifierProvider<AlarmsNotifier, List<AlarmModel>>((ref) {
  final repository = ref.watch(alarmRepositoryProvider);
  return AlarmsNotifier(repository);
});

// Active alarms provider - filters enabled alarms that should trigger
final activeAlarmsProvider = Provider<List<AlarmModel>>((ref) {
  final alarms = ref.watch(alarmsProvider);
  return alarms.where((alarm) => alarm.shouldTriggerToday()).toList();
});

// Live card alarms provider - filters alarms that should show live cards
final liveCardAlarmsProvider = Provider<List<AlarmModel>>((ref) {
  final activeAlarms = ref.watch(activeAlarmsProvider);
  return activeAlarms.where((alarm) => alarm.showLiveCard).toList();
});

class AlarmsNotifier extends StateNotifier<List<AlarmModel>> {
  final AlarmRepository _repository;

  AlarmsNotifier(this._repository) : super([]) {
    _loadAlarms();
  }

  void _loadAlarms() {
    state = _repository.getAllAlarms();
  }

  Future<void> addAlarm({
    required String label,
    required AlarmType type,
    required LocationModel location,
    double radius = 300.0,
    bool enabled = true,
    bool showLiveCard = true,
    String soundPath = 'default',
    int snoozeMinutes = 5,
    List<int> recurringDays = const [],
    String? groupName,
  }) async {
    print('📝 [DEBUG] Adding alarm: $label, type: $type, enabled: $enabled');
    
    final alarm = AlarmModel(
      id: _uuid.v4(),
      label: label,
      type: type,
      location: location,
      radius: radius,
      enabled: enabled,
      showLiveCard: showLiveCard,
      soundPath: soundPath,
      snoozeMinutes: snoozeMinutes,
      recurringDays: recurringDays,
      createdAt: DateTime.now(),
      groupName: groupName,
      // Set expiration for one-time alarms (24 hours)
      expiresAt: type == AlarmType.oneTime 
          ? DateTime.now().add(const Duration(hours: 24))
          : null,
      // For one-time alarms that are enabled, automatically set isActive = true
      isActive: type == AlarmType.oneTime && enabled,
    );

    print('📝 [DEBUG] Created alarm with isActive: ${alarm.isActive}, shouldTrigger: ${alarm.shouldTriggerToday()}');
    
    await _repository.saveAlarm(alarm);
    _loadAlarms();
    
    print('📝 [DEBUG] Alarm saved and loaded. Total alarms: ${state.length}');
  }

  Future<void> updateAlarm(AlarmModel alarm) async {
    await _repository.saveAlarm(alarm);
    _loadAlarms();
  }

  Future<void> deleteAlarm(String alarmId) async {
    await _repository.deleteAlarm(alarmId);
    _loadAlarms();
  }

  Future<void> deleteAlarms(List<String> alarmIds) async {
    for (final id in alarmIds) {
      await _repository.deleteAlarm(id);
    }
    _loadAlarms();
  }

  Future<void> toggleAlarm(String alarmId) async {
    final alarm = state.firstWhere((a) => a.id == alarmId);
    final updatedAlarm = alarm.copyWith(enabled: !alarm.enabled);
    await updateAlarm(updatedAlarm);
  }

  Future<void> enableAlarms(List<String> alarmIds) async {
    for (final id in alarmIds) {
      final alarm = state.firstWhere((a) => a.id == id);
      await updateAlarm(alarm.copyWith(enabled: true));
    }
    _loadAlarms();
  }

  Future<void> disableAlarms(List<String> alarmIds) async {
    for (final id in alarmIds) {
      final alarm = state.firstWhere((a) => a.id == id);
      await updateAlarm(alarm.copyWith(enabled: false));
    }
    _loadAlarms();
  }

  Future<void> activateOneTimeAlarm(String alarmId) async {
    final alarm = state.firstWhere((a) => a.id == alarmId);
    if (alarm.type == AlarmType.oneTime) {
      await updateAlarm(alarm.copyWith(
        isActive: true,
        enabled: true,
      ));
    }
  }

  Future<void> triggerAlarm(String alarmId) async {
    final alarm = state.firstWhere((a) => a.id == alarmId);
    
    // Update last triggered time
    var updatedAlarm = alarm.copyWith(
      lastTriggeredAt: DateTime.now(),
    );

    // For one-time alarms, disable after triggering
    if (alarm.type == AlarmType.oneTime) {
      updatedAlarm = updatedAlarm.copyWith(
        enabled: false,
        isActive: false,
      );
    }

    await updateAlarm(updatedAlarm);
  }

  Future<void> duplicateAlarm(String alarmId) async {
    final original = state.firstWhere((a) => a.id == alarmId);
    final duplicate = AlarmModel(
      id: _uuid.v4(),
      label: '${original.label} (Copy)',
      type: original.type,
      location: original.location,
      radius: original.radius,
      enabled: false, // Duplicates start disabled
      showLiveCard: original.showLiveCard,
      soundPath: original.soundPath,
      snoozeMinutes: original.snoozeMinutes,
      recurringDays: original.recurringDays,
      createdAt: DateTime.now(),
      groupName: original.groupName,
      expiresAt: original.type == AlarmType.oneTime 
          ? DateTime.now().add(const Duration(hours: 24))
          : null,
    );

    await _repository.saveAlarm(duplicate);
    _loadAlarms();
  }

  // Cleanup expired one-time alarms
  Future<void> cleanupExpiredAlarms() async {
    final expiredAlarms = state.where((alarm) => alarm.isExpired).toList();
    for (final alarm in expiredAlarms) {
      await _repository.deleteAlarm(alarm.id);
    }
    if (expiredAlarms.isNotEmpty) {
      _loadAlarms();
    }
  }

  // Start live card tracking service
  Future<bool> startLiveCardTracking() async {
    final liveCardAlarms = state
        .where((alarm) => alarm.shouldTriggerToday() && alarm.showLiveCard)
        .toList();
    
    if (liveCardAlarms.isEmpty) {
      return true; // No alarms to track
    }

    final alarmData = liveCardAlarms.map((alarm) => {
      'id': alarm.id,
      'label': alarm.label,
      'latitude': alarm.location.latitude,
      'longitude': alarm.location.longitude,
      'radius': alarm.radius,
    }).toList();

    return await GeofencingPlatform.startLiveCardService(alarmData);
  }

  // Stop live card tracking service
  Future<bool> stopLiveCardTracking() async {
    return await GeofencingPlatform.stopLiveCardService();
  }

  // Register geofences for active alarms
  Future<void> registerActiveGeofences() async {
    final activeAlarms = state.where((alarm) => alarm.shouldTriggerToday()).toList();
    print('🎯 [DEBUG] registerActiveGeofences: Found ${activeAlarms.length} active alarms');
    
    // Debug: Show details of all alarms
    for (final alarm in state) {
      print('🎯 [DEBUG] Alarm "${alarm.label}": enabled=${alarm.enabled}, isActive=${alarm.isActive}, type=${alarm.type}, shouldTrigger=${alarm.shouldTriggerToday()}');
      if (alarm.type == AlarmType.recurring) {
        final today = DateTime.now().weekday % 7;
        print('🎯 [DEBUG] Recurring alarm "${alarm.label}": today=$today, recurringDays=${alarm.recurringDays}');
      }
      if (alarm.type == AlarmType.oneTime) {
        print('🎯 [DEBUG] OneTime alarm "${alarm.label}": isExpired=${alarm.isExpired}, expiresAt=${alarm.expiresAt}');
      }
    }
    
    // First remove all existing geofences
    print('🎯 [DEBUG] Removing all existing geofences...');
    await GeofencingPlatform.removeAllGeofences();
    
    // Register new geofences for active alarms
    for (final alarm in activeAlarms) {
      print('🎯 [DEBUG] Registering geofence for alarm: ${alarm.label}');
      final success = await GeofencingPlatform.addGeofence(
        alarmId: alarm.id,
        latitude: alarm.location.latitude,
        longitude: alarm.location.longitude,
        radius: alarm.radius,
        expirationDuration: alarm.type == AlarmType.oneTime 
            ? 86400000 // 24 hours in milliseconds
            : null, // Never expire for recurring alarms
      );
      
      if (!success) {
        print('🎯 [ERROR] Failed to register geofence for alarm: ${alarm.label}');
      } else {
        print('🎯 [DEBUG] Successfully registered geofence for alarm: ${alarm.label}');
      }
    }
  }

  // Check permissions and setup notifications
  Future<Map<String, bool>> checkPermissions() async {
    final hasLocation = await GeofencingPlatform.hasLocationPermission();
    final hasBackground = await GeofencingPlatform.hasBackgroundLocationPermission();
    final hasNotification = await GeofencingPlatform.hasNotificationPermission();
    
    return {
      'location': hasLocation,
      'background': hasBackground,
      'notification': hasNotification,
    };
  }

  // Test function to create a test alarm for debugging
  Future<void> createTestAlarm() async {
    print('🧪 [DEBUG] Starting createTestAlarm...');
    
    try {
      print('🧪 [DEBUG] Adding test alarm...');
      await addAlarm(
        label: 'ทดสอบแจ้งเตือน',
        type: AlarmType.oneTime,
        location: LocationModel(
          latitude: 13.7563, // Bangkok coordinates
          longitude: 100.5018,
          address: 'กรุงเทพมหานคร',
        ),
        radius: 100.0, // Small radius for testing
        enabled: true,
        showLiveCard: true,
      );
      
      // For one-time alarms, need to activate them manually
      final testAlarm = state.last; // Get the just-added alarm
      print('🧪 [DEBUG] Test alarm before activation: enabled=${testAlarm.enabled}, isActive=${testAlarm.isActive}, type=${testAlarm.type}');
      await updateAlarm(testAlarm.copyWith(isActive: true));
      
      // Check the alarm again after update
      final updatedAlarm = state.firstWhere((a) => a.id == testAlarm.id);
      print('🧪 [DEBUG] Test alarm after activation: enabled=${updatedAlarm.enabled}, isActive=${updatedAlarm.isActive}, shouldTrigger=${updatedAlarm.shouldTriggerToday()}');
      print('🧪 [DEBUG] Test alarm added successfully');
      
      // Register geofences after adding test alarm
      print('🧪 [DEBUG] Registering geofences...');
      await registerActiveGeofences();
      print('🧪 [DEBUG] Geofences registered');
      
      // Start live tracking
      print('🧪 [DEBUG] Starting live card tracking...');
      final result = await startLiveCardTracking();
      print('🧪 [DEBUG] Live card tracking result: $result');
      
      print('🧪 [DEBUG] createTestAlarm completed successfully');
    } catch (e) {
      print('🧪 [ERROR] createTestAlarm failed: $e');
      rethrow;
    }
  }

  Future<void> createTestAlarmAtCurrentLocation() async {
    print('🧪 [DEBUG] Starting createTestAlarmAtCurrentLocation...');
    
    try {
      // Get current location
      print('📍 [DEBUG] Getting current location...');
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      
      if (position == null) {
        throw Exception('ไม่สามารถหาตำแหน่งปัจจุบันได้');
      }
      
      print('📍 [DEBUG] Current position: ${position.latitude}, ${position.longitude}');
      
      // Create test alarm at current location
      print('🧪 [DEBUG] Adding test alarm at current location...');
      await addAlarm(
        label: 'ทดสอบแจ้งเตือนตรงนี้',
        type: AlarmType.oneTime,
        location: LocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          address: 'ตำแหน่งปัจจุบัน',
        ),
        radius: 50.0, // Very small radius for immediate testing
        enabled: true,
        showLiveCard: true,
      );
      
      // For one-time alarms, they're automatically activated in addAlarm
      final testAlarm = state.last; // Get the just-added alarm
      print('🧪 [DEBUG] Test alarm created: enabled=${testAlarm.enabled}, isActive=${testAlarm.isActive}, type=${testAlarm.type}');
      
      // Register geofences after adding test alarm
      print('🧪 [DEBUG] Registering geofences...');
      await registerActiveGeofences();
      print('🧪 [DEBUG] Geofences registered');
      
      // Start live tracking
      print('🧪 [DEBUG] Starting live card tracking...');
      final trackingResult = await startLiveCardTracking();
      print('🧪 [DEBUG] Live tracking result: $trackingResult');
      
      print('🧪 [DEBUG] Test alarm at current location created successfully!');
    } catch (e, stackTrace) {
      print('❌ [ERROR] Failed to create test alarm at current location: $e');
      print('❌ [STACKTRACE] $stackTrace');
      rethrow;
    }
  }
}

class AlarmRepository {
  Box<AlarmModel> get _alarmBox => Hive.box<AlarmModel>('alarms');

  List<AlarmModel> getAllAlarms() {
    return _alarmBox.values.toList();
  }

  Future<void> saveAlarm(AlarmModel alarm) async {
    await _alarmBox.put(alarm.id, alarm);
  }

  Future<void> deleteAlarm(String alarmId) async {
    await _alarmBox.delete(alarmId);
  }

  AlarmModel? getAlarm(String alarmId) {
    return _alarmBox.get(alarmId);
  }

  List<AlarmModel> getAlarmsByGroup(String groupName) {
    return _alarmBox.values
        .where((alarm) => alarm.groupName == groupName)
        .toList();
  }

  List<String> getAllGroups() {
    final groups = <String>{};
    for (final alarm in _alarmBox.values) {
      if (alarm.groupName != null) {
        groups.add(alarm.groupName!);
      }
    }
    return groups.toList()..sort();
  }
}