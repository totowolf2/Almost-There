import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isMultiSelectMode)
            _buildMultiSelectToolbar(context),
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
                          onToggle: (enabled) => _toggleAlarm(alarm.id, enabled),
                          onSelect: (selected) => _selectAlarm(alarm.id, selected),
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
          Icon(
            Icons.location_on_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
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

  void _toggleAlarm(String alarmId, bool enabled) {
    ref.read(alarmsProvider.notifier).toggleAlarm(alarmId);
  }

  void _addNewAlarm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditAlarmScreen(),
      ),
    );
  }

  void _editAlarm(String alarmId) {
    final alarm = ref.read(alarmsProvider).firstWhere((a) => a.id == alarmId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditAlarmScreen(alarm: alarm),
      ),
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
    }
  }

  void _openSettings() {
    // TODO: Navigate to settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings - Coming Soon')),
    );
  }

  void _cleanupExpiredAlarms() {
    ref.read(alarmsProvider.notifier).cleanupExpiredAlarms();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expired alarms cleaned up')),
    );
  }

  void _addToGroup() {
    // TODO: Show group selection dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add to Group - Coming Soon')),
    );
  }

  void _enableSelectedAlarms() {
    ref.read(alarmsProvider.notifier).enableAlarms(_selectedAlarmIds.toList());
    _exitMultiSelectMode();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedAlarmIds.length} alarms enabled')),
    );
  }

  void _disableSelectedAlarms() {
    ref.read(alarmsProvider.notifier).disableAlarms(_selectedAlarmIds.toList());
    _exitMultiSelectMode();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedAlarmIds.length} alarms disabled')),
    );
  }

  void _deleteSelectedAlarms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alarms'),
        content: Text('Are you sure you want to delete ${_selectedAlarmIds.length} alarm(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(alarmsProvider.notifier).deleteAlarms(_selectedAlarmIds.toList());
              Navigator.of(context).pop();
              _exitMultiSelectMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${_selectedAlarmIds.length} alarms deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}