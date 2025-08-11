# Task Completion Checklist

## When completing any development task:

1. **Code Quality**
   - Run `flutter analyze` to check for issues
   - Run `flutter format .` to format code
   - Ensure no compilation errors

2. **Testing**
   - Run `flutter test` if tests exist
   - Test on physical Android device if dealing with location/notifications
   - Test different Android versions if possible

3. **Build Verification**
   - Run `flutter build apk --debug` to ensure build succeeds
   - Check Android logs: `flutter logs` or `adb logcat`

4. **Documentation**
   - Update README.md if functionality changes
   - Add code comments for complex logic
   - Update memory files if architecture changes

## Specific for Almost There! App
- Test location permissions on device
- Test notification permissions (Android 13+)
- Verify geofencing works with real location changes
- Test background service lifecycle
- Check battery optimization settings impact