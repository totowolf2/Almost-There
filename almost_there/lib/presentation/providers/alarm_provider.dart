import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/alarm_model.dart';
import '../../data/models/location_model.dart';

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
    );

    await _repository.saveAlarm(alarm);
    _loadAlarms();
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