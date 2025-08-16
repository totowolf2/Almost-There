import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/notification_alarm_service.dart';
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
final alarmsProvider = StateNotifierProvider<AlarmsNotifier, List<AlarmModel>>((
  ref,
) {
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
  Timer? _startTimeCheckTimer;

  AlarmsNotifier(this._repository) : super([]) {
    _loadAlarms();
    _startPeriodicStartTimeCheck();
    _initializeBackgroundAlarmService();
  }

  @override
  void dispose() {
    _startTimeCheckTimer?.cancel();
    super.dispose();
  }

  void _loadAlarms() {
    state = _repository.getAllAlarms();
    // Check for alarms that should be activated immediately on app start
    Future.microtask(() => checkAndActivateScheduledAlarms());
  }

  void _startPeriodicStartTimeCheck() {
    // Check every 10 seconds for alarms that should be activated
    _startTimeCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      checkAndActivateScheduledAlarms();
    });
    print('🕐 [DEBUG] Started periodic start time check every 10 seconds');
  }

  void _initializeBackgroundAlarmService() {
    // Schedule all enabled alarms using native alarm service
    try {
      NotificationAlarmService.scheduleAllEnabledAlarms();
      print('🔧 [DEBUG] Native alarm service scheduled all alarms');
    } catch (e) {
      print('❌ [ERROR] Failed to schedule native alarms: $e');
      print('⚠️ [WARNING] Alarms will only work when app is open');
    }
  }

  bool _isStartTimePassed(TimeOfDay? startTime) {
    if (startTime == null) return true;
    
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    
    return currentMinutes >= startMinutes;
  }

  Future<void> checkAndActivateScheduledAlarms() async {
    await _checkAndActivateScheduledAlarmsInternal();
    
    // Check if we need to re-register geofences due to time window changes
    final currentActiveAlarms = state.where((alarm) => alarm.shouldTriggerToday()).length;
    print('🕐 [DEBUG] Currently active alarms that should trigger: $currentActiveAlarms');
    
    // If the time has passed and we have alarms that should now be active, re-register geofences
    if (currentActiveAlarms > 0) {
      print('🕐 [DEBUG] 🎯 Re-registering geofences due to active alarms');
      await _registerActiveGeofencesInternal();
    }
  }

  Future<void> _checkAndActivateScheduledAlarmsInternal() async {
    final now = DateTime.now();
    final currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    print('🕐 [DEBUG] Checking for alarms that should be activated now at $currentTime...');
    
    // Debug: Show all alarms with start times
    final alarmsWithStartTime = state.where((alarm) => alarm.startTime != null).toList();
    for (final alarm in alarmsWithStartTime) {
      print('🕐 [DEBUG] Alarm "${alarm.label}": startTime=${alarm.formattedStartTime}, enabled=${alarm.enabled}, isActive=${alarm.isActive}, shouldBeActivated=${alarm.shouldBeActivatedNow()}');
    }
    
    final alarmsToActivate = state.where((alarm) => alarm.shouldBeActivatedNow()).toList();
    
    for (final alarm in alarmsToActivate) {
      print('🕐 [DEBUG] 🎯 ACTIVATING alarm: ${alarm.label} at ${alarm.formattedStartTime}');
      
      final activatedAlarm = alarm.copyWith(isActive: true);
      await updateAlarm(activatedAlarm);
      
      // Re-register geofences to include the newly activated alarm
      await registerActiveGeofences();
    }
    
    if (alarmsToActivate.isNotEmpty) {
      print('🕐 [DEBUG] ✅ Activated ${alarmsToActivate.length} alarms');
    } else if (alarmsWithStartTime.isNotEmpty) {
      print('🕐 [DEBUG] ⏳ No alarms ready for activation yet');
    }
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
    TimeOfDay? startTime,
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
      startTimeMinutes: startTime != null ? (startTime.hour * 60 + startTime.minute) : null,
      // Set expiration for one-time alarms (24 hours)
      expiresAt: type == AlarmType.oneTime
          ? DateTime.now().add(const Duration(hours: 24))
          : null,
      // For one-time alarms: set active only if enabled and (no start time OR start time has passed)
      isActive: type == AlarmType.oneTime && enabled && (startTime == null || _isStartTimePassed(startTime)),
    );

    print(
      '📝 [DEBUG] Created alarm with isActive: ${alarm.isActive}, shouldTrigger: ${alarm.shouldTriggerToday()}',
    );

    await _repository.saveAlarm(alarm);
    _loadAlarms();

    // Schedule notification activation if alarm has startTime
    if (alarm.enabled && alarm.startTime != null) {
      try {
        await NotificationAlarmService.scheduleAlarmActivation(alarm);
        print('⏰ [DEBUG] Notification alarm scheduled for: ${alarm.label}');
      } catch (e) {
        print('⚠️ [WARNING] Failed to schedule notification alarm: $e');
      }
    }

    print('📝 [DEBUG] Alarm saved and loaded. Total alarms: ${state.length}');
  }

  Future<void> updateAlarm(AlarmModel alarm) async {
    print(
      '📝 [DEBUG] updateAlarm called for alarm: ${alarm.label}, enabled: ${alarm.enabled}',
    );

    // Update the state immediately for UI responsiveness
    final index = state.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      final updatedList = [...state];
      updatedList[index] = alarm;
      state = updatedList;
      print(
        '📝 [DEBUG] State updated immediately, alarm enabled: ${state[index].enabled}',
      );
    } else {
      print('📝 [ERROR] Could not find alarm with id: ${alarm.id}');
    }

    // Then save to database
    await _repository.saveAlarm(alarm);
    print('📝 [DEBUG] Alarm saved to database');

    // Handle notification scheduling for alarm
    try {
      await NotificationAlarmService.cancelAlarmActivation(alarm.id);
      if (alarm.enabled && alarm.startTime != null) {
        await NotificationAlarmService.scheduleAlarmActivation(alarm);
        print('⏰ [DEBUG] Notification alarm rescheduled for: ${alarm.label}');
      } else {
        print('⏰ [DEBUG] Notification alarm cancelled for: ${alarm.label}');
      }
    } catch (e) {
      print('⚠️ [WARNING] Failed to update notification alarm schedule: $e');
    }

    // Reload from database to ensure consistency
    _loadAlarms();
    print('📝 [DEBUG] Alarms reloaded from database');
  }

  Future<void> deleteAlarm(String alarmId) async {
    print('📝 [DEBUG] deleteAlarm called for alarm: $alarmId');

    // Update state immediately for UI responsiveness - remove from list
    final index = state.indexWhere((a) => a.id == alarmId);
    if (index != -1) {
      final updatedList = [...state];
      updatedList.removeAt(index);
      state = updatedList;
      print('📝 [DEBUG] Alarm removed from state immediately');
    } else {
      print('📝 [ERROR] Could not find alarm with id: $alarmId');
    }

    // Cancel notification scheduling for deleted alarm
    try {
      await NotificationAlarmService.cancelAlarmActivation(alarmId);
      print('⏰ [DEBUG] Notification alarm cancelled for deleted alarm: $alarmId');
    } catch (e) {
      print('⚠️ [WARNING] Failed to cancel notification alarm: $e');
    }

    // Then delete from database
    await _repository.deleteAlarm(alarmId);
    print('📝 [DEBUG] Alarm deleted from database');

    // Reload from database to ensure consistency
    _loadAlarms();
    print('📝 [DEBUG] Alarms reloaded from database');
  }

  Future<void> deleteAlarms(List<String> alarmIds) async {
    print('📝 [DEBUG] deleteAlarms called for ${alarmIds.length} alarms');

    // Update state immediately for UI responsiveness - remove all selected alarms
    final updatedList = state
        .where((alarm) => !alarmIds.contains(alarm.id))
        .toList();
    state = updatedList;
    print(
      '📝 [DEBUG] ${alarmIds.length} alarms removed from state immediately',
    );

    // Then delete from database
    for (final id in alarmIds) {
      await _repository.deleteAlarm(id);
    }
    print('📝 [DEBUG] ${alarmIds.length} alarms deleted from database');

    // Reload from database to ensure consistency
    _loadAlarms();
    print('📝 [DEBUG] Alarms reloaded from database');
  }

  Future<void> toggleAlarm(String alarmId) async {
    final alarm = state.firstWhere((a) => a.id == alarmId);
    final updatedAlarm = alarm.copyWith(enabled: !alarm.enabled);

    // Update UI immediately
    final index = state.indexWhere((a) => a.id == alarmId);
    if (index != -1) {
      final updatedList = [...state];
      updatedList[index] = updatedAlarm;
      state = updatedList;
    }

    // Save to database
    await _repository.saveAlarm(updatedAlarm);
    _loadAlarms();
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
      await updateAlarm(alarm.copyWith(isActive: true, enabled: true));
    }
  }

  Future<void> triggerAlarm(String alarmId) async {
    final alarm = state.firstWhere((a) => a.id == alarmId);

    // Update last triggered time
    var updatedAlarm = alarm.copyWith(lastTriggeredAt: DateTime.now());

    // For one-time alarms, disable after triggering
    if (alarm.type == AlarmType.oneTime) {
      updatedAlarm = updatedAlarm.copyWith(enabled: false, isActive: false);
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
    // Debug: Show all alarms for live card eligibility
    for (final alarm in state) {
      print('📱 [DEBUG] Alarm "${alarm.label}": shouldTrigger=${alarm.shouldTriggerToday()}, showLiveCard=${alarm.showLiveCard}, enabled=${alarm.enabled}');
    }
    
    final liveCardAlarms = state
        .where((alarm) => alarm.shouldTriggerToday() && alarm.showLiveCard)
        .toList();

    print('📱 [DEBUG] startLiveCardTracking: Found ${liveCardAlarms.length} live card alarms');

    if (liveCardAlarms.isEmpty) {
      print('📱 [DEBUG] No live card alarms found, stopping service');
      // Ensure service is stopped when no alarms to track
      await stopLiveCardTracking();
      return true;
    }

    final alarmData = liveCardAlarms
        .map(
          (alarm) => {
            'id': alarm.id,
            'label': alarm.label,
            'latitude': alarm.location.latitude,
            'longitude': alarm.location.longitude,
            'radius': alarm.radius,
          },
        )
        .toList();

    return await GeofencingPlatform.startLiveCardService(alarmData);
  }

  // Stop live card tracking service
  Future<bool> stopLiveCardTracking() async {
    return await GeofencingPlatform.stopLiveCardService();
  }

  // Register geofences for active alarms
  Future<void> registerActiveGeofences() async {
    // First, check and activate any alarms that should be activated now
    await _checkAndActivateScheduledAlarmsInternal();
    await _registerActiveGeofencesInternal();
  }

  Future<void> _registerActiveGeofencesInternal() async {
    final activeAlarms = state
        .where((alarm) => alarm.shouldTriggerToday())
        .toList();
    print(
      '🎯 [DEBUG] registerActiveGeofences: Found ${activeAlarms.length} active alarms',
    );

    // Debug: Show details of all alarms
    for (final alarm in state) {
      print(
        '🎯 [DEBUG] Alarm "${alarm.label}": enabled=${alarm.enabled}, isActive=${alarm.isActive}, type=${alarm.type}, shouldTrigger=${alarm.shouldTriggerToday()}',
      );
      if (alarm.type == AlarmType.recurring) {
        final today = DateTime.now().weekday % 7;
        print(
          '🎯 [DEBUG] Recurring alarm "${alarm.label}": today=$today, recurringDays=${alarm.recurringDays}',
        );
      }
      if (alarm.type == AlarmType.oneTime) {
        print(
          '🎯 [DEBUG] OneTime alarm "${alarm.label}": isExpired=${alarm.isExpired}, expiresAt=${alarm.expiresAt}',
        );
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
        print(
          '🎯 [ERROR] Failed to register geofence for alarm: ${alarm.label}',
        );
      } else {
        print(
          '🎯 [DEBUG] Successfully registered geofence for alarm: ${alarm.label}',
        );
      }
    }
    
    // Start live card tracking after geofences are registered
    print('🎯 [DEBUG] Starting live card tracking after geofence registration...');
    await startLiveCardTracking();
  }

  // Check permissions and setup notifications
  Future<Map<String, bool>> checkPermissions() async {
    final hasLocation = await GeofencingPlatform.hasLocationPermission();
    final hasBackground =
        await GeofencingPlatform.hasBackgroundLocationPermission();
    final hasNotification =
        await GeofencingPlatform.hasNotificationPermission();

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
      print(
        '🧪 [DEBUG] Test alarm before activation: enabled=${testAlarm.enabled}, isActive=${testAlarm.isActive}, type=${testAlarm.type}',
      );
      await updateAlarm(testAlarm.copyWith(isActive: true));

      // Check the alarm again after update
      final updatedAlarm = state.firstWhere((a) => a.id == testAlarm.id);
      print(
        '🧪 [DEBUG] Test alarm after activation: enabled=${updatedAlarm.enabled}, isActive=${updatedAlarm.isActive}, shouldTrigger=${updatedAlarm.shouldTriggerToday()}',
      );
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

      print(
        '📍 [DEBUG] Current position: ${position.latitude}, ${position.longitude}',
      );

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
        radius: 300.0, // Very small radius for immediate testing
        enabled: true,
        showLiveCard: true,
      );

      // For one-time alarms, they're automatically activated in addAlarm
      final testAlarm = state.last; // Get the just-added alarm
      print(
        '🧪 [DEBUG] Test alarm created: enabled=${testAlarm.enabled}, isActive=${testAlarm.isActive}, type=${testAlarm.type}',
      );

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
