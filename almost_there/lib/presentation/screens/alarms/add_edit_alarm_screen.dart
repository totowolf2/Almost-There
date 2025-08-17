import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/models/alarm_model.dart';
import '../../../data/models/location_model.dart';
import '../../../data/services/holiday_service.dart';
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
  late AudioPlayer _audioPlayer;
  
  late AlarmType _selectedType;
  late bool _enabled;
  late bool _showLiveCard;
  late List<int> _selectedDays;
  late int _snoozeMinutes;
  late String _soundPath;
  
  LocationModel? _selectedLocation;
  double _radius = 300.0;
  String? _groupName;
  TimeOfDay? _startTime;
  late bool _skipHolidays;

  bool get _isEditing => widget.alarm != null;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
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
      _startTime = alarm.startTime;
      _skipHolidays = alarm.skipHolidays;
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
      _skipHolidays = false;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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
            
            // Start time picker
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('เวลาเริ่มทำงาน'),
                subtitle: Text(_startTime != null 
                  ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                  : 'ทำงานทันทีเมื่อเปิดใช้งาน'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_startTime != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _startTime = null;
                          });
                        },
                        tooltip: 'ลบเวลาเริ่มทำงาน',
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: _pickStartTime,
              ),
            ),
            
            const SizedBox(height: 16),
            
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
            
            SwitchListTile(
              title: const Text('ข้ามวันหยุด'),
              subtitle: const Text('ไม่แจ้งเตือนในวันหยุดตามปฏิทิน'),
              value: _skipHolidays,
              onChanged: (value) async {
                setState(() {
                  _skipHolidays = value;
                });
                
                // Debug: Show holiday information when toggle is enabled
                if (value) {
                  await _debugShowHolidays();
                }
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

  void _pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
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

  void _previewSound() async {
    try {
      // เล่นเสียงที่แตกต่างกันตามที่เลือก
      await _playSpecificSoundPreview(_soundPath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 เล่นเสียง: ${_soundPath == 'default' ? 'เสียงเริ่มต้น' : _soundPath}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // ถ้าเล่นเสียงไม่ได้ ให้ใช้ system sound fallback
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.mediumImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 ตัวอย่างเสียง: ${_soundPath == 'default' ? 'เสียงเริ่มต้น' : _soundPath}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  Future<void> _playSpecificSoundPreview(String soundKey) async {
    // เล่นเสียงโดยตรงผ่าน SystemSound ตามประเภทที่เลือก
    switch (soundKey) {
      case 'bell':
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.lightImpact();
        break;
        
      case 'chime':
        SystemSound.play(SystemSoundType.click);
        await Future.delayed(const Duration(milliseconds: 300));
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.lightImpact();
        break;
        
      case 'ding':
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.mediumImpact();
        break;
        
      case 'gentle':
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.lightImpact();
        break;
        
      case 'alert':
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.heavyImpact();
        // เพิ่มการสั่นซ้ำสำหรับเสียงเตือน
        Future.delayed(const Duration(milliseconds: 500), () {
          HapticFeedback.heavyImpact();
        });
        break;
        
      default: // 'default' และอื่นๆ
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.mediumImpact();
        break;
    }
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
          startTime: _startTime,
          skipHolidays: _skipHolidays,
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
          startTime: _startTime,
          skipHolidays: _skipHolidays,
        );
      }

      // After saving alarm, register geofences and start live tracking
      print('🔧 [DEBUG] Alarm saved, registering geofences...');
      await alarmNotifier.registerActiveGeofences();
      
      print('🔧 [DEBUG] Starting live card tracking...');
      final trackingResult = await alarmNotifier.startLiveCardTracking();
      print('🔧 [DEBUG] Live tracking result: $trackingResult');

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

  Future<void> _debugShowHolidays() async {
    final holidayService = HolidayService();
    
    try {
      // Request calendar permissions first
      print('🎄 [DEBUG] Requesting calendar permission...');
      final hasPermission = await holidayService.requestCalendarPermission();
      if (!hasPermission) {
        print('🎄 [DEBUG] Calendar permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่ได้รับสิทธิ์เข้าถึงปฏิทิน กรุณาอนุญาตในการตั้งค่า'),
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'ตั้งค่า',
                onPressed: openAppSettings,
              ),
            ),
          );
        }
        return;
      }
      print('🎄 [DEBUG] Calendar permission granted');

      // Find holiday calendars
      print('🎄 [DEBUG] Finding holiday calendars...');
      final holidayCalendars = await holidayService.findHolidayCalendars();
      print('🎄 [DEBUG] Found ${holidayCalendars.length} holiday calendars');
      
      if (holidayCalendars.isEmpty) {
        print('🎄 [DEBUG] No holiday calendars found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่พบปฏิทินวันหยุด กรุณาเพิ่มปฏิทินวันหยุดไทยใน Google Calendar'),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      
      for (final calendar in holidayCalendars) {
        print('🎄 [DEBUG] Holiday calendar: ${calendar.name} (ID: ${calendar.id})');
      }

      // Use the first calendar found and load holidays for current year
      print('🎄 [DEBUG] Using calendar: ${holidayCalendars.first.name}');
      holidayService.setHolidayCalendar(holidayCalendars.first);
      print('🎄 [DEBUG] Loading holidays for year ${DateTime.now().year}...');
      await holidayService.loadHolidaysForYear(DateTime.now().year);

      // Get the cached holidays
      final holidays = holidayService.cachedHolidays;
      final calendarInfo = holidayService.holidayCalendarInfo;

      // Show debug information
      if (holidays.isNotEmpty) {
        final today = DateTime.now();
        final isHolidayToday = await holidayService.isHoliday(today);
        
        // Find next few holidays from today
        final upcomingHolidays = holidays
            .where((holiday) => holiday.isAfter(today.subtract(const Duration(days: 1))))
            .take(5)
            .toList();

        // Console debug logs
        print('🎄 [DEBUG] Holiday Calendar Info: $calendarInfo');
        print('🎄 [DEBUG] Today is holiday: $isHolidayToday');
        print('🎄 [DEBUG] Total holidays in ${DateTime.now().year}: ${holidays.length}');
        print('🎄 [DEBUG] All holidays: ${holidays.map((h) => "${h.day}/${h.month}/${h.year}").join(", ")}');
        print('🎄 [DEBUG] Upcoming holidays: ${upcomingHolidays.map((h) => "${h.day}/${h.month}").join(", ")}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'วันนี้เป็นวันหยุด: ${isHolidayToday ? "ใช่" : "ไม่"}\n'
                'พบ ${holidays.length} วันหยุดในปี ${DateTime.now().year}\n'
                'วันหยุดถัดไป 5 วัน: ${upcomingHolidays.map((h) => "${h.day}/${h.month}").join(", ")}'
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่พบวันหยุดในปฏิทิน'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการดึงข้อมูลวันหยุด: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}