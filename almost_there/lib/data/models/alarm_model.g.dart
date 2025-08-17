// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmModelAdapter extends TypeAdapter<AlarmModel> {
  @override
  final int typeId = 1;

  @override
  AlarmModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmModel(
      id: fields[0] as String,
      label: fields[1] as String,
      type: fields[2] as AlarmType,
      location: fields[3] as LocationModel,
      radius: fields[4] as double,
      enabled: fields[5] as bool,
      showLiveCard: fields[6] as bool,
      soundPath: fields[7] as String,
      snoozeMinutes: fields[8] as int,
      recurringDays: (fields[9] as List).cast<int>(),
      createdAt: fields[10] as DateTime,
      lastTriggeredAt: fields[11] as DateTime?,
      isActive: fields[12] as bool,
      groupName: fields[13] as String?,
      expiresAt: fields[14] as DateTime?,
      startTimeMinutes: fields[15] as int?,
      skipHolidays: fields[16] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.radius)
      ..writeByte(5)
      ..write(obj.enabled)
      ..writeByte(6)
      ..write(obj.showLiveCard)
      ..writeByte(7)
      ..write(obj.soundPath)
      ..writeByte(8)
      ..write(obj.snoozeMinutes)
      ..writeByte(9)
      ..write(obj.recurringDays)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.lastTriggeredAt)
      ..writeByte(12)
      ..write(obj.isActive)
      ..writeByte(13)
      ..write(obj.groupName)
      ..writeByte(14)
      ..write(obj.expiresAt)
      ..writeByte(15)
      ..write(obj.startTimeMinutes)
      ..writeByte(16)
      ..write(obj.skipHolidays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlarmTypeAdapter extends TypeAdapter<AlarmType> {
  @override
  final int typeId = 0;

  @override
  AlarmType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlarmType.oneTime;
      case 1:
        return AlarmType.recurring;
      default:
        return AlarmType.oneTime;
    }
  }

  @override
  void write(BinaryWriter writer, AlarmType obj) {
    switch (obj) {
      case AlarmType.oneTime:
        writer.writeByte(0);
        break;
      case AlarmType.recurring:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
