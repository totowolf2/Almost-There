import 'package:flutter/material.dart';

import '../../data/models/alarm_model.dart';
import '../theme/color_schemes.dart';

class AlarmItemWidget extends StatelessWidget {
  final AlarmModel alarm;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onToggle;
  final ValueChanged<bool> onSelect;

  const AlarmItemWidget({
    super.key,
    required this.alarm,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorExtension = Theme.of(context).extension<AppColorExtension>()!;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selection checkbox or enable/disable switch
              if (isMultiSelectMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onSelect(value ?? false),
                )
              else
                Switch(
                  value: alarm.enabled,
                  onChanged: (value) {
                    print('🔄 [DEBUG] Switch toggled for ${alarm.label}: $value (was ${alarm.enabled})');
                    onToggle(value);
                  },
                ),
              
              const SizedBox(width: 16),
              
              // Alarm details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alarm label and type
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alarm.label,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: alarm.isOneTime 
                                ? Theme.of(context).colorScheme.tertiary
                                : Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${alarm.isOneTime ? 'One-time' : 'Recurring'} ${alarm.formattedRadius}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: alarm.isOneTime 
                                  ? Theme.of(context).colorScheme.onTertiary
                                  : Theme.of(context).colorScheme.onSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Location coordinates
                    Text(
                      alarm.location.coordinates,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorExtension.distanceText,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Additional info row
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Start time indicator
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              alarm.formattedStartTime,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        
                        // Days for recurring alarms
                        if (alarm.isRecurring)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                alarm.recurringDaysText,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        
                        // Sound indicator
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              alarm.soundPath == 'default' ? Icons.volume_up : Icons.music_note,
                              size: 16,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              alarm.soundPath == 'default' ? 'Default' : 'Custom',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        
                        // Live card indicator
                        if (alarm.showLiveCard)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Live Card',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Status indicators
                    if (alarm.isExpired || !alarm.enabled || (alarm.isOneTime && !alarm.isActive) || _isWaitingForStartTime())
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            if (alarm.isExpired) ...[
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: colorExtension.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Expired',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorExtension.warning,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ] else if (!alarm.enabled) ...[
                              Icon(
                                Icons.power_off,
                                size: 16,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Disabled',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ] else if (_isWaitingForStartTime()) ...[
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'รอถึงเวลา ${alarm.formattedStartTime}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ] else if (alarm.isOneTime && !alarm.isActive) ...[
                              Icon(
                                Icons.play_arrow,
                                size: 16,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tap to Activate',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            
                            if (alarm.lastTriggeredAt != null) ...[
                              const SizedBox(width: 16),
                              Text(
                                'Last: ${_formatLastTriggered(alarm.lastTriggeredAt!)}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isWaitingForStartTime() {
    if (alarm.startTime == null || !alarm.enabled) return false;
    
    if (alarm.isOneTime && !alarm.isActive) {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;
      final startMinutes = alarm.startTime!.hour * 60 + alarm.startTime!.minute;
      return currentMinutes < startMinutes;
    }
    
    return false;
  }

  String _formatLastTriggered(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}