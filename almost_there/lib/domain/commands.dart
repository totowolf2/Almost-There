import '../../data/models/alarm_model.dart';

/// Base command interface for orchestrator
abstract class SchedulingCommand {}

/// Command to handle geofence entry events
class GeofenceEnteredCommand implements SchedulingCommand {
  final String alarmId;
  final DateTime entryTime;
  
  const GeofenceEnteredCommand({
    required this.alarmId,
    required this.entryTime,
  });
}

/// Command to handle geofence exit events  
class GeofenceExitedCommand implements SchedulingCommand {
  final String alarmId;
  final DateTime exitTime;
  
  const GeofenceExitedCommand({
    required this.alarmId,
    required this.exitTime,
  });
}

/// Command to reconcile system state (boot, permissions, settings changes)
class ReconcileCommand implements SchedulingCommand {
  final ReconcileReason reason;
  
  const ReconcileCommand({required this.reason});
}

enum ReconcileReason {
  boot,
  permissionChanged,
  settingsChanged,
  alarmUpdated,
  manualSync,
}

/// Command to schedule alarm activation
class ScheduleAlarmCommand implements SchedulingCommand {
  final AlarmModel alarm;
  final bool force;
  
  const ScheduleAlarmCommand({
    required this.alarm,
    this.force = false,
  });
}

/// Command to cancel alarm scheduling
class CancelAlarmCommand implements SchedulingCommand {
  final String alarmId;
  
  const CancelAlarmCommand({required this.alarmId});
}

/// Command to update alarm state
class UpdateAlarmStateCommand implements SchedulingCommand {
  final String alarmId;
  final AlarmState newState;
  
  const UpdateAlarmStateCommand({
    required this.alarmId,
    required this.newState,
  });
}

enum AlarmState {
  active,
  inactive, 
  triggered,
  bypassed,
  suspended,
}