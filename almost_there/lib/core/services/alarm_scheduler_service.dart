import 'dart:async';
import 'package:flutter/services.dart';
import '../../data/models/alarm_model.dart';

class AlarmSchedulerService {
  static const MethodChannel _channel = MethodChannel('notification_alarm_service');
  
  static Future<void> scheduleAlarmActivation(AlarmModel alarm) async {
    if (alarm.startTime == null && !(alarm.isOneTime && alarm.isActive)) {
      print('⏰ [DEBUG] Alarm ${alarm.label} has no startTime and is not an active one-time alarm, skipping activation scheduling');
      return;
    }
    
    try {
      final now = DateTime.now();
      DateTime targetDateTime;
      
      if (alarm.startTime == null) {
        // Immediate activation for one-time alarms without specific start time
        targetDateTime = now.add(const Duration(seconds: 5)); // Small delay to allow processing
        print('⏰ [DEBUG] Scheduling immediate activation for ${alarm.label} at: ${targetDateTime.toString()}');
      } else {
        final startTime = alarm.startTime!;
        print('⏰ [DEBUG] Scheduling activation for ${alarm.label} with startTime: ${startTime.hour}:${startTime.minute}');
        
        // Calculate the target DateTime for today's start time
        targetDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          startTime.hour,
          startTime.minute,
        );
        
        // If the time has already passed today, schedule for tomorrow
        if (targetDateTime.isBefore(now)) {
          targetDateTime = targetDateTime.add(const Duration(days: 1));
          print('⏰ [DEBUG] Start time has passed today, scheduling for tomorrow: ${targetDateTime.toString()}');
        } else {
          print('⏰ [DEBUG] Scheduling for today: ${targetDateTime.toString()}');
        }
      }
      
      print('⏰ [DEBUG] Exact trigger time: ${targetDateTime.millisecondsSinceEpoch}');
      
      await _channel.invokeMethod('scheduleAlarmActivation', {
        'alarmId': alarm.id,
        'alarmLabel': alarm.label,
        'triggerTimeMillis': targetDateTime.millisecondsSinceEpoch,
      });
      
      print('⏰ [DEBUG] ✅ Successfully scheduled alarm activation using AlarmManager for ${alarm.label}');
    } catch (e) {
      print('⚠️ [WARNING] Failed to schedule alarm activation: $e');
    }
  }
  
  static Future<void> cancelAlarmActivation(String alarmId) async {
    try {
      await _channel.invokeMethod('cancelAlarmActivation', {
        'alarmId': alarmId,
      });
      print('⏰ [DEBUG] Cancelled alarm activation for: $alarmId');
    } catch (e) {
      print('⚠️ [WARNING] Failed to cancel alarm activation: $e');
    }
  }
}