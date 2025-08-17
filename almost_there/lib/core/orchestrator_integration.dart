import '../domain/scheduling_orchestrator.dart';
import '../domain/policy/holiday_policy.dart';
import '../domain/commands.dart';
import '../data/services/holiday_service.dart';
import '../infrastructure/holiday_service_repository.dart';
import '../infrastructure/platform_alarm_scheduler.dart';
import '../infrastructure/platform_geofence_registrar.dart';

/// Integration layer that sets up and manages the SchedulingOrchestrator
class OrchestratorIntegration {
  static SchedulingOrchestrator? _instance;
  
  /// Get the singleton orchestrator instance
  static SchedulingOrchestrator get instance {
    _instance ??= _createOrchestrator();
    return _instance!;
  }
  
  /// Create orchestrator with all dependencies wired up
  static SchedulingOrchestrator _createOrchestrator() {
    // Create repository implementations
    final holidayRepository = HolidayServiceRepository(HolidayService());
    final holidayPolicy = CalendarHolidayPolicy(holidayRepository);
    final alarmScheduler = PlatformAlarmScheduler();
    final geofenceRegistrar = PlatformGeofenceRegistrar();
    
    return SchedulingOrchestrator(
      holidayPolicy: holidayPolicy,
      alarmScheduler: alarmScheduler,
      geofenceRegistrar: geofenceRegistrar,
    );
  }
  
  /// Handle geofence entry events
  static Future<void> onGeofenceEntered(String alarmId) async {
    await instance.execute(GeofenceEnteredCommand(
      alarmId: alarmId,
      entryTime: DateTime.now(),
    ));
  }
  
  /// Handle geofence exit events
  static Future<void> onGeofenceExited(String alarmId) async {
    await instance.execute(GeofenceExitedCommand(
      alarmId: alarmId,
      exitTime: DateTime.now(),
    ));
  }
  
  /// Handle device boot
  static Future<void> onDeviceBoot() async {
    await instance.execute(const ReconcileCommand(
      reason: ReconcileReason.boot,
    ));
  }
  
  /// Handle permission changes
  static Future<void> onPermissionChanged() async {
    await instance.execute(const ReconcileCommand(
      reason: ReconcileReason.permissionChanged,
    ));
  }
  
  /// Handle settings changes
  static Future<void> onSettingsChanged() async {
    await instance.execute(const ReconcileCommand(
      reason: ReconcileReason.settingsChanged,
    ));
  }
  
  /// Schedule alarm through orchestrator
  static Future<void> scheduleAlarm(dynamic alarm) async {
    await instance.execute(ScheduleAlarmCommand(
      alarm: alarm,
    ));
  }
  
  /// Cancel alarm through orchestrator
  static Future<void> cancelAlarm(String alarmId) async {
    await instance.execute(CancelAlarmCommand(
      alarmId: alarmId,
    ));
  }
  
  /// Get system state for debugging
  static Future<Map<String, dynamic>> getSystemState() async {
    return await instance.getSystemState();
  }
  
  /// Reset the orchestrator instance (for testing)
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}