import 'dart:async';
import '../data/models/alarm_model.dart';
import 'commands.dart';
import 'events/scheduling_events.dart';
import 'policy/holiday_policy.dart';
import 'gateways/alarm_scheduler.dart';
import 'gateways/geofence_registrar.dart';

/// Central orchestrator for alarm scheduling decisions
class SchedulingOrchestrator {
  final HolidayPolicy _holidayPolicy;
  final AlarmScheduler _alarmScheduler;
  final GeofenceRegistrar _geofenceRegistrar;
  
  final StreamController<SchedulingEvent> _eventController = 
      StreamController<SchedulingEvent>.broadcast();
  
  SchedulingOrchestrator({
    required HolidayPolicy holidayPolicy,
    required AlarmScheduler alarmScheduler,
    required GeofenceRegistrar geofenceRegistrar,
  }) : _holidayPolicy = holidayPolicy,
       _alarmScheduler = alarmScheduler,
       _geofenceRegistrar = geofenceRegistrar;

  /// Stream of scheduling events for monitoring
  Stream<SchedulingEvent> get events => _eventController.stream;

  /// Execute a scheduling command
  Future<void> execute(SchedulingCommand command) async {
    try {
      switch (command) {
        case GeofenceEnteredCommand cmd:
          await _handleGeofenceEntered(cmd);
        case GeofenceExitedCommand cmd:
          await _handleGeofenceExited(cmd);
        case ReconcileCommand cmd:
          await _handleReconcile(cmd);
        case ScheduleAlarmCommand cmd:
          await _handleScheduleAlarm(cmd);
        case CancelAlarmCommand cmd:
          await _handleCancelAlarm(cmd);
        case UpdateAlarmStateCommand cmd:
          await _handleUpdateAlarmState(cmd);
      }
    } catch (e) {
      // Log error and emit event
      _eventController.add(SystemStateChangedEvent(
        reason: 'Command execution failed: $e',
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _handleGeofenceEntered(GeofenceEnteredCommand cmd) async {
    final now = DateTime.now();
    
    // Check if today is a working day
    final isWorkingDay = await _holidayPolicy.isWorkingDay(now);
    
    if (!isWorkingDay) {
      _eventController.add(AlarmBypassedEvent(
        alarmId: cmd.alarmId,
        reason: BypassReason.holiday,
        timestamp: now,
      ));
      return;
    }
    
    // For geofence entry, we typically want to activate the alarm immediately
    // The actual alarm scheduling will be handled by the alarm system
    _eventController.add(AlarmScheduledEvent(
      alarmId: cmd.alarmId,
      scheduledFor: cmd.entryTime,
      reason: 'Geofence entered on working day',
    ));
  }

  Future<void> _handleGeofenceExited(GeofenceExitedCommand cmd) async {
    // Handle geofence exit - typically cancel any pending alarms
    await _alarmScheduler.cancelAlarmActivation(cmd.alarmId);
  }

  Future<void> _handleReconcile(ReconcileCommand cmd) async {
    // Reconcile system state based on reason
    switch (cmd.reason) {
      case ReconcileReason.boot:
        await _reconcileAfterBoot();
      case ReconcileReason.permissionChanged:
        await _reconcileAfterPermissionChange();
      case ReconcileReason.settingsChanged:
      case ReconcileReason.alarmUpdated:
      case ReconcileReason.manualSync:
        await _reconcileGeofences();
    }
    
    _eventController.add(SystemStateChangedEvent(
      reason: 'Reconciliation completed: ${cmd.reason}',
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _handleScheduleAlarm(ScheduleAlarmCommand cmd) async {
    final alarm = cmd.alarm;
    
    // Check if alarm should be scheduled based on current state
    if (!alarm.isActive && !cmd.force) {
      _eventController.add(AlarmBypassedEvent(
        alarmId: alarm.id,
        reason: BypassReason.alarmInactive,
        timestamp: DateTime.now(),
      ));
      return;
    }
    
    // Check holiday policy for start time if applicable
    if (alarm.startTime != null) {
      final startDateTime = _getNextStartDateTime(alarm);
      final isWorkingDay = await _holidayPolicy.isWorkingDay(startDateTime);
      
      if (!isWorkingDay) {
        _eventController.add(AlarmBypassedEvent(
          alarmId: alarm.id,
          reason: BypassReason.holiday,
          timestamp: DateTime.now(),
        ));
        return;
      }
    }
    
    // Schedule the alarm
    final success = await _alarmScheduler.scheduleAlarmActivation(alarm);
    
    if (success) {
      final nextActivation = await _alarmScheduler.getNextActivationTime(alarm.id);
      _eventController.add(AlarmScheduledEvent(
        alarmId: alarm.id,
        scheduledFor: nextActivation ?? DateTime.now(),
        reason: 'Manual schedule request',
      ));
    }
  }

  Future<void> _handleCancelAlarm(CancelAlarmCommand cmd) async {
    await _alarmScheduler.cancelAlarmActivation(cmd.alarmId);
  }

  Future<void> _handleUpdateAlarmState(UpdateAlarmStateCommand cmd) async {
    // Handle state changes that might affect scheduling
    switch (cmd.newState) {
      case AlarmState.active:
        // Re-evaluate scheduling for this alarm
        break;
      case AlarmState.inactive:
        // Cancel any scheduled activations
        await _alarmScheduler.cancelAlarmActivation(cmd.alarmId);
      case AlarmState.triggered:
      case AlarmState.bypassed:
      case AlarmState.suspended:
        // Handle other states as needed
        break;
    }
  }

  Future<void> _reconcileAfterBoot() async {
    // After device boot, re-register all necessary geofences
    await _reconcileGeofences();
    
    // Update holiday cache for current year
    await _holidayPolicy.isWorkingDay(DateTime.now());
  }

  Future<void> _reconcileAfterPermissionChange() async {
    final hasLocationPermission = await _geofenceRegistrar.hasLocationPermissions();
    final hasBackgroundPermission = await _geofenceRegistrar.hasBackgroundLocationPermissions();
    
    if (!hasLocationPermission || !hasBackgroundPermission) {
      // Permissions revoked, unregister all geofences
      await _geofenceRegistrar.unregisterAllGeofences();
      
      _eventController.add(SystemStateChangedEvent(
        reason: 'Location permissions revoked, geofences unregistered',
        timestamp: DateTime.now(),
      ));
    } else {
      // Permissions granted, re-register geofences
      await _reconcileGeofences();
    }
  }

  Future<void> _reconcileGeofences() async {
    // This would typically get active alarms from a repository
    // For now, we'll emit an event indicating reconciliation is needed
    _eventController.add(SystemStateChangedEvent(
      reason: 'Geofence reconciliation required',
      timestamp: DateTime.now(),
    ));
  }

  DateTime _getNextStartDateTime(AlarmModel alarm) {
    if (alarm.startTime == null) return DateTime.now();
    
    final now = DateTime.now();
    final startTime = alarm.startTime!;
    
    var targetDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      startTime.hour,
      startTime.minute,
    );
    
    // If time has passed today, schedule for tomorrow
    if (targetDateTime.isBefore(now)) {
      targetDateTime = targetDateTime.add(const Duration(days: 1));
    }
    
    return targetDateTime;
  }

  /// Get current system state for debugging
  Future<Map<String, dynamic>> getSystemState() async {
    return {
      'holidayPolicy': _holidayPolicy.policyState,
      'hasLocationPermissions': await _geofenceRegistrar.hasLocationPermissions(),
      'hasBackgroundPermissions': await _geofenceRegistrar.hasBackgroundLocationPermissions(),
      'registeredGeofences': await _geofenceRegistrar.getRegisteredGeofences(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
  }
}