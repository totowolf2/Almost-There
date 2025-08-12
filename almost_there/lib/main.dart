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
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/alarms/alarms_list_screen.dart';
import 'presentation/screens/onboarding/permissions_screen.dart';

// Global navigation key for handling deep links
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

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

  // Setup method channel for MainActivity communication
  _setupMainActivityChannel();

  runApp(
    const ProviderScope(
      child: AlmostThereApp(),
    ),
  );
}

void _setupMainActivityChannel() {
  const channel = MethodChannel('com.example.almost_there/main');
  
  channel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'onAlarmEvent':
        final eventType = call.arguments['eventType'] as String;
        final alarmId = call.arguments['alarmId'] as String;
        print('📱 [DEBUG] Received alarm event: $eventType for alarm: $alarmId');
        
        // Handle different alarm events
        switch (eventType) {
          case 'ALARM_FULL_SCREEN':
          case 'OPEN_ALARM_MAP':
            // Navigate to home and trigger alarm display
            _handleAlarmEvent(alarmId);
            break;
        }
        break;
      default:
        print('📱 [DEBUG] Unknown method: ${call.method}');
    }
  });
}

void _handleAlarmEvent(String alarmId) {
  print('📱 [DEBUG] Handling alarm event for: $alarmId');
  
  // Get the current context and navigate to home screen
  final context = navigatorKey.currentContext;
  if (context != null) {
    // If we're not on the home screen, navigate there
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    
    // Show a snackbar to indicate the alarm was triggered
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เปิดแอปจากการแจ้งเตือนปลุก: $alarmId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class AlmostThereApp extends StatelessWidget {
  const AlmostThereApp({super.key});

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'กำลังเริ่มต้น...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}