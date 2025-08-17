import 'dart:async';
import '../../domain/events/scheduling_events.dart';
import '../orchestrator_integration.dart';
import 'debug_logger.dart';

/// Service that listens to orchestrator events and provides user notifications
class UserNotificationService {
  static StreamSubscription<SchedulingEvent>? _eventSubscription;
  
  /// Start listening to orchestrator events
  static void startListening() {
    _eventSubscription?.cancel();
    
    _eventSubscription = OrchestratorIntegration.instance.events.listen(
      _handleSchedulingEvent,
      onError: (error) {
        DebugLogger.error('Error in notification service: $error');
      },
    );
    
    DebugLogger.info('User notification service started');
  }
  
  /// Stop listening to orchestrator events
  static void stopListening() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    DebugLogger.info('User notification service stopped');
  }
  
  /// Handle scheduling events
  static void _handleSchedulingEvent(SchedulingEvent event) {
    switch (event) {
      case AlarmScheduledEvent scheduledEvent:
        _notifyAlarmScheduled(scheduledEvent);
      case AlarmBypassedEvent bypassedEvent:
        _notifyAlarmBypassed(bypassedEvent);
      case GeofenceRegistrationEvent geofenceEvent:
        _notifyGeofenceRegistration(geofenceEvent);
      case SystemStateChangedEvent stateEvent:
        _notifySystemStateChange(stateEvent);
      case HolidayPolicyUpdatedEvent holidayEvent:
        _notifyHolidayPolicyUpdate(holidayEvent);
    }
  }
  
  static void _notifyAlarmScheduled(AlarmScheduledEvent event) {
    DebugLogger.info(
      '⏰ Alarm ${event.alarmId} scheduled for ${event.scheduledFor}: ${event.reason}',
    );
    // Here you could show a user notification, update UI, etc.
  }
  
  static void _notifyAlarmBypassed(AlarmBypassedEvent event) {
    final reason = _formatBypassReason(event.reason);
    DebugLogger.info('⏸️ Alarm ${event.alarmId} bypassed: $reason');
    // Here you could show a user notification explaining why the alarm was bypassed
  }
  
  static void _notifyGeofenceRegistration(GeofenceRegistrationEvent event) {
    if (event.registered) {
      DebugLogger.info('🌍 Geofence registered for alarm ${event.alarmId}');
    } else {
      DebugLogger.warning(
        '🌍 Failed to register geofence for alarm ${event.alarmId}: ${event.error ?? "Unknown error"}',
      );
    }
  }
  
  static void _notifySystemStateChange(SystemStateChangedEvent event) {
    DebugLogger.info('⚙️ System state changed: ${event.reason}');
  }
  
  static void _notifyHolidayPolicyUpdate(HolidayPolicyUpdatedEvent event) {
    DebugLogger.info(
      '📅 Holiday policy updated: ${event.holidaysLoaded} holidays loaded',
    );
  }
  
  static String _formatBypassReason(BypassReason reason) {
    switch (reason) {
      case BypassReason.holiday:
        return 'Today is a holiday';
      case BypassReason.outsideWorkHours:
        return 'Outside work hours';
      case BypassReason.permissionDenied:
        return 'Permission denied';
      case BypassReason.alarmInactive:
        return 'Alarm is inactive';
      case BypassReason.manualOverride:
        return 'Manual override';
    }
  }
}