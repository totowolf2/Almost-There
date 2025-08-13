import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/models/alarm_model.dart';
import '../../providers/alarm_provider.dart';
import '../../widgets/alarm_item_widget.dart';
import 'add_edit_alarm_screen.dart';

class AlarmsListScreen extends ConsumerStatefulWidget {
  const AlarmsListScreen({super.key});

  @override
  ConsumerState<AlarmsListScreen> createState() => _AlarmsListScreenState();
}

class _AlarmsListScreenState extends ConsumerState<AlarmsListScreen> {
  bool _isMultiSelectMode = false;
  final Set<String> _selectedAlarmIds = <String>{};

  @override
  void initState() {
    super.initState();
    // Check permissions on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsOnStartup();
    });
  }

  Future<void> _checkPermissionsOnStartup() async {
    final locationStatus = await Permission.locationWhenInUse.status;
    final backgroundLocationStatus = await Permission.locationAlways.status;
    final notificationStatus = await Permission.notification.status;

    // If any essential permission is missing, navigate to permissions screen
    if (!locationStatus.isGranted ||
        !backgroundLocationStatus.isGranted ||
        !notificationStatus.isGranted) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/permissions');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alarms = ref.watch(alarmsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Almost There!'),
        actions: [
          if (_isMultiSelectMode)
            TextButton(
              onPressed: _exitMultiSelectMode,
              child: const Text('Cancel'),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'cleanup',
                  child: ListTile(
                    leading: Icon(Icons.cleaning_services),
                    title: Text('Cleanup Expired'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'test_alarm',
                  child: ListTile(
                    leading: Icon(Icons.bug_report),
                    title: Text('สร้างปลุกทดสอบ'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'test_alarm_current_location',
                  child: ListTile(
                    leading: Icon(Icons.my_location),
                    title: Text('สร้างปลุกตรงตำแหน่งที่อยู่'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'check_permissions',
                  child: ListTile(
                    leading: Icon(Icons.security),
                    title: Text('ตรวจสอบ Permissions'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isMultiSelectMode) _buildMultiSelectToolbar(context),
          Expanded(
            child: alarms.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: alarms.length,
                    itemBuilder: (context, index) {
                      final alarm = alarms[index];
                      final isSelected = _selectedAlarmIds.contains(alarm.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AlarmItemWidget(
                          alarm: alarm,
                          isSelected: isSelected,
                          isMultiSelectMode: _isMultiSelectMode,
                          onTap: () => _handleAlarmTap(alarm.id),
                          onLongPress: () => _handleAlarmLongPress(alarm.id),
                          onToggle: (enabled) =>
                              _toggleAlarm(alarm.id, enabled),
                          onSelect: (selected) =>
                              _selectAlarm(alarm.id, selected),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton(
              onPressed: _addNewAlarm,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/empty_list_icon.png',
            width: 300,
            height: 300,
            // color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Alarms Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first location alarm to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewAlarm,
            icon: const Icon(Icons.add),
            label: const Text('Add Alarm'),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectToolbar(BuildContext context) {
    final selectedCount = _selectedAlarmIds.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Text(
            '$selectedCount selected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          if (selectedCount > 0) ...[
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: _addToGroup,
              tooltip: 'Add to Group',
            ),
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              onPressed: _enableSelectedAlarms,
              tooltip: 'Enable All',
            ),
            IconButton(
              icon: const Icon(Icons.power_off),
              onPressed: _disableSelectedAlarms,
              tooltip: 'Disable All',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedAlarms,
              tooltip: 'Delete',
            ),
          ],
        ],
      ),
    );
  }

  void _handleAlarmTap(String alarmId) {
    if (_isMultiSelectMode) {
      _selectAlarm(alarmId, !_selectedAlarmIds.contains(alarmId));
    } else {
      _editAlarm(alarmId);
    }
  }

  void _handleAlarmLongPress(String alarmId) {
    if (!_isMultiSelectMode) {
      setState(() {
        _isMultiSelectMode = true;
        _selectedAlarmIds.clear();
        _selectedAlarmIds.add(alarmId);
      });
    }
  }

  void _selectAlarm(String alarmId, bool selected) {
    setState(() {
      if (selected) {
        _selectedAlarmIds.add(alarmId);
      } else {
        _selectedAlarmIds.remove(alarmId);
      }

      // Exit multi-select mode if no items are selected
      if (_selectedAlarmIds.isEmpty) {
        _isMultiSelectMode = false;
      }
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedAlarmIds.clear();
    });
  }

  Future<void> _toggleAlarm(String alarmId, bool enabled) async {
    print('🔄 [DEBUG] Toggle alarm: $alarmId to enabled: $enabled');

    try {
      final alarmNotifier = ref.read(alarmsProvider.notifier);

      // Update the alarm's enabled state immediately for UI responsiveness
      final alarm = ref.read(alarmsProvider).firstWhere((a) => a.id == alarmId);
      final updatedAlarm = alarm.copyWith(
        enabled: enabled,
        // For one-time alarms, set isActive = enabled
        isActive: alarm.type == AlarmType.oneTime ? enabled : alarm.isActive,
      );

      // Update alarm in database - this should trigger UI update immediately
      await alarmNotifier.updateAlarm(updatedAlarm);

      print('🔄 [DEBUG] Alarm state updated in database');

      // If we're enabling the alarm, register geofences and start tracking
      if (enabled) {
        print('🔄 [DEBUG] Alarm enabled, registering geofences...');
        await alarmNotifier.registerActiveGeofences();

        print('🔄 [DEBUG] Starting live card tracking...');
        final trackingResult = await alarmNotifier.startLiveCardTracking();
        print('🔄 [DEBUG] Live tracking result: $trackingResult');
      } else {
        // If we're disabling the alarm, we should re-register geofences to exclude this one
        print('🔄 [DEBUG] Alarm disabled, updating geofences...');
        await alarmNotifier.registerActiveGeofences();

        // Stop any active alarm notifications and audio for this alarm
        print(
          '🔄 [DEBUG] Stopping any active alarm notifications and audio...',
        );
        await _stopAlarmNotificationAndAudio(alarmId);

        // Stop live card service completely and restart with remaining active alarms
        print('🔄 [DEBUG] Stopping existing live card service...');
        await alarmNotifier.stopLiveCardTracking();

        print(
          '🔄 [DEBUG] Restarting live card tracking with remaining active alarms...',
        );
        final trackingResult = await alarmNotifier.startLiveCardTracking();
        print('🔄 [DEBUG] Live tracking result: $trackingResult');

        // Also manually trigger UI sync if needed - the LiveCard should disappear
        print('🔄 [DEBUG] LiveCard tracking updated for disabled alarm');
      }
    } catch (e) {
      print('🔄 [ERROR] Failed to toggle alarm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _addNewAlarm() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddEditAlarmScreen()));
  }

  void _editAlarm(String alarmId) {
    final alarm = ref.read(alarmsProvider).firstWhere((a) => a.id == alarmId);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddEditAlarmScreen(alarm: alarm)),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        _openSettings();
        break;
      case 'cleanup':
        _cleanupExpiredAlarms();
        break;
      case 'test_alarm':
        _createTestAlarm();
        break;
      case 'test_alarm_current_location':
        _createTestAlarmAtCurrentLocation();
        break;
      case 'check_permissions':
        _checkPermissions();
        break;
    }
  }

  void _openSettings() {
    // TODO: Navigate to settings screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings - Coming Soon')));
  }

  void _cleanupExpiredAlarms() {
    ref.read(alarmsProvider.notifier).cleanupExpiredAlarms();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Expired alarms cleaned up')));
  }

  void _addToGroup() {
    // TODO: Show group selection dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Add to Group - Coming Soon')));
  }

  Future<void> _enableSelectedAlarms() async {
    try {
      final alarmNotifier = ref.read(alarmsProvider.notifier);
      await alarmNotifier.enableAlarms(_selectedAlarmIds.toList());

      // Register geofences and start tracking for newly enabled alarms
      print('🔄 [DEBUG] Multiple alarms enabled, updating geofences...');
      await alarmNotifier.registerActiveGeofences();

      print('🔄 [DEBUG] Starting live card tracking...');
      final trackingResult = await alarmNotifier.startLiveCardTracking();
      print('🔄 [DEBUG] Live tracking result: $trackingResult');

      _exitMultiSelectMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedAlarmIds.length} alarms enabled')),
        );
      }
    } catch (e) {
      print('🔄 [ERROR] Failed to enable alarms: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _disableSelectedAlarms() async {
    try {
      final alarmNotifier = ref.read(alarmsProvider.notifier);
      await alarmNotifier.disableAlarms(_selectedAlarmIds.toList());

      // Update geofences to exclude disabled alarms
      print('🔄 [DEBUG] Multiple alarms disabled, updating geofences...');
      await alarmNotifier.registerActiveGeofences();

      // Update live card tracking (may stop if no active alarms left)
      print('🔄 [DEBUG] Updating live card tracking...');
      final trackingResult = await alarmNotifier.startLiveCardTracking();
      print('🔄 [DEBUG] Live tracking result: $trackingResult');

      _exitMultiSelectMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedAlarmIds.length} alarms disabled'),
          ),
        );
      }
    } catch (e) {
      print('🔄 [ERROR] Failed to disable alarms: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _deleteSelectedAlarms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alarms'),
        content: Text(
          'Are you sure you want to delete ${_selectedAlarmIds.length} alarm(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(alarmsProvider.notifier)
                  .deleteAlarms(_selectedAlarmIds.toList());
              Navigator.of(context).pop();
              _exitMultiSelectMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_selectedAlarmIds.length} alarms deleted'),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTestAlarm() async {
    try {
      await ref.read(alarmsProvider.notifier).createTestAlarm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สร้างปลุกทดสอบเรียบร้อย! ลองเดินไปที่กรุงเทพฯ'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _createTestAlarmAtCurrentLocation() async {
    try {
      await ref
          .read(alarmsProvider.notifier)
          .createTestAlarmAtCurrentLocation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'สร้างปลุกทดสอบตรงตำแหน่งที่อยู่เรียบร้อย! ลองออกจากตำแหน่งนี้',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final permissions = await ref
          .read(alarmsProvider.notifier)
          .checkPermissions();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('สถานะ Permissions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPermissionRow(
                  'Location',
                  permissions['location'] ?? false,
                ),
                _buildPermissionRow(
                  'Background Location',
                  permissions['background'] ?? false,
                ),
                _buildPermissionRow(
                  'Notifications',
                  permissions['notification'] ?? false,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildPermissionRow(String name, bool granted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(name)),
          Text(
            granted ? 'อนุญาต' : 'ไม่อนุญาต',
            style: TextStyle(
              color: granted ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _stopAlarmNotificationAndAudio(String alarmId) async {
    try {
      print('🛑 [DEBUG] Stopping alarm notification and audio for: $alarmId');

      // Send platform channel message to Android to stop alarm notification and audio
      const platform = MethodChannel('com.vaas.almost_there/geofencing');
      await platform.invokeMethod('stopAlarmAudio', {'alarmId': alarmId});

      // Also update alarm state in Flutter
      final alarmNotifier = ref.read(alarmsProvider.notifier);
      await alarmNotifier.triggerAlarm(
        alarmId,
      ); // This disables one-time alarms

      print('🛑 [DEBUG] Alarm $alarmId notification and audio stopped');
    } catch (e) {
      print('🛑 [ERROR] Failed to stop alarm notification: $e');
    }
  }
}
