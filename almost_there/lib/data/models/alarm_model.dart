import 'package:hive/hive.dart';
import 'location_model.dart';

part 'alarm_model.g.dart';

@HiveType(typeId: 0)
enum AlarmType {
  @HiveField(0)
  oneTime,

  @HiveField(1)
  recurring,
}

@HiveType(typeId: 1)
class AlarmModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String label;

  @HiveField(2)
  AlarmType type;

  @HiveField(3)
  LocationModel location;

  @HiveField(4)
  double radius; // in meters

  @HiveField(5)
  bool enabled;

  @HiveField(6)
  bool showLiveCard;

  @HiveField(7)
  String soundPath; // Default or custom sound path

  @HiveField(8)
  int snoozeMinutes;

  @HiveField(9)
  List<int> recurringDays; // 0 = Sunday, 1 = Monday, etc.

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime? lastTriggeredAt;

  @HiveField(12)
  bool isActive; // For one-time alarms: whether currently listening for geofence

  @HiveField(13)
  String? groupName;

  @HiveField(14)
  DateTime? expiresAt; // For one-time alarms: auto-disable after 24 hours

  AlarmModel({
    required this.id,
    required this.label,
    required this.type,
    required this.location,
    this.radius = 300.0,
    this.enabled = true,
    this.showLiveCard = true,
    this.soundPath = 'default',
    this.snoozeMinutes = 5,
    this.recurringDays = const [],
    required this.createdAt,
    this.lastTriggeredAt,
    this.isActive = false,
    this.groupName,
    this.expiresAt,
  });

  // Helper methods
  bool get isOneTime => type == AlarmType.oneTime;
  bool get isRecurring => type == AlarmType.recurring;

  bool get isExpired {
    if (type == AlarmType.oneTime && expiresAt != null) {
      return DateTime.now().isAfter(expiresAt!);
    }
    return false;
  }

  bool shouldTriggerToday() {
    if (type == AlarmType.oneTime) {
      return enabled && isActive && !isExpired;
    }
    
    if (type == AlarmType.recurring) {
      final today = DateTime.now().weekday % 7; // Convert to 0 = Sunday format
      return enabled && recurringDays.contains(today);
    }
    
    return false;
  }

  String get formattedRadius {
    if (radius >= 1000) {
      return '${(radius / 1000).toStringAsFixed(1)} km';
    }
    return '${radius.toInt()} m';
  }

  String get recurringDaysText {
    if (recurringDays.isEmpty) return 'Never';
    
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final sortedDays = [...recurringDays]..sort();
    
    if (sortedDays.length == 7) return 'Daily';
    if (sortedDays.length == 5 && 
        sortedDays.every((day) => day >= 1 && day <= 5)) {
      return 'Weekdays';
    }
    
    return sortedDays.map((day) => dayNames[day]).join(', ');
  }

  // Create copy with modifications
  AlarmModel copyWith({
    String? id,
    String? label,
    AlarmType? type,
    LocationModel? location,
    double? radius,
    bool? enabled,
    bool? showLiveCard,
    String? soundPath,
    int? snoozeMinutes,
    List<int>? recurringDays,
    DateTime? createdAt,
    DateTime? lastTriggeredAt,
    bool? isActive,
    String? groupName,
    DateTime? expiresAt,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      location: location ?? this.location,
      radius: radius ?? this.radius,
      enabled: enabled ?? this.enabled,
      showLiveCard: showLiveCard ?? this.showLiveCard,
      soundPath: soundPath ?? this.soundPath,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      recurringDays: recurringDays ?? this.recurringDays,
      createdAt: createdAt ?? this.createdAt,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      isActive: isActive ?? this.isActive,
      groupName: groupName ?? this.groupName,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  String toString() {
    return 'AlarmModel(id: $id, label: $label, type: $type, enabled: $enabled)';
  }
}