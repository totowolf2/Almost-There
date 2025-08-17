import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'data/models/alarm_model.dart';
import 'data/models/location_model.dart';
import 'data/models/settings_model.dart';
import 'data/services/holiday_service.dart';
import 'presentation/providers/alarm_provider.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/alarms/alarms_list_screen.dart';
import 'presentation/screens/onboarding/permissions_screen.dart';

// Global navigation key for handling deep links
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  print('🚀 [DEBUG] ========== Flutter App Starting ==========');
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 [DEBUG] WidgetsFlutterBinding ensureInitialized completed');

  // Initialize Hive
  await Hive.initFlutter();
  print('🚀 [DEBUG] Hive initialized');

  // Register Hive Adapters (will be generated)
  Hive.registerAdapter(AlarmModelAdapter());
  Hive.registerAdapter(LocationModelAdapter());
  Hive.registerAdapter(SettingsModelAdapter());
  Hive.registerAdapter(AlarmTypeAdapter());

  // Open Hive boxes
  await Hive.openBox<AlarmModel>('alarms');
  await Hive.openBox<SettingsModel>('settings');

  // Initialize timezone data for notifications
  tz.initializeTimeZones();

  // Initialize notifications
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const initializationSettingsAndroid = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification taps
    },
  );

  print('🚀 [DEBUG] About to run Flutter app...');
  runApp(const ProviderScope(child: AlmostThereApp()));
  print('🚀 [DEBUG] Flutter app started successfully');
}

void _setupMainActivityChannel() {
  print('🔧 [DEBUG] Setting up main activity method channel...');
  const channel = MethodChannel('com.vaas.almost_there/main');
  print('🔧 [DEBUG] Created method channel with name: com.vaas.almost_there/main');

  channel.setMethodCallHandler((call) async {
    print('🔔 [DEBUG] *** METHOD CHANNEL RECEIVED CALL: ${call.method} ***');
    print('🔔 [DEBUG] Call arguments: ${call.arguments}');
    switch (call.method) {
      case 'onAlarmEvent':
        final eventType = call.arguments['eventType'] as String;
        final alarmId = call.arguments['alarmId'] as String;
        print(
          '📱 [DEBUG] Received alarm event: $eventType for alarm: $alarmId',
        );

        // Handle different alarm events
        switch (eventType) {
          case 'TEST_CONNECTION':
            print('🧪 [DEBUG] TEST_CONNECTION received successfully! Method channel is working!');
            break;
          case 'ALARM_FULL_SCREEN':
          case 'OPEN_ALARM_MAP':
            // Navigate to home and trigger alarm display
            _handleAlarmEvent(alarmId);
            break;
          case 'ALARM_DISMISSED':
            // Handle alarm dismiss
            _handleAlarmDismissed(alarmId);
            break;
          case 'ALARM_SNOOZED':
            // Handle alarm snooze
            final snoozeMinutes = call.arguments['snoozeMinutes'] as int? ?? 5;
            _handleAlarmSnoozed(alarmId, snoozeMinutes);
            break;
          case 'ALARM_TRIGGERED':
            // Handle alarm trigger
            _handleAlarmTriggered(alarmId);
            break;
          case 'LIVECARD_STOPPED':
            // Handle LiveCard stop button
            _handleLiveCardStopped(alarmId);
            break;
          case 'LIVECARD_HIDDEN':
            // Handle LiveCard hide button
            _handleLiveCardHidden(alarmId);
            break;
        }
        break;
      default:
        print('📱 [DEBUG] Unknown method: ${call.method}');
    }
  });
  
  print('🔧 [DEBUG] Method channel setup completed successfully');
}

void _handleAlarmEvent(String alarmId) async {
  // Get the provider container to check alarm details
  final context = navigatorKey.currentContext;
  if (context == null) return;
  
  final container = ProviderScope.containerOf(context);
  final alarms = container.read(alarmsProvider);
  
  // Find the alarm that triggered
  final alarm = alarms.firstWhere(
    (a) => a.id == alarmId,
    orElse: () => throw Exception('Alarm not found: $alarmId'),
  );
  
  // Check if alarm should skip holidays and if today is a holiday
  if (alarm.skipHolidays) {
    final holidayService = HolidayService();
    final isHolidayToday = await holidayService.isHoliday(DateTime.now());
    if (isHolidayToday) {
      // Skip this alarm trigger due to holiday
      return;
    }
  }

  // Check if context is still valid after async operations
  final currentContext = navigatorKey.currentContext;
  if (currentContext == null) return;

  // If we're not on the home screen, navigate there
  Navigator.of(currentContext).pushNamedAndRemoveUntil('/home', (route) => false);

  // Show a snackbar to indicate the alarm was triggered
  ScaffoldMessenger.of(currentContext).showSnackBar(
    SnackBar(
      content: Text('เปิดแอปจากการแจ้งเตือนปลุก: $alarmId'),
      duration: const Duration(seconds: 2),
    ),
  );
}

void _handleAlarmDismissed(String alarmId) {
  print('📱 [DEBUG] Handling alarm dismissed for: $alarmId');

  // Get the provider container to update alarm state
  final container = ProviderScope.containerOf(navigatorKey.currentContext!);
  final alarmNotifier = container.read(alarmsProvider.notifier);

  // Update the alarm state to dismissed/disabled for one-time alarms
  alarmNotifier
      .triggerAlarm(alarmId)
      .then((_) async {
        print('📱 [DEBUG] Alarm $alarmId marked as triggered/disabled');

        // Add a small delay to ensure state changes are fully processed
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Re-register geofences to reflect the updated state
        await alarmNotifier.registerActiveGeofences();
        print('📱 [DEBUG] Geofences updated after alarm dismissal');
        
        // Force UI update by triggering a refresh
        if (navigatorKey.currentContext != null) {
          print('📱 [DEBUG] Forcing UI refresh after alarm dismissal');
        }
      })
      .catchError((error) {
        print('📱 [ERROR] Failed to handle alarm dismissal: $error');
      });

  // Show user feedback
  final context = navigatorKey.currentContext;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔕 ปลุกถูกปิดแล้ว'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }
}

void _handleAlarmSnoozed(String alarmId, int snoozeMinutes) {
  print(
    '📱 [DEBUG] Handling alarm snoozed for: $alarmId, minutes: $snoozeMinutes',
  );

  // Show user feedback
  final context = navigatorKey.currentContext;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('😴 เลื่อนปลุกไป $snoozeMinutes นาที'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

void _handleAlarmTriggered(String alarmId) {
  print('📱 [DEBUG] Handling alarm triggered for: $alarmId');

  // Get the provider container to update alarm state
  final container = ProviderScope.containerOf(navigatorKey.currentContext!);
  final alarmNotifier = container.read(alarmsProvider.notifier);

  // Update the alarm's last triggered time
  alarmNotifier
      .triggerAlarm(alarmId)
      .then((_) {
        print('📱 [DEBUG] Alarm $alarmId marked as triggered');
      })
      .catchError((error) {
        print('📱 [ERROR] Failed to update alarm trigger: $error');
      });

  // Show user feedback
  final context = navigatorKey.currentContext;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏰ ปลุกถูกเรียกแล้ว!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }
}

void _handleLiveCardStopped(String alarmId) {
  print('📱 [DEBUG] Handling LiveCard stopped for: $alarmId');

  try {
    // Get the provider container to update alarm state
    final container = ProviderScope.containerOf(navigatorKey.currentContext!);
    final alarmNotifier = container.read(alarmsProvider.notifier);

    // Find and update the alarm to disable it (same as alarm dismiss for immediate UI update)
    final alarms = container.read(alarmsProvider);
    final alarmIndex = alarms.indexWhere((a) => a.id == alarmId);

    if (alarmIndex == -1) {
      print(
        '📱 [WARNING] Alarm $alarmId not found in current state - may have been already processed',
      );
      return; // Exit gracefully if alarm not found
    }

    final alarm = alarms[alarmIndex];

    print(
      '📱 [DEBUG] Found alarm: ${alarm.label}, current enabled: ${alarm.enabled}',
    );

    // Check if alarm is already disabled to avoid race conditions
    if (!alarm.enabled) {
      print('📱 [DEBUG] Alarm $alarmId is already disabled, skipping update');
      return;
    }

    // Update alarm state immediately - disable the alarm for immediate UI response
    final updatedAlarm = alarm.copyWith(enabled: false);
    print('📱 [DEBUG] Updating alarm to disabled state...');

    alarmNotifier
        .updateAlarm(updatedAlarm)
        .then((_) {
          print(
            '📱 [DEBUG] Alarm $alarmId disabled from LiveCard stop - UI should be updated now',
          );

          // Update geofences to reflect disabled state
          alarmNotifier.registerActiveGeofences();
        })
        .catchError((error) {
          print('📱 [ERROR] Failed to handle LiveCard stop: $error');
        });

    // Show user feedback
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔕 ปิด LiveCard และปลุกแล้ว'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } catch (e, stackTrace) {
    print('📱 [ERROR] Exception in _handleLiveCardStopped: $e');
    print('📱 [ERROR] Stack trace: $stackTrace');
  }
}

void _handleLiveCardHidden(String alarmId) {
  print('📱 [DEBUG] Handling LiveCard hidden for: $alarmId');

  // Show user feedback
  final context = navigatorKey.currentContext;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('👁️‍🗨️ ซ่อน LiveCard วันนี้แล้ว'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.grey,
      ),
    );
  }
}

class AlmostThereApp extends StatelessWidget {
  const AlmostThereApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('📱 [DEBUG] AlmostThereApp.build() called');
    return MaterialApp(
      title: 'Almost There!',
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppInitializer(),
      routes: {
        '/home': (context) => const AlarmsListScreen(),
        '/permissions': (context) => const PermissionsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// Widget สำหรับตรวจสอบ permissions เพื่อกำหนดหน้าแรก
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    print('🚀 [DEBUG] AppInitializer.initState() called');
    
    // Setup method channel after widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔧 [DEBUG] Setting up method channel after Flutter initialization...');
      _setupMainActivityChannel();
    });
    
    _checkPermissionsAndNavigate();
  }

  Future<void> _checkPermissionsAndNavigate() async {
    // ตรวจสอบ permissions ทั้งหมดที่จำเป็น
    final locationStatus = await Permission.locationWhenInUse.status;
    final backgroundLocationStatus = await Permission.locationAlways.status;
    final notificationStatus = await Permission.notification.status;

    // ถ้า permissions ครบทุกตัวแล้ว ให้ไปหน้าหลัก
    if (locationStatus.isGranted &&
        backgroundLocationStatus.isGranted &&
        notificationStatus.isGranted) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      // ถ้ายังไม่ครบ ให้ไปหน้าขอ permissions
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/permissions');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // แสดง loading screen ขณะตรวจสอบ permissions
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.location_on, size: 120, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            const Text(
              'Almost There!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'กำลังเริ่มต้น...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
