import 'package:hive_flutter/hive_flutter.dart';
import '../resolution.dart';

class ResolutionAdapter extends TypeAdapter<Resolution> {
  @override
  final int typeId = 3;

  @override
  Resolution read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Resolution(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      resolution: fields[2] as String,
      dataSnapshot: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Resolution obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.resolution)
      ..writeByte(3)
      ..write(obj.dataSnapshot);
  }
}