import '../domain/gateways/alarm_scheduler.dart';
import '../data/models/alarm_model.dart';
import '../core/services/alarm_scheduler_service.dart';

/// Implementation of AlarmScheduler that wraps the existing AlarmSchedulerService
class PlatformAlarmScheduler implements AlarmScheduler {
  
  @override
  Future<bool> scheduleAlarmActivation(AlarmModel alarm) async {
    try {
      await AlarmSchedulerService.scheduleAlarmActivation(alarm);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> cancelAlarmActivation(String alarmId) async {
    try {
      await AlarmSchedulerService.cancelAlarmActivation(alarmId);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<DateTime?> getNextActivationTime(String alarmId) async {
    // The existing service doesn't provide this functionality
    // This would need to be implemented by storing scheduled times
    // or querying the platform for scheduled alarms
    return null;
  }
  
  @override
  Future<bool> isAlarmScheduled(String alarmId) async {
    // The existing service doesn't provide this functionality
    // This would need to be implemented by querying the platform
    // or maintaining a local registry
    return false;
  }
}