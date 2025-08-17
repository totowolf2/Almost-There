# SchedulingOrchestrator Architecture

This document explains the new centralized orchestrator pattern implemented for alarm scheduling.

## Overview

The `SchedulingOrchestrator` is the central decision maker for all alarm scheduling operations. It centralizes holiday checking, manages geofence registration, and coordinates alarm scheduling through a clean interface-based architecture.

## Key Components

### Domain Layer
- **SchedulingOrchestrator**: Central command processor and decision maker
- **HolidayPolicy**: Centralized holiday checking logic
- **Commands**: All operations go through command pattern
- **Events**: Observable events for monitoring system state

### Gateway Interfaces
- **AlarmScheduler**: Interface for alarm scheduling operations
- **GeofenceRegistrar**: Interface for geofence management operations
- **HolidayRepository**: Interface for holiday data access

### Infrastructure Layer
- **PlatformAlarmScheduler**: Wraps existing AlarmSchedulerService
- **PlatformGeofenceRegistrar**: Wraps existing GeofencingPlatform
- **HolidayServiceRepository**: Wraps existing HolidayService

## Key Benefits

### 1. Centralized Holiday Checking
- All holiday logic is now in `HolidayPolicy`
- No more scattered holiday checks throughout the codebase
- Single source of truth for working day determination

### 2. Loose Coupling
- All components communicate through interfaces
- Easy to test and mock dependencies
- Clean separation of concerns

### 3. Command-Based Architecture
- All operations are commands sent to the orchestrator
- Consistent error handling and logging
- Easy to add new operations

### 4. Observable Events
- System state changes emit events
- Enables reactive UI updates
- Better debugging and monitoring

## Usage Examples

### Basic Integration

```dart
// Initialize the orchestrator (typically in main.dart)
import 'package:almost_there/core/services/user_notification_service.dart';

void main() {
  // ... other initialization
  
  // Start listening to orchestrator events
  UserNotificationService.startListening();
  
  runApp(MyApp());
}
```

### Handling Geofence Events

```dart
// In your platform channel handler
import 'package:almost_there/core/services/alarm_event_manager.dart';

void handleGeofenceEvent(String alarmId, String action) {
  if (action == 'ENTER') {
    AlarmEventManager.handleGeofenceEntry(alarmId);
  } else if (action == 'EXIT') {
    AlarmEventManager.handleGeofenceExit(alarmId);
  }
}
```

### Scheduling Alarms

```dart
// In your alarm provider
import 'package:almost_there/core/orchestrator_integration.dart';

class AlarmProvider {
  Future<void> scheduleAlarm(AlarmModel alarm) async {
    // The orchestrator will handle holiday checking automatically
    await OrchestratorIntegration.scheduleAlarm(alarm);
  }
  
  Future<void> cancelAlarm(String alarmId) async {
    await OrchestratorIntegration.cancelAlarm(alarmId);
  }
}
```

### Handling System Events

```dart
// In your boot receiver or permission handlers
import 'package:almost_there/core/services/alarm_event_manager.dart';

class BootReceiver {
  static Future<void> onDeviceBooted() async {
    await AlarmEventManager.handleDeviceBoot();
  }
}

class PermissionHandler {
  static Future<void> onPermissionChanged() async {
    await AlarmEventManager.handlePermissionChange();
  }
}
```

## Migration from Existing Code

### Old Pattern (Scattered Logic)
```dart
// ❌ Old way - holiday checking scattered everywhere
if (await HolidayService().isHoliday(DateTime.now())) {
  // Don't register geofence
  return;
}
await GeofencingPlatform.addGeofence(...);
await AlarmSchedulerService.scheduleAlarmActivation(alarm);
```

### New Pattern (Centralized)
```dart
// ✅ New way - orchestrator handles everything
await OrchestratorIntegration.scheduleAlarm(alarm);
```

## Flow Diagram

```
User Action / System Event
           ↓
    Command Creation
           ↓
  SchedulingOrchestrator
           ↓
    HolidayPolicy Check
           ↓
   Gateway Operations
           ↓
    Event Emission
           ↓
  UI Updates / Notifications
```

## Testing

The interface-based architecture makes testing much easier:

```dart
// Mock implementations for testing
class MockHolidayPolicy implements HolidayPolicy {
  @override
  Future<bool> isWorkingDay(DateTime date) async => true; // Always working day
}

class MockAlarmScheduler implements AlarmScheduler {
  @override
  Future<bool> scheduleAlarmActivation(AlarmModel alarm) async => true;
}

// Test orchestrator with mocks
final orchestrator = SchedulingOrchestrator(
  holidayPolicy: MockHolidayPolicy(),
  alarmScheduler: MockAlarmScheduler(),
  geofenceRegistrar: MockGeofenceRegistrar(),
);
```

## File Structure

```
lib/
  domain/
    scheduling_orchestrator.dart      # Main orchestrator
    commands.dart                     # Command definitions
    policy/
      holiday_policy.dart             # Holiday checking interface
    gateways/
      alarm_scheduler.dart            # Alarm scheduling interface
      geofence_registrar.dart         # Geofence management interface
    events/
      scheduling_events.dart          # Event definitions
  
  infrastructure/
    platform_alarm_scheduler.dart    # Platform implementation
    platform_geofence_registrar.dart # Platform implementation
    holiday_service_repository.dart  # Holiday service wrapper
  
  core/
    orchestrator_integration.dart    # Integration layer
    services/
      alarm_event_manager.dart       # Event handling service
      user_notification_service.dart # User notification service
      debug_logger.dart              # Logging service
```

## Next Steps

1. **Integrate with existing providers**: Update AlarmProvider to use OrchestratorIntegration
2. **Platform channel integration**: Connect geofence events to AlarmEventManager
3. **UI integration**: Subscribe to orchestrator events for real-time updates
4. **Add monitoring**: Implement proper logging and error tracking
5. **Add tests**: Create comprehensive tests for all components