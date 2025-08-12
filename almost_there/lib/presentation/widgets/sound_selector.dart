import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class SoundSelector extends StatefulWidget {
  final String currentSound;
  final ValueChanged<String> onSoundSelected;

  const SoundSelector({
    super.key,
    required this.currentSound,
    required this.onSoundSelected,
  });

  @override
  State<SoundSelector> createState() => _SoundSelectorState();
}

class _SoundSelectorState extends State<SoundSelector> {
  late AudioPlayer _audioPlayer;
  String? _currentlyPlaying;
  
  final List<SoundOption> _sounds = [
    SoundOption('alarm', 'เสียงปลุกเริ่มต้น', Icons.alarm),
    SoundOption('notification', 'เสียงแจ้งเตือน', Icons.notifications),
    SoundOption('ringtone', 'เสียงเรียกเข้า', Icons.phone_in_talk),
    SoundOption('system_alert', 'เสียงเตือนระบบ', Icons.warning),
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'เลือกเสียงแจ้งเตือน',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก'),
                ),
              ],
            ),
          ),
          
          // Scrollable sound list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _sounds.length,
              itemBuilder: (context, index) => _buildSoundTile(_sounds[index]),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSoundTile(SoundOption sound) {
    final isSelected = widget.currentSound == sound.key;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(sound.icon),
      title: Text(sound.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _currentlyPlaying == sound.key
                  ? Icons.stop
                  : Icons.play_arrow,
            ),
            onPressed: () => _previewSound(sound.key),
            tooltip: _currentlyPlaying == sound.key ? 'หยุด' : 'ฟังตัวอย่าง',
            visualDensity: VisualDensity.compact,
          ),
          Radio<String>(
            value: sound.key,
            groupValue: widget.currentSound,
            onChanged: (value) {
              if (value != null) {
                widget.onSoundSelected(value);
              }
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      selected: isSelected,
      onTap: () {
        if (sound.key == 'custom') {
          _selectCustomSound();
        } else {
          widget.onSoundSelected(sound.key);
        }
      },
    );
  }

  void _previewSound(String soundKey) async {
    try {
      // If currently playing this sound, stop it
      if (_currentlyPlaying == soundKey) {
        setState(() {
          _currentlyPlaying = null;
        });
        return;
      }

      // Stop any currently playing sound
      if (_currentlyPlaying != null) {
        setState(() {
          _currentlyPlaying = null;
        });
      }

      setState(() {
        _currentlyPlaying = soundKey;
      });

      // เล่นเสียงที่แตกต่างกันตามประเภทที่เลือก
      await _playSpecificSound(soundKey);

      // Show preview message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 เล่นเสียง: ${_getSoundName(soundKey)}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Auto-stop after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (_currentlyPlaying == soundKey && mounted) {
          setState(() {
            _currentlyPlaying = null;
          });
        }
      });

    } catch (e) {
      // Fallback เล่นเสียง system
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.mediumImpact();
      
      setState(() {
        _currentlyPlaying = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 ตัวอย่างเสียง: ${_getSoundName(soundKey)} (Fallback)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _playSpecificSound(String soundKey) async {
    // เล่นเสียงตัวอย่างโดยใช้เสียงจริงของระบบ
    switch (soundKey) {
      case 'alarm':
        // เสียงปลุกเริ่มต้น - ใช้ระบบปลุกหลัก
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 300));
        HapticFeedback.mediumImpact();
        break;
        
      case 'notification':
        // เสียงแจ้งเตือนปกติ
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.lightImpact();
        break;
        
      case 'ringtone':
        // เสียงเรียกเข้า - simulation ด้วย click pattern
        SystemSound.play(SystemSoundType.click);
        await Future.delayed(const Duration(milliseconds: 200));
        SystemSound.play(SystemSoundType.click);
        await Future.delayed(const Duration(milliseconds: 200));
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.mediumImpact();
        break;
        
      case 'system_alert':
        // เสียงเตือนระบบที่เข้มข้น
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 500));
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.heavyImpact();
        break;
        
      default:
        // เสียงปลุกเริ่มต้น
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.mediumImpact();
        break;
    }
  }

  void _selectCustomSound() {
    // TODO: Implement custom sound file picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('การเลือกเสียงกำหนดเองจะพร้อมใช้งานเร็วๆ นี้'),
      ),
    );
  }

  String _getSoundName(String soundKey) {
    return _sounds.firstWhere(
      (sound) => sound.key == soundKey,
      orElse: () => SoundOption(soundKey, 'ไม่ทราบ', Icons.help),
    ).name;
  }
}

class SoundOption {
  final String key;
  final String name;
  final IconData icon;

  const SoundOption(this.key, this.name, this.icon);
}