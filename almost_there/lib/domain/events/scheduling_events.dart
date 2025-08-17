/// Base event class for scheduling system
abstract class SchedulingEvent {}

/// Event emitted when alarm is successfully scheduled
class AlarmScheduledEvent implements SchedulingEvent {
  final String alarmId;
  final DateTime scheduledFor;
  final String reason;
  
  const AlarmScheduledEvent({
    required this.alarmId,
    required this.scheduledFor,
    required this.reason,
  });
}

/// Event emitted when alarm scheduling is skipped/bypassed
class AlarmBypassedEvent implements SchedulingEvent {
  final String alarmId;
  final BypassReason reason;
  final DateTime timestamp;
  
  const AlarmBypassedEvent({
    required this.alarmId,
    required this.reason,
    required this.timestamp,
  });
}

enum BypassReason {
  holiday,
  outsideWorkHours,
  permissionDenied,
  alarmInactive,
  manualOverride,
}

/// Event emitted when geofence is registered/unregistered
class GeofenceRegistrationEvent implements SchedulingEvent {
  final String alarmId;
  final bool registered;
  final String? error;
  
  const GeofenceRegistrationEvent({
    required this.alarmId,
    required this.registered,
    this.error,
  });
}

/// Event emitted when system state changes require reconciliation
class SystemStateChangedEvent implements SchedulingEvent {
  final String reason;
  final DateTime timestamp;
  
  const SystemStateChangedEvent({
    required this.reason,
    required this.timestamp,
  });
}

/// Event emitted when holiday policy state changes
class HolidayPolicyUpdatedEvent implements SchedulingEvent {
  final String policyInfo;
  final int holidaysLoaded;
  
  const HolidayPolicyUpdatedEvent({
    required this.policyInfo,
    required this.holidaysLoaded,
  });
}