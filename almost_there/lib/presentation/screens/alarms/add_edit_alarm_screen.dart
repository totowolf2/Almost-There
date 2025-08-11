import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/alarm_model.dart';
import '../../../data/models/location_model.dart';
import '../../providers/alarm_provider.dart';
import '../../providers/settings_provider.dart';
import '../map/map_picker_screen.dart';
import '../../widgets/day_selector.dart';
import '../../widgets/sound_selector.dart';

class AddEditAlarmScreen extends ConsumerStatefulWidget {
  final AlarmModel? alarm; // null for add, non-null for edit

  const AddEditAlarmScreen({
    super.key,
    this.alarm,
  });

  @override
  ConsumerState<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends ConsumerState<AddEditAlarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  
  late AlarmType _selectedType;
  late bool _enabled;
  late bool _showLiveCard;
  late List<int> _selectedDays;
  late int _snoozeMinutes;
  late String _soundPath;
  
  LocationModel? _selectedLocation;
  double _radius = 300.0;
  String? _groupName;

  bool get _isEditing => widget.alarm != null;

  @override
  void initState() {
    super.initState();
    
    if (_isEditing) {
      // Initialize with existing alarm data
      final alarm = widget.alarm!;
      _labelController.text = alarm.label;
      _selectedType = alarm.type;
      _enabled = alarm.enabled;
      _showLiveCard = alarm.showLiveCard;
      _selectedDays = List.from(alarm.recurringDays);
      _snoozeMinutes = alarm.snoozeMinutes;
      _soundPath = alarm.soundPath;
      _selectedLocation = alarm.location;
      _radius = alarm.radius;
      _groupName = alarm.groupName;
    } else {
      // Initialize with default values from settings
      final settings = ref.read(settingsProvider);
      _selectedType = settings.isDefaultOneTime ? AlarmType.oneTime : AlarmType.recurring;
      _enabled = true;
      _showLiveCard = settings.defaultShowLiveCard;
      _selectedDays = [];
      _snoozeMinutes = settings.defaultSnoozeMinutes;
      _soundPath = settings.defaultSound;
      _radius = settings.defaultRadius;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'แก้ไขการแจ้งเตือน' : 'เพิ่มการแจ้งเตือน'),
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: const Text('บันทึก'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Label input
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'ชื่อการแจ้งเตือน',
                hintText: 'เช่น บ้าน, ที่ทำงาน, ร้านอาหาร',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณาใส่ชื่อการแจ้งเตือน';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Alarm type selection
            Text(
              'ประเภทการแจ้งเตือน',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<AlarmType>(
              segments: const [
                ButtonSegment(
                  value: AlarmType.oneTime,
                  label: Text('ครั้งเดียว'),
                  icon: Icon(Icons.schedule),
                ),
                ButtonSegment(
                  value: AlarmType.recurring,
                  label: Text('ประจำ'),
                  icon: Icon(Icons.repeat),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<AlarmType> selection) {
                setState(() {
                  _selectedType = selection.first;
                  if (_selectedType == AlarmType.oneTime) {
                    _selectedDays.clear();
                  }
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Days selector for recurring alarms
            if (_selectedType == AlarmType.recurring) ...[
              Text(
                'วันที่ต้องการแจ้งเตือน',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DaySelector(
                selectedDays: _selectedDays,
                onSelectionChanged: (days) {
                  setState(() {
                    _selectedDays = days;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],
            
            // Location picker
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('ตำแหน่งปลายทาง'),
                subtitle: _selectedLocation != null
                    ? Text(_selectedLocation!.coordinates)
                    : const Text('แตะเพื่อเลือกตำแหน่ง'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickLocation,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Radius display
            if (_selectedLocation != null) ...[
              Text(
                'รัศมีการแจ้งเตือน: ${_formatRadius(_radius)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
            ],
            
            // Sound selector
            Card(
              child: ListTile(
                leading: const Icon(Icons.volume_up),
                title: const Text('เสียงแจ้งเตือน'),
                subtitle: Text(_soundPath == 'default' ? 'เสียงเริ่มต้น' : 'เสียงกำหนดเอง'),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: _previewSound,
                ),
                onTap: _selectSound,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Snooze duration
            Card(
              child: ListTile(
                leading: const Icon(Icons.snooze),
                title: const Text('ระยะเวลา Snooze'),
                subtitle: Text('$_snoozeMinutes นาที'),
                trailing: DropdownButton<int>(
                  value: _snoozeMinutes,
                  items: [1, 3, 5, 10, 15, 30].map((minutes) {
                    return DropdownMenuItem(
                      value: minutes,
                      child: Text('$minutes นาที'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _snoozeMinutes = value;
                      });
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Toggles
            SwitchListTile(
              title: const Text('เปิดใช้งาน'),
              subtitle: const Text('เริ่มติดตามตำแหน่งทันที'),
              value: _enabled,
              onChanged: (value) {
                setState(() {
                  _enabled = value;
                });
              },
            ),
            
            SwitchListTile(
              title: const Text('แสดง Live Card'),
              subtitle: const Text('แสดงระยะทางบนหน้าจอล็อก'),
              value: _showLiveCard,
              onChanged: (value) {
                setState(() {
                  _showLiveCard = value;
                });
              },
            ),
            
            const SizedBox(height: 32),
            
            // Delete button for editing
            if (_isEditing) ...[
              OutlinedButton.icon(
                onPressed: _deleteAlarm,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('ลบการแจ้งเตือน', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _pickLocation() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLocation: _selectedLocation,
          initialRadius: _radius,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result['location'] as LocationModel;
        _radius = result['radius'] as double;
      });
    }
  }

  void _selectSound() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SoundSelector(
        currentSound: _soundPath,
        onSoundSelected: (sound) {
          setState(() {
            _soundPath = sound;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _previewSound() {
    // TODO: Implement sound preview
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('การฟังตัวอย่างเสียงจะพร้อมใช้งานเร็วๆ นี้')),
    );
  }

  void _saveAlarm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกตำแหน่งปลายทาง')),
      );
      return;
    }

    if (_selectedType == AlarmType.recurring && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกวันสำหรับการแจ้งเตือนแบบประจำ')),
      );
      return;
    }

    try {
      final alarmNotifier = ref.read(alarmsProvider.notifier);
      
      if (_isEditing) {
        // Update existing alarm
        final updatedAlarm = widget.alarm!.copyWith(
          label: _labelController.text.trim(),
          type: _selectedType,
          location: _selectedLocation!,
          radius: _radius,
          enabled: _enabled,
          showLiveCard: _showLiveCard,
          soundPath: _soundPath,
          snoozeMinutes: _snoozeMinutes,
          recurringDays: _selectedDays,
          groupName: _groupName,
        );
        await alarmNotifier.updateAlarm(updatedAlarm);
      } else {
        // Create new alarm
        await alarmNotifier.addAlarm(
          label: _labelController.text.trim(),
          type: _selectedType,
          location: _selectedLocation!,
          radius: _radius,
          enabled: _enabled,
          showLiveCard: _showLiveCard,
          soundPath: _soundPath,
          snoozeMinutes: _snoozeMinutes,
          recurringDays: _selectedDays,
          groupName: _groupName,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'อัปเดตการแจ้งเตือนแล้ว' : 'เพิ่มการแจ้งเตือนแล้ว'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  void _deleteAlarm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบการแจ้งเตือน'),
        content: const Text('คุณแน่ใจหรือไม่ที่จะลบการแจ้งเตือนนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(alarmsProvider.notifier).deleteAlarm(widget.alarm!.id);
                if (mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ลบการแจ้งเตือนแล้ว')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                  );
                }
              }
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  String _formatRadius(double radius) {
    if (radius >= 1000) {
      return '${(radius / 1000).toStringAsFixed(1)} กม.';
    }
    return '${radius.toInt()} ม.';
  }
}