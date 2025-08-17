import '../../data/models/alarm_model.dart';

/// Interface for alarm scheduling operations
abstract class AlarmScheduler {
  /// Schedule alarm activation at the specified time
  Future<bool> scheduleAlarmActivation(AlarmModel alarm);
  
  /// Cancel scheduled alarm activation
  Future<bool> cancelAlarmActivation(String alarmId);
  
  /// Get the next scheduled activation time for an alarm
  Future<DateTime?> getNextActivationTime(String alarmId);
  
  /// Check if alarm is currently scheduled
  Future<bool> isAlarmScheduled(String alarmId);
}