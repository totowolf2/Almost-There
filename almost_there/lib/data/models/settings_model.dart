import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 3)
class SettingsModel extends HiveObject {
  // Default values for new alarms
  @HiveField(0)
  String defaultAlarmType; // 'oneTime' or 'recurring'

  @HiveField(1)
  double defaultRadius; // in meters

  @HiveField(2)
  int defaultSnoozeMinutes;

  @HiveField(3)
  String defaultSound;

  @HiveField(4)
  bool defaultShowLiveCard;

  // Live Card settings
  @HiveField(5)
  bool globalLiveCardEnabled;

  @HiveField(6)
  int liveCardUpdateIntervalSeconds;

  @HiveField(7)
  double liveCardMinDistanceMeters;

  // Overlap and limits
  @HiveField(8)
  int maxActiveAlarms;

  @HiveField(9)
  int coolOffMinutes; // Time between triggers for same alarm

  @HiveField(10)
  int debounceSeconds; // Prevent rapid re-triggers

  @HiveField(11)
  int suppressionSeconds; // Suppress other alarms after one triggers

  // Notification settings
  @HiveField(12)
  bool notificationsEnabled;

  @HiveField(13)
  bool soundEnabled;

  @HiveField(14)
  bool vibrationEnabled;

  // Theme and display
  @HiveField(15)
  String themeMode; // 'system', 'light', 'dark'

  @HiveField(16)
  String language; // 'system', 'en', 'th'

  // Battery optimization
  @HiveField(17)
  bool batteryOptimizationShown;

  @HiveField(18)
  bool permissionTutorialShown;

  SettingsModel({
    this.defaultAlarmType = 'oneTime',
    this.defaultRadius = 300.0,
    this.defaultSnoozeMinutes = 5,
    this.defaultSound = 'default',
    this.defaultShowLiveCard = true,
    this.globalLiveCardEnabled = true,
    this.liveCardUpdateIntervalSeconds = 45,
    this.liveCardMinDistanceMeters = 200.0,
    this.maxActiveAlarms = 30,
    this.coolOffMinutes = 10,
    this.debounceSeconds = 120,
    this.suppressionSeconds = 15,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.themeMode = 'system',
    this.language = 'system',
    this.batteryOptimizationShown = false,
    this.permissionTutorialShown = false,
  });

  // Helper getters
  bool get isDefaultOneTime => defaultAlarmType == 'oneTime';
  bool get isDefaultRecurring => defaultAlarmType == 'recurring';

  bool get shouldShowLiveCards => globalLiveCardEnabled && notificationsEnabled;

  String get formattedDefaultRadius {
    if (defaultRadius >= 1000) {
      return '${(defaultRadius / 1000).toStringAsFixed(1)} km';
    }
    return '${defaultRadius.toInt()} m';
  }

  String get formattedLiveCardInterval {
    if (liveCardUpdateIntervalSeconds >= 60) {
      final minutes = liveCardUpdateIntervalSeconds ~/ 60;
      return '$minutes min';
    }
    return '$liveCardUpdateIntervalSeconds sec';
  }

  // Create default settings instance
  static SettingsModel defaultSettings() {
    return SettingsModel();
  }

  // Create copy with modifications
  SettingsModel copyWith({
    String? defaultAlarmType,
    double? defaultRadius,
    int? defaultSnoozeMinutes,
    String? defaultSound,
    bool? defaultShowLiveCard,
    bool? globalLiveCardEnabled,
    int? liveCardUpdateIntervalSeconds,
    double? liveCardMinDistanceMeters,
    int? maxActiveAlarms,
    int? coolOffMinutes,
    int? debounceSeconds,
    int? suppressionSeconds,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? themeMode,
    String? language,
    bool? batteryOptimizationShown,
    bool? permissionTutorialShown,
  }) {
    return SettingsModel(
      defaultAlarmType: defaultAlarmType ?? this.defaultAlarmType,
      defaultRadius: defaultRadius ?? this.defaultRadius,
      defaultSnoozeMinutes: defaultSnoozeMinutes ?? this.defaultSnoozeMinutes,
      defaultSound: defaultSound ?? this.defaultSound,
      defaultShowLiveCard: defaultShowLiveCard ?? this.defaultShowLiveCard,
      globalLiveCardEnabled: globalLiveCardEnabled ?? this.globalLiveCardEnabled,
      liveCardUpdateIntervalSeconds: liveCardUpdateIntervalSeconds ?? this.liveCardUpdateIntervalSeconds,
      liveCardMinDistanceMeters: liveCardMinDistanceMeters ?? this.liveCardMinDistanceMeters,
      maxActiveAlarms: maxActiveAlarms ?? this.maxActiveAlarms,
      coolOffMinutes: coolOffMinutes ?? this.coolOffMinutes,
      debounceSeconds: debounceSeconds ?? this.debounceSeconds,
      suppressionSeconds: suppressionSeconds ?? this.suppressionSeconds,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      batteryOptimizationShown: batteryOptimizationShown ?? this.batteryOptimizationShown,
      permissionTutorialShown: permissionTutorialShown ?? this.permissionTutorialShown,
    );
  }

  @override
  String toString() {
    return 'SettingsModel(defaultType: $defaultAlarmType, defaultRadius: $defaultRadius)';
  }
}