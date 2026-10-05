// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DrawingModelAdapter extends TypeAdapter<DrawingModel> {
  @override
  final int typeId = 26;

  @override
  DrawingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DrawingModel(
      imageId: fields[0] as String,
      colors: (fields[1] as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, DrawingModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.imageId)
      ..writeByte(1)
      ..write(obj.colors);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
