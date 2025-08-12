# PRP: Alarm Clock Style Notifications

## Overview

Implement full-screen alarm notifications that behave like traditional alarm clocks, including bypass of Do Not Disturb mode, lock screen display, continuous alarm sound/vibration, and snooze/dismiss functionality. This will transform the existing geofence-triggered notifications into a proper alarm experience.

## Context

### Current State
- **GeofenceReceiver.kt**: Already implements full-screen intent notifications but directs to MainActivity which lacks lock screen handling
- **GeofencingService.kt**: Creates notification channels including "alarm_triggers" with proper alarm audio attributes
- **MainActivity.kt**: Handles intent routing but doesn't implement lock screen display
- **NotificationActionReceiver.kt**: Handles snooze/dismiss actions but has incomplete vibration stopping
- Existing notification system works but doesn't provide alarm-like user experience

### Requirements
Based on INIT.md feature file:
1. **Full-Screen Intent Notification**: Use `setCategory(CATEGORY_ALARM)` and `setFullScreenIntent()` with high importance
2. **Lock Screen Display**: Activity must show over lock screen using `setShowWhenLocked(true)` and `setTurnScreenOn(true)`
3. **Alarm Audio/Vibration**: Continuous sound with `AudioAttributes.USAGE_ALARM` and vibration patterns
4. **Background Operation**: Work when screen off or app dismissed via Foreground Service
5. **DND Bypass**: Override Do Not Disturb mode with `CATEGORY_ALARM` and proper permissions
6. **UX Flow**: Snooze/Dismiss actions with proper geofence re-scheduling

### Dependencies
- **Android Geofencing API**: Already integrated
- **Notification Channels**: Existing with alarm_triggers channel
- **Flutter Method Channels**: Existing geofencing platform communication
- **MediaPlayer/AudioManager**: For alarm sound playback
- **VibrationEffect**: For alarm vibration patterns

## Research Findings

### Codebase Analysis
- **Existing Full-Screen Setup**: GeofenceReceiver.kt (lines 91-121) already implements full-screen intent
- **Channel Configuration**: GeofencingService.kt (lines 137-158) has proper alarm channel with DND bypass
- **Flutter Communication**: GeofencingPlatform.dart provides method channel communication
- **Permission Handling**: AndroidManifest.xml has most required permissions but missing USE_FULL_SCREEN_INTENT
- **Service Architecture**: Foreground service already handles background operation

### External Research

#### Android 14+ Full-Screen Intent Changes (2024)
- **Documentation**: https://developer.android.com/develop/ui/views/notifications/build-notification#urgent-message
- **Permission Required**: `USE_FULL_SCREEN_INTENT` must be declared in manifest for Android 10+
- **Alarm App Exemption**: Android 14 automatically grants FSI permission for alarm apps
- **Runtime Check**: Use `NotificationManager.canUseFullScreenIntent()` to verify permission

#### Lock Screen Activity Implementation
- **Modern Approach**: Use `setShowWhenLocked(true)` and `setTurnScreenOn(true)` for Android 8.1+
- **Legacy Fallback**: Use window flags for older versions
- **Common Issues**: Device-specific restrictions (Xiaomi, Huawei require additional permissions)
- **Best Practice**: Create dedicated alarm activity instead of using MainActivity

#### Alarm Audio with AudioAttributes
- **Key Finding**: Use `setDataSource()` instead of `MediaPlayer.create()` to properly apply AudioAttributes
- **Proper Configuration**: 
  ```kotlin
  AudioAttributes.Builder()
    .setUsage(AudioAttributes.USAGE_ALARM)
    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
    .build()
  ```
- **Continuous Playback**: Use `setLooping(true)` for alarm-like behavior

#### DND Bypass Configuration
- **Channel Setup**: `notificationChannel.setBypassDnd(true)` requires DND access permission
- **User Permission**: Apps must request access via `ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS`
- **Category Importance**: Use `CATEGORY_ALARM` with `IMPORTANCE_HIGH` or `IMPORTANCE_MAX`

## Implementation Plan

### Pseudocode/Algorithm
```
1. ON GEOFENCE_ENTER:
   - Create AlarmActivity full-screen intent
   - Show full-screen notification with CATEGORY_ALARM
   - Start AlarmAudioService for continuous sound
   - Trigger vibration pattern

2. AlarmActivity:
   - Set lock screen flags (setShowWhenLocked, setTurnScreenOn)
   - Display alarm UI with Snooze/Dismiss buttons
   - Handle user actions

3. Snooze Action:
   - Stop current alarm sound/vibration
   - Create smaller radius geofence for re-trigger
   - Dismiss notification and activity

4. Dismiss Action:
   - Stop alarm sound/vibration permanently
   - Remove geofence if one-time alarm
   - Mark alarm as triggered in Flutter

5. Audio Service:
   - Use MediaPlayer with AudioAttributes.USAGE_ALARM
   - Loop alarm sound until dismissed
   - Handle audio focus changes
```

### Tasks (in order)

1. **Add Missing Permissions**
   - Add `USE_FULL_SCREEN_INTENT` permission to AndroidManifest.xml
   - Add DND access request handling in Flutter

2. **Create AlarmActivity**
   - New Kotlin activity for lock screen alarm display
   - Implement lock screen flags for Android 8.1+ and legacy fallback
   - Design alarm UI with large snooze/dismiss buttons
   - Handle window flags and audio focus

3. **Implement AlarmAudioService**
   - Foreground service for continuous alarm sound playback
   - Use MediaPlayer with proper AudioAttributes configuration
   - Handle looping, volume, and audio focus
   - Stop on snooze/dismiss actions

4. **Update GeofenceReceiver**
   - Modify full-screen intent to point to AlarmActivity instead of MainActivity
   - Enhance vibration pattern for alarm-like behavior
   - Start AlarmAudioService when alarm triggers

5. **Enhance NotificationActionReceiver**
   - Improve vibration stopping logic
   - Add proper AlarmAudioService stop commands
   - Implement snooze geofence re-scheduling

6. **Update Flutter Integration**
   - Add DND permission request flow in PermissionsScreen
   - Enhance geofencing platform for snooze functionality
   - Add alarm event handling in alarm provider

7. **Test and Validation**
   - Test on locked and unlocked devices
   - Verify DND bypass functionality
   - Test snooze re-scheduling behavior
   - Validate across different Android versions

### File Structure
```
almost_there/
├── android/app/src/main/kotlin/com/example/almost_there/
│   ├── AlarmActivity.kt (NEW)
│   ├── AlarmAudioService.kt (NEW)
│   ├── GeofenceReceiver.kt (MODIFY)
│   ├── NotificationActionReceiver.kt (MODIFY)
│   ├── GeofencingService.kt (MINOR UPDATES)
│   └── MainActivity.kt (MINOR UPDATES)
├── android/app/src/main/AndroidManifest.xml (ADD PERMISSION)
├── lib/presentation/screens/
│   └── alarm/
│       └── alarm_trigger_screen.dart (NEW - Flutter UI for alarm)
├── lib/platform/geofencing_platform.dart (ENHANCE)
└── lib/presentation/providers/alarm_provider.dart (ENHANCE)
```

## Validation Gates

### Syntax/Style Checks
```bash
# Android
cd almost_there/android && ./gradlew build
cd almost_there/android && ./gradlew assembleDebug

# Flutter
cd almost_there && flutter analyze
cd almost_there && flutter build apk --debug
```

### Testing Commands
```bash
# Manual Testing Script
cd almost_there && flutter run

# Test scenarios:
# 1. Create test alarm at current location with 50m radius
# 2. Enable DND mode on device
# 3. Move outside and back into geofence
# 4. Verify full-screen alarm appears on lock screen
# 5. Test snooze functionality
# 6. Test dismiss functionality
```

### Manual Validation
- [ ] Alarm triggers when entering geofence
- [ ] Full-screen activity appears on lock screen
- [ ] Alarm sound plays continuously using alarm volume channel
- [ ] Vibration pattern works properly
- [ ] Notification bypasses Do Not Disturb mode
- [ ] Snooze creates smaller geofence for re-trigger
- [ ] Dismiss stops alarm and updates Flutter app state
- [ ] Works when app is in background/dismissed
- [ ] Supports both one-time and recurring alarms

## Error Handling

### Common Issues
- **Permission Denied**: Handle graceful degradation when DND access not granted
- **Audio Focus Loss**: Pause alarm when phone call comes in, resume after
- **Device Restrictions**: Show user guidance for manufacturer-specific lock screen permissions
- **Geofence Limits**: Handle Android's 100 geofence limit per app
- **Service Killed**: Implement proper service restart mechanisms

### Troubleshooting
- **Full-screen not showing**: Check USE_FULL_SCREEN_INTENT permission and notification importance
- **No sound on alarm channel**: Verify AudioAttributes configuration and DND permissions
- **Lock screen not working**: Check device-specific settings and window flags
- **Background issues**: Verify foreground service configuration and background location permission

## Quality Checklist

- [ ] All INIT.md requirements implemented
- [ ] Code follows existing Kotlin/Dart patterns in codebase
- [ ] Proper error handling and user feedback
- [ ] Permissions handled gracefully with user guidance
- [ ] Validation passes on multiple Android versions
- [ ] Documentation updated with new components
- [ ] Memory leaks prevented (proper service lifecycle)
- [ ] Battery optimization considerations addressed

## Confidence Score

**9/10** - Very High Confidence

**Rationale**: 
- Extensive research completed with 2024-current Android documentation
- Current codebase already has 80% of required infrastructure
- Clear implementation path with existing patterns to follow
- Well-documented APIs with proven solutions from Stack Overflow
- Comprehensive error handling and fallback strategies identified
- Only uncertainty is device-specific manufacturer restrictions, but these are well-documented

The implementation should succeed in one pass with the detailed research and existing codebase foundation.

## References

### Android Documentation
- [Full-Screen Intent Notifications](https://developer.android.com/develop/ui/views/notifications/build-notification#urgent-message)
- [Android 10 Full-Screen Intent Permissions](https://developer.android.com/about/versions/10/behavior-changes-10#full-screen-intents)
- [Do Not Disturb Access](https://developer.android.com/guide/topics/ui/notifiers/notifications#dnd)
- [AudioAttributes](https://developer.android.com/reference/android/media/AudioAttributes)
- [Notification Categories](https://developer.android.com/develop/ui/views/notifications/channels#importance)

### Implementation Examples
- [Lock Screen Activity Implementation](https://victorbrandalise.com/how-to-show-activity-on-lock-screen-instead-of-notification/)
- [Alarm Audio with AudioAttributes](https://stackoverflow.com/questions/33961439/how-to-play-a-ringtone-using-the-alarm-volume-with-setaudioattributes)
- [Critical Alerts Implementation](https://medium.com/@surendar1006/implementing-critical-alerts-on-android-aa49b4d75705)

### Current Codebase References
- `almost_there/android/app/src/main/kotlin/com/example/almost_there/GeofenceReceiver.kt:89-178` - Existing notification implementation
- `almost_there/android/app/src/main/kotlin/com/example/almost_there/GeofencingService.kt:137-158` - Alarm channel configuration
- `almost_there/lib/platform/geofencing_platform.dart` - Flutter-Android communication
- `almost_there/lib/presentation/providers/alarm_provider.dart:218-258` - Geofence registration logic