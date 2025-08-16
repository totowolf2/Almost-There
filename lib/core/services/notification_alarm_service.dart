import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/alarm_model.dart';

class NotificationAlarmService {
  static const MethodChannel _channel = MethodChannel('notification_alarm_service');
  
  static Future<void> scheduleAllEnabledAlarms() async {
    try {
      await _channel.invokeMethod('scheduleAllEnabledAlarms');
      print('🔧 [DEBUG] Native alarm service scheduled all alarms');
    } catch (e) {
      print('❌ [ERROR] Failed to schedule native alarms: $e');
      print('⚠️ [WARNING] Alarms will only work when app is open');
    }
  }
  
  static Future<void> scheduleAlarmActivation(AlarmModel alarm) async {
    if (alarm.startTime == null) return;
    
    try {
      final now = DateTime.now();
      final startTime = alarm.startTime!;
      
      // Calculate the target DateTime for today's start time
      var targetDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );
      
      // If the time has already passed today, schedule for tomorrow
      if (targetDateTime.isBefore(now)) {
        targetDateTime = targetDateTime.add(const Duration(days: 1));
      }
      
      final timeUntilActivation = targetDateTime.difference(now).inMilliseconds;
      
      await _channel.invokeMethod('scheduleAlarmActivation', {
        'alarmId': alarm.id,
        'alarmLabel': alarm.label,
        'triggerTimeMillis': targetDateTime.millisecondsSinceEpoch,
        'delayMillis': timeUntilActivation,
      });
      
      print('⏰ [DEBUG] Scheduled alarm activation for ${alarm.label} at ${targetDateTime.toString()}');
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
  
  static Future<void> startAlarmMonitoringService() async {
    try {
      await _channel.invokeMethod('startAlarmMonitoringService');
      print('🚀 [DEBUG] Started alarm monitoring foreground service');
    } catch (e) {
      print('❌ [ERROR] Failed to start alarm monitoring service: $e');
    }
  }
  
  static Future<void> stopAlarmMonitoringService() async {
    try {
      await _channel.invokeMethod('stopAlarmMonitoringService');
      print('🛑 [DEBUG] Stopped alarm monitoring service');
    } catch (e) {
      print('❌ [ERROR] Failed to stop alarm monitoring service: $e');
    }
  }
}