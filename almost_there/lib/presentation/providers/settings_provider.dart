import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/settings_model.dart';

// Settings repository provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

// Settings provider - manages app settings
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});

class SettingsNotifier extends StateNotifier<SettingsModel> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(SettingsModel.defaultSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final settings = _repository.getSettings();
    state = settings ?? SettingsModel.defaultSettings();
  }

  // Default alarm settings
  Future<void> updateDefaultAlarmType(String type) async {
    final updated = state.copyWith(defaultAlarmType: type);
    await _save(updated);
  }

  Future<void> updateDefaultRadius(double radius) async {
    final updated = state.copyWith(defaultRadius: radius);
    await _save(updated);
  }

  Future<void> updateDefaultSnooze(int minutes) async {
    final updated = state.copyWith(defaultSnoozeMinutes: minutes);
    await _save(updated);
  }

  Future<void> updateDefaultSound(String sound) async {
    final updated = state.copyWith(defaultSound: sound);
    await _save(updated);
  }

  Future<void> updateDefaultShowLiveCard(bool show) async {
    final updated = state.copyWith(defaultShowLiveCard: show);
    await _save(updated);
  }

  // Live card settings
  Future<void> updateGlobalLiveCardEnabled(bool enabled) async {
    final updated = state.copyWith(globalLiveCardEnabled: enabled);
    await _save(updated);
  }

  Future<void> updateLiveCardInterval(int seconds) async {
    final updated = state.copyWith(liveCardUpdateIntervalSeconds: seconds);
    await _save(updated);
  }

  Future<void> updateLiveCardMinDistance(double meters) async {
    final updated = state.copyWith(liveCardMinDistanceMeters: meters);
    await _save(updated);
  }

  // Overlap and limits
  Future<void> updateMaxActiveAlarms(int max) async {
    final updated = state.copyWith(maxActiveAlarms: max);
    await _save(updated);
  }

  Future<void> updateCoolOffMinutes(int minutes) async {
    final updated = state.copyWith(coolOffMinutes: minutes);
    await _save(updated);
  }

  Future<void> updateDebounceSeconds(int seconds) async {
    final updated = state.copyWith(debounceSeconds: seconds);
    await _save(updated);
  }

  Future<void> updateSuppressionSeconds(int seconds) async {
    final updated = state.copyWith(suppressionSeconds: seconds);
    await _save(updated);
  }

  // Notification settings
  Future<void> updateNotificationsEnabled(bool enabled) async {
    final updated = state.copyWith(notificationsEnabled: enabled);
    await _save(updated);
  }

  Future<void> updateSoundEnabled(bool enabled) async {
    final updated = state.copyWith(soundEnabled: enabled);
    await _save(updated);
  }

  Future<void> updateVibrationEnabled(bool enabled) async {
    final updated = state.copyWith(vibrationEnabled: enabled);
    await _save(updated);
  }

  // Theme and display
  Future<void> updateThemeMode(String mode) async {
    final updated = state.copyWith(themeMode: mode);
    await _save(updated);
  }

  Future<void> updateLanguage(String language) async {
    final updated = state.copyWith(language: language);
    await _save(updated);
  }

  // Tutorial and onboarding
  Future<void> markBatteryOptimizationShown() async {
    final updated = state.copyWith(batteryOptimizationShown: true);
    await _save(updated);
  }

  Future<void> markPermissionTutorialShown() async {
    final updated = state.copyWith(permissionTutorialShown: true);
    await _save(updated);
  }

  // Bulk update settings
  Future<void> updateSettings(SettingsModel settings) async {
    await _save(settings);
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    final defaults = SettingsModel.defaultSettings();
    // Preserve tutorial/onboarding states
    final updated = defaults.copyWith(
      batteryOptimizationShown: state.batteryOptimizationShown,
      permissionTutorialShown: state.permissionTutorialShown,
    );
    await _save(updated);
  }

  Future<void> _save(SettingsModel settings) async {
    await _repository.saveSettings(settings);
    state = settings;
  }
}

class SettingsRepository {
  static const String _settingsKey = 'app_settings';
  Box<SettingsModel> get _settingsBox => Hive.box<SettingsModel>('settings');

  SettingsModel? getSettings() {
    return _settingsBox.get(_settingsKey);
  }

  Future<void> saveSettings(SettingsModel settings) async {
    await _settingsBox.put(_settingsKey, settings);
  }

  Future<void> clearSettings() async {
    await _settingsBox.delete(_settingsKey);
  }
}