# PRP: Almost There! Location Alarm App

## Overview

Create a comprehensive location-based alarm application "Almost There!" that alerts users when they approach their destinations. The app features one-time and recurring alarms, live distance cards on lock screen, OSM map integration, and sophisticated geofencing using native Android APIs with Flutter UI.

## Context

### Current State
- Greenfield Flutter project
- No existing codebase
- Icon asset available: `icon.png`
- Complete specifications in `README.md`

### Requirements

**Core Features:**
- **Two alarm types**: One-time (trip-based, auto-disable after trigger) and Recurring (daily/scheduled)
- **Native Android Geofencing**: Up to 100 geofences using GeofencingClient API
- **Live Cards**: Ongoing notifications showing distance to destination on lock screen
- **Multiple simultaneous alarms**: Max 30 active with overlap management (cooloff, debounce)
- **OSM Map Integration**: Location picker with radius visualization
- **Complex UI**: Alarm list, map picker, settings, onboarding, permission handling
- **Battery optimization**: Efficient location tracking with Fused Location Provider

**Technical Requirements:**
- **Platform**: Android (minSdk 24, targetSdk 34)
- **Framework**: Flutter + Native Android (Kotlin)
- **Theme**: Warm natural tones (Terracotta #C8664F, Sage #6F8E6B, River #4C768D)
- **Languages**: Thai/English support with Noto Sans Thai font

### Dependencies

**Flutter Packages:**
- `flutter_map` - OSM map integration
- `geolocator` - Location services and permissions
- `flutter_local_notifications` - Notification system
- `hive` + `hive_flutter` - Local storage
- `riverpod` + `flutter_riverpod` - State management
- `timezone` - Notification scheduling

**Native Android APIs:**
- `GeofencingClient` - Geofence management
- `FusedLocationProviderClient` - Battery-efficient location tracking
- `NotificationManagerCompat` - Advanced notifications
- `BroadcastReceiver` - Geofence transition handling

## Research Findings

### Codebase Analysis
- New project - no existing patterns to follow
- Will establish architectural patterns using industry best practices

### External Research

**Flutter Map (OSM Integration):**
- URL: https://docs.fleaflet.dev/
- **Critical**: Must set `userAgentPackageName` to avoid being blocked by OSM
- Simple setup with TileLayer and MapOptions
- Supports interactive markers, polygons, and radius visualization

**Geolocator Package:**
- URL: https://pub.dev/packages/geolocator
- Handles location permissions, current position, distance calculations
- Requires `ACCESS_FINE_LOCATION` and `ACCESS_BACKGROUND_LOCATION` permissions
- Platform-specific setup for Android/iOS

**Flutter Local Notifications:**
- URL: https://pub.dev/packages/flutter_local_notifications
- Supports ongoing notifications (live cards), notification actions
- Requires timezone package for scheduling
- Android 13+ notification permission handling

**Android Geofencing:**
- URL: https://developer.android.com/develop/sensors-and-location/location/geofencing
- 100 geofences max per app/device user
- Geofence alerts can be delayed 2-3 minutes
- Requires BroadcastReceiver for transition handling
- Best radius: 100-150 meters for accuracy/battery balance

**Riverpod State Management:**
- URL: https://riverpod.dev/docs/introduction/why_riverpod
- Reactive caching framework, ideal for async location data
- Automatic error handling and state management
- Recommended for complex Flutter apps in 2024

**Hive Storage:**
- URL: https://pub.dev/packages/hive
- Fast NoSQL database, perfect for alarm configurations
- Type-safe with code generation
- Cross-platform and encryption support

**Flutter Geofencing Options:**
- `flutter_background_geolocation` (commercial, robust)
- `easy_geofencing` (free, built on geolocator)
- Custom platform channel with native GeofencingClient (recommended)

## Implementation Plan

### Pseudocode/Algorithm

```
1. Initialize Flutter app with Riverpod + Hive
2. Setup native Android GeofencingClient platform channel
3. Create alarm models and providers (one-time/recurring types)
4. Implement permission flow (location → background → notifications)
5. Build main UI: AlarmsList → Add/Edit → MapPicker
6. Integrate geofencing: register/unregister based on alarm.enabled
7. Setup foreground service for live cards and location tracking
8. Handle geofence transitions → trigger notifications with actions
9. Implement background location tracking for live distance updates
10. Add settings, theming, and battery optimization guidance
```

### Tasks (in order)

1. **Project Setup & Dependencies**
   - Create Flutter project with required packages
   - Configure Android permissions and gradle settings
   - Setup Hive database initialization

2. **Data Models & Storage**
   - Create Alarm model with Hive TypeAdapter
   - Create Settings model for user preferences
   - Setup Riverpod providers for state management

3. **Native Android Geofencing**
   - Create platform channel for GeofencingClient
   - Implement GeofenceReceiver BroadcastReceiver
   - Setup GeofencingService foreground service
   - Handle geofence registration/removal

4. **Core UI Framework**
   - Setup app theming with specified color palette
   - Create main navigation structure
   - Implement AlarmsList screen with basic CRUD

5. **Location Integration**
   - Setup geolocator permissions handling
   - Create location picker with flutter_map
   - Implement radius visualization on map

6. **Alarm Management**
   - Build Add/Edit alarm screen
   - Implement alarm validation and persistence
   - Create bottom action sheet for alarm actions

7. **Permission Flow**
   - Build onboarding screens for permissions
   - Handle complex Android 10+ background location flow
   - Create battery optimization guidance

8. **Notifications System**
   - Setup local notifications with channels
   - Implement live cards (ongoing notifications)
   - Create trigger notifications with actions (snooze/dismiss)

9. **Background Services**
   - Implement foreground service for live distance tracking
   - Handle location updates and distance calculations
   - Manage service lifecycle with alarm states

10. **Settings & Optimization**
    - Create settings screen with defaults
    - Implement overlap management and limits
    - Add battery optimization tips and permissions status

11. **Testing & Polish**
    - Test geofence accuracy and battery usage
    - Implement error handling and edge cases
    - Performance optimization and memory management

### File Structure

```
almost_there/
├── lib/
│   ├── main.dart                           # App entry, theme, providers
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart          # Defaults, limits, intervals
│   │   │   └── theme_constants.dart        # Color palette, typography
│   │   ├── utils/
│   │   │   ├── location_utils.dart         # Distance calculations, formatting
│   │   │   ├── permission_utils.dart       # Permission checking helpers
│   │   │   └── notification_utils.dart     # Notification helpers
│   │   └── errors/
│   │       └── app_exceptions.dart         # Custom exception classes
│   ├── data/
│   │   ├── models/
│   │   │   ├── alarm_model.dart            # Alarm entity with Hive annotations
│   │   │   ├── location_model.dart         # Location coordinates model
│   │   │   └── settings_model.dart         # App settings model
│   │   ├── repositories/
│   │   │   ├── alarm_repository.dart       # Alarm CRUD operations
│   │   │   ├── settings_repository.dart    # Settings persistence
│   │   │   └── geofence_repository.dart    # Geofence management
│   │   └── services/
│   │       ├── location_service.dart       # Geolocator wrapper
│   │       ├── notification_service.dart   # Local notifications
│   │       └── geofencing_service.dart     # Platform channel interface
│   ├── presentation/
│   │   ├── providers/
│   │   │   ├── alarm_provider.dart         # Alarm state management
│   │   │   ├── location_provider.dart      # Current location state
│   │   │   ├── settings_provider.dart      # App settings state
│   │   │   └── permission_provider.dart    # Permission states
│   │   ├── screens/
│   │   │   ├── alarms/
│   │   │   │   ├── alarms_list_screen.dart # Main alarm list
│   │   │   │   └── add_edit_alarm_screen.dart # Alarm creation/editing
│   │   │   ├── map/
│   │   │   │   └── map_picker_screen.dart  # Location picker with OSM
│   │   │   ├── settings/
│   │   │   │   └── settings_screen.dart    # App settings
│   │   │   └── onboarding/
│   │   │       └── permission_screen.dart  # Permission requesting flow
│   │   ├── widgets/
│   │   │   ├── alarm_item_widget.dart      # Alarm list item
│   │   │   ├── bottom_action_sheet.dart    # Long-press actions
│   │   │   ├── radius_slider.dart          # Custom radius selector
│   │   │   ├── sound_selector.dart         # Sound picker with preview
│   │   │   └── day_selector.dart           # Recurring days selector
│   │   └── theme/
│   │       ├── app_theme.dart              # Material3 theme definition
│   │       └── color_schemes.dart          # Light/dark color schemes
│   └── platform/
│       └── geofencing_platform.dart       # Platform channel definitions
└── android/
    ├── app/src/main/kotlin/com/example/almost_there/
    │   ├── GeofencingService.kt           # Foreground service for live cards
    │   ├── GeofenceReceiver.kt            # Handles geofence transitions
    │   ├── GeofencingPlugin.kt            # Flutter platform channel
    │   └── MainActivity.kt                # Main activity
    └── app/src/main/AndroidManifest.xml   # Permissions, services, receivers
```

## Validation Gates

### Syntax/Style Checks
```bash
# Flutter analysis and formatting
flutter analyze
flutter format lib/ --line-length 80

# Build verification
flutter build apk --debug
```

### Testing Commands
```bash
# Unit tests
flutter test

# Integration tests (if applicable)
flutter test integration_test/

# Android native code compilation
cd android && ./gradlew build
```

### Manual Validation
- [ ] One-time alarm triggers and disables after geofence entry
- [ ] Recurring alarm works on specified days
- [ ] Live card shows accurate distance and updates
- [ ] Multiple alarms work simultaneously with proper overlap handling
- [ ] Background location permissions granted and working
- [ ] Notification actions (snooze, dismiss) work correctly
- [ ] Map picker allows location selection and radius adjustment
- [ ] Settings persist and apply correctly
- [ ] Battery optimization tips accessible and relevant
- [ ] App survives device reboot and restores active alarms

## Error Handling

### Common Issues

**Permission Denied Errors:**
- Solution: Implement graceful degradation, show permission rationale
- Check permissions before location operations
- Guide users to device settings for background location

**Geofence Registration Failures:**
- Solution: Validate coordinates, check network connectivity
- Limit active geofences to device maximum (100)
- Retry registration with exponential backoff

**Background Location Not Working:**
- Solution: Verify foreground service is running
- Check battery optimization settings
- Ensure proper Android manifest configuration

**OSM Tile Loading Issues:**
- Solution: Set proper User-Agent in flutter_map
- Handle network errors gracefully
- Implement offline map caching if needed

**Notification Not Appearing:**
- Solution: Check notification permissions and channels
- Verify foreground service notification
- Handle Android 13+ notification permission

### Troubleshooting

**Debug Steps:**
1. Check device logs for geofencing events
2. Verify location permissions in device settings
3. Test with location mocking for consistent results
4. Monitor battery usage and background restrictions

**Fallback Approaches:**
- Use timer-based location polling if geofencing fails
- Implement manual location refresh for live cards
- Provide manual alarm testing without movement

## Quality Checklist

- [ ] All requirements from README.md implemented
- [ ] Native Android geofencing integration working
- [ ] Flutter UI matches design specifications and theme
- [ ] Background location permissions properly handled
- [ ] Foreground service for live cards functional
- [ ] Notification system with actions working
- [ ] Settings and preferences persist correctly
- [ ] Battery optimization considerations addressed
- [ ] Error handling for edge cases implemented
- [ ] Performance optimized for battery life

## Confidence Score

**7/10** - High complexity project requiring deep expertise in multiple areas:

**Strengths:**
- Comprehensive requirements and design specifications
- Strong research foundation with specific package versions
- Well-defined architecture using proven patterns (Riverpod + Hive)
- Clear implementation roadmap with logical task ordering

**Challenges:**
- Complex native Android integration for geofencing
- Android 10+ background location permission complexity
- Battery optimization and foreground service requirements
- Multiple concurrent location-based features
- Sophisticated UI requirements with live updating components

**Risk Factors:**
- GeofencingClient API limitations and delays (2-3 minutes)
- Device-specific battery optimization behaviors
- Background location restrictions on modern Android
- Complex state management across multiple alarm types
- Performance optimization for battery life

**Mitigation:**
- Start with core functionality before advanced features
- Implement comprehensive error handling and fallbacks
- Test thoroughly on multiple Android versions and devices
- Use proven packages and established patterns
- Follow Android background location best practices

## References

### Flutter Packages Documentation
- flutter_map OSM integration: https://docs.fleaflet.dev/
- geolocator location services: https://pub.dev/packages/geolocator
- flutter_local_notifications: https://pub.dev/packages/flutter_local_notifications
- hive NoSQL database: https://pub.dev/packages/hive
- riverpod state management: https://riverpod.dev/docs/introduction/why_riverpod

### Android APIs Documentation
- GeofencingClient: https://developers.google.com/android/reference/com/google/android/gms/location/GeofencingClient
- Create & monitor geofences: https://developer.android.com/develop/sensors-and-location/location/geofencing
- FusedLocationProviderClient: https://developers.google.com/android/reference/com/google/android/gms/location/FusedLocationProviderClient
- Background location guidelines: https://developer.android.com/training/location/background
- Foreground services: https://developer.android.com/develop/background-work/services/fgs
- POST_NOTIFICATIONS permission: https://developer.android.com/develop/ui/views/notifications/notification-permission

### OSM Usage Policy
- Tile Usage Policy: https://operations.osmfoundation.org/policies/tiles/

### Best Practices Resources
- Flutter state management approaches: https://docs.flutter.dev/data-and-backend/state-mgmt/options
- Android background location best practices
- Battery optimization guidance for location apps