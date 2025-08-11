// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 3;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      defaultAlarmType: fields[0] as String,
      defaultRadius: fields[1] as double,
      defaultSnoozeMinutes: fields[2] as int,
      defaultSound: fields[3] as String,
      defaultShowLiveCard: fields[4] as bool,
      globalLiveCardEnabled: fields[5] as bool,
      liveCardUpdateIntervalSeconds: fields[6] as int,
      liveCardMinDistanceMeters: fields[7] as double,
      maxActiveAlarms: fields[8] as int,
      coolOffMinutes: fields[9] as int,
      debounceSeconds: fields[10] as int,
      suppressionSeconds: fields[11] as int,
      notificationsEnabled: fields[12] as bool,
      soundEnabled: fields[13] as bool,
      vibrationEnabled: fields[14] as bool,
      themeMode: fields[15] as String,
      language: fields[16] as String,
      batteryOptimizationShown: fields[17] as bool,
      permissionTutorialShown: fields[18] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.defaultAlarmType)
      ..writeByte(1)
      ..write(obj.defaultRadius)
      ..writeByte(2)
      ..write(obj.defaultSnoozeMinutes)
      ..writeByte(3)
      ..write(obj.defaultSound)
      ..writeByte(4)
      ..write(obj.defaultShowLiveCard)
      ..writeByte(5)
      ..write(obj.globalLiveCardEnabled)
      ..writeByte(6)
      ..write(obj.liveCardUpdateIntervalSeconds)
      ..writeByte(7)
      ..write(obj.liveCardMinDistanceMeters)
      ..writeByte(8)
      ..write(obj.maxActiveAlarms)
      ..writeByte(9)
      ..write(obj.coolOffMinutes)
      ..writeByte(10)
      ..write(obj.debounceSeconds)
      ..writeByte(11)
      ..write(obj.suppressionSeconds)
      ..writeByte(12)
      ..write(obj.notificationsEnabled)
      ..writeByte(13)
      ..write(obj.soundEnabled)
      ..writeByte(14)
      ..write(obj.vibrationEnabled)
      ..writeByte(15)
      ..write(obj.themeMode)
      ..writeByte(16)
      ..write(obj.language)
      ..writeByte(17)
      ..write(obj.batteryOptimizationShown)
      ..writeByte(18)
      ..write(obj.permissionTutorialShown);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
