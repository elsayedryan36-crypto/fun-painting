// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'painting_save_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedStrokeAdapter extends TypeAdapter<SavedStroke> {
  @override
  final int typeId = 20;

  @override
  SavedStroke read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedStroke(
      points: (fields[0] as List).cast<double>(),
      color: fields[1] as int,
      style: fields[2] as int,
      wallpaperAsset: fields[3] as String?,
      stampAsset: fields[4] as String?,
      stampSize: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SavedStroke obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.points)
      ..writeByte(1)
      ..write(obj.color)
      ..writeByte(2)
      ..write(obj.style)
      ..writeByte(3)
      ..write(obj.wallpaperAsset)
      ..writeByte(4)
      ..write(obj.stampAsset)
      ..writeByte(5)
      ..write(obj.stampSize);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedStrokeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SavedRegionAdapter extends TypeAdapter<SavedRegion> {
  @override
  final int typeId = 21;

  @override
  SavedRegion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedRegion(
      fillColor: fields[0] as int,
      fillStyle: fields[1] as int,
      strokes: (fields[2] as List).cast<SavedStroke>(),
    );
  }

  @override
  void write(BinaryWriter writer, SavedRegion obj) {
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
      other is SavedRegionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaintingSaveAdapter extends TypeAdapter<PaintingSave> {
  @override
  final int typeId = 22;

  @override
  PaintingSave read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaintingSave(
      (fields[0] as List).cast<SavedRegion>(),
    );
  }

  @override
  void write(BinaryWriter writer, PaintingSave obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.regions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaintingSaveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
