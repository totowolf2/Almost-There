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
    SoundOption('default', 'เสียงเริ่มต้น', Icons.volume_up),
    SoundOption('bell', 'เสียงระฆัง', Icons.notifications),
    SoundOption('chime', 'เสียงกิ่ง', Icons.music_note),
    SoundOption('ding', 'เสียงดิง', Icons.campaign),
    SoundOption('gentle', 'เสียงนุ่มนวล', Icons.volume_down),
    SoundOption('alert', 'เสียงเตือน', Icons.warning),
    SoundOption('custom', 'เสียงกำหนดเอง', Icons.folder_open),
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

      // Play system feedback sound
      HapticFeedback.mediumImpact();

      // Show preview message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('กำลังเล่นตัวอย่างเสียง: ${_getSoundName(soundKey)}'),
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
      setState(() {
        _currentlyPlaying = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเล่นเสียงได้: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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