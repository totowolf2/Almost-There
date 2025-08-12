# Test Plan: Notification Dismissal Fix

## Test Objective
Verify that when user taps the alarm notification card, ALL notifications are dismissed properly including:
1. Main alarm notification 
2. AlarmAudioService ongoing foreground notification
3. Audio playback stops
4. Vibration stops

## Test Steps

### Step 1: Setup Test Alarm
1. Launch the app
2. Create a new alarm at current location with small radius (100-300m)
3. Enable the alarm
4. Wait for geofence registration confirmation

### Step 2: Trigger Alarm
1. Move within the geofence radius (or simulate location)
2. Wait for alarm to trigger
3. Verify the following appears:
   - Main alarm notification with Thai text "⏰ ถึงปลายทางแล้ว! ⏰"
   - Audio starts playing (system alarm sound)
   - Vibration pattern starts
   - Ongoing "Alarm Playing" service notification appears

### Step 3: Test Notification Tap Dismissal
1. Tap anywhere on the main alarm notification body (not the action buttons)
2. **Expected Results:**
   - ✅ Audio immediately stops
   - ✅ Vibration immediately stops  
   - ✅ Main alarm notification disappears
   - ✅ **"Alarm Playing" service notification disappears** (This is the key fix)
   - ✅ No persistent notifications remain in the notification panel

### Step 4: Test Action Buttons
1. Repeat steps 1-2 to trigger alarm again
2. Test "⏰ Snooze 5 นาที" button
3. Test "✅ ปิดเตือน" button
4. Verify same results as Step 3

### Step 5: Verify Logs
Check Android logs for:
```
D/NotificationActionReceiver: Alarm audio service stop requested and service stop called
D/AlarmAudioService: Alarm service stopped and notification cleared
```

## Test Environment
- Android device with location permissions
- App installed with latest build
- Location services enabled

## Pass/Fail Criteria
**PASS:** All notifications disappear when alarm card is tapped
**FAIL:** Any notification remains visible after dismissal

## Current Issue Being Fixed
The "Alarm Playing" ongoing service notification was not disappearing even though audio/vibration stopped correctly.

## Technical Details
- Main alarm notification ID: `1000 + alarmId.hashCode()`
- Service foreground notification ID: `4000`
- Both notifications are now explicitly cancelled in dismissal handlers