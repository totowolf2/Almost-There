import 'package:flutter/material.dart';
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

  runApp(
    const ProviderScope(
      child: AlmostThereApp(),
    ),
  );
}

class AlmostThereApp extends StatelessWidget {
  const AlmostThereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Almost There!',
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