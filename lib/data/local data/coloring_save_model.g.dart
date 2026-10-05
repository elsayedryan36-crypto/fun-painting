// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coloring_save_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ColoringSaveModelAdapter extends TypeAdapter<ColoringSaveModel> {
  @override
  final int typeId = 30;

  @override
  ColoringSaveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ColoringSaveModel(
      imageId: fields[0] as String,
      regions: (fields[1] as List).cast<RegionSaveModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, ColoringSaveModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.imageId)
      ..writeByte(1)
      ..write(obj.regions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColoringSaveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RegionSaveModelAdapter extends TypeAdapter<RegionSaveModel> {
  @override
  final int typeId = 31;

  @override
  RegionSaveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RegionSaveModel(
      fillColor: fields[0] as int,
      fillStyle: fields[1] as int,
      strokes: (fields[2] as List).cast<StrokeSaveModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, RegionSaveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.fillColor)
      ..writeByte(1)
      ..write(obj.fillStyle)
      ..writeByte(2)
      ..write(obj.strokes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegionSaveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StrokeSaveModelAdapter extends TypeAdapter<StrokeSaveModel> {
  @override
  final int typeId = 32;

  @override
  StrokeSaveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StrokeSaveModel(
      points: (fields[0] as List).cast<double>(),
      color: fields[1] as int,
      style: fields[2] as int,
      stampAsset: fields[3] as String?,
      stampSize: fields[4] as double,
      wallpaperAsset: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StrokeSaveModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.points)
      ..writeByte(1)
      ..write(obj.color)
      ..writeByte(2)
      ..write(obj.style)
      ..writeByte(3)
      ..write(obj.stampAsset)
      ..writeByte(4)
      ..write(obj.stampSize)
      ..writeByte(5)
      ..write(obj.wallpaperAsset);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokeSaveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
