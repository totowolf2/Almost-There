import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _locationRequested = false;
  bool _backgroundLocationRequested = false;
  bool _notificationRequested = false;
  
  bool _locationGranted = false;
  bool _backgroundLocationGranted = false;
  bool _notificationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    final locationStatus = await Permission.locationWhenInUse.status;
    final backgroundLocationStatus = await Permission.locationAlways.status;
    final notificationStatus = await Permission.notification.status;

    setState(() {
      _locationGranted = locationStatus.isGranted;
      _backgroundLocationGranted = backgroundLocationStatus.isGranted;
      _notificationGranted = notificationStatus.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allPermissionsGranted = _locationGranted && 
                                 _backgroundLocationGranted && 
                                 _notificationGranted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Almost There!'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Header
            Text(
              'ตั้งค่า Permissions',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'แอพต้องการสิทธิ์เหล่านี้เพื่อแจ้งเตือนเมื่อคุณใกล้ถึงจุดหมาย',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            
            Expanded(
              child: Column(
                children: [
                  // Location Permission
                  _buildPermissionCard(
                    icon: Icons.location_on,
                    title: 'ตำแหน่งที่ตั้ง',
                    description: 'ใช้เพื่อตรวจสอบตำแหน่งของคุณ',
                    isGranted: _locationGranted,
                    isRequested: _locationRequested,
                    onRequest: _requestLocationPermission,
                  ),
                  const SizedBox(height: 16),
                  
                  // Background Location Permission
                  _buildPermissionCard(
                    icon: Icons.my_location,
                    title: 'ตำแหน่งที่ตั้งในพื้นหลัง',
                    description: 'ใช้เพื่อแจ้งเตือนแม้แอพไม่ได้เปิดอยู่',
                    isGranted: _backgroundLocationGranted,
                    isRequested: _backgroundLocationRequested,
                    onRequest: _requestBackgroundLocationPermission,
                    isEnabled: _locationGranted, // Can only request if location is granted
                  ),
                  const SizedBox(height: 16),
                  
                  // Notification Permission
                  _buildPermissionCard(
                    icon: Icons.notifications,
                    title: 'การแจ้งเตือน',
                    description: 'ใช้เพื่อส่งการแจ้งเตือนเมื่อใกล้ถึงจุดหมาย',
                    isGranted: _notificationGranted,
                    isRequested: _notificationRequested,
                    onRequest: _requestNotificationPermission,
                  ),
                ],
              ),
            ),
            
            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: allPermissionsGranted ? _continueToApp : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  allPermissionsGranted 
                    ? 'เริ่มใช้งาน' 
                    : 'กรุณาอนุญาต Permissions ทั้งหมด',
                ),
              ),
            ),
            
            if (!allPermissionsGranted) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _openAppSettings,
                child: const Text('เปิดการตั้งค่าแอพ'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required bool isRequested,
    required VoidCallback onRequest,
    bool isEnabled = true,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isGranted 
                  ? Colors.green.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isGranted 
                  ? Colors.green 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Status/Action
            if (isGranted)
              Icon(
                Icons.check_circle,
                color: Colors.green,
              )
            else
              ElevatedButton(
                onPressed: isEnabled && !isRequested ? onRequest : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  isRequested ? 'กำลังขอ...' : 'อนุญาต',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _locationRequested = true;
    });

    final status = await Permission.locationWhenInUse.request();
    
    setState(() {
      _locationRequested = false;
      _locationGranted = status.isGranted;
    });

    if (!status.isGranted) {
      _showPermissionDeniedDialog('Location');
    }
  }

  Future<void> _requestBackgroundLocationPermission() async {
    if (!_locationGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาอนุญาตตำแหน่งที่ตั้งก่อน'),
        ),
      );
      return;
    }

    setState(() {
      _backgroundLocationRequested = true;
    });

    final status = await Permission.locationAlways.request();
    
    setState(() {
      _backgroundLocationRequested = false;
      _backgroundLocationGranted = status.isGranted;
    });

    if (!status.isGranted) {
      _showPermissionDeniedDialog('Background Location');
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() {
      _notificationRequested = true;
    });

    final status = await Permission.notification.request();
    
    setState(() {
      _notificationRequested = false;
      _notificationGranted = status.isGranted;
    });

    if (!status.isGranted) {
      _showPermissionDeniedDialog('Notification');
    }
  }

  void _showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission ถูกปฏิเสธ'),
        content: Text(
          'คุณได้ปฏิเสธ $permissionName permission\n'
          'กรุณาไปที่การตั้งค่าแอพเพื่ออนุญาต permissions',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openAppSettings();
            },
            child: const Text('เปิดการตั้งค่า'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
    // Refresh permissions after returning from settings
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkCurrentPermissions();
    });
  }

  void _continueToApp() {
    // ใช้ pushNamedAndRemoveUntil เพื่อป้องกันไม่ให้กลับมาหน้า permissions อีก
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }
}