import 'package:hive/hive.dart';

part 'painting_save_model.g.dart';

@HiveType(typeId: 20)
class SavedStroke extends HiveObject {
  @HiveField(0)
  List<double> points;

  @HiveField(1)
  int color;

  @HiveField(2)
  int style;

  @HiveField(3)
  String? wallpaperAsset;

  @HiveField(4)
  String? stampAsset;

  @HiveField(5)
  double stampSize;

  SavedStroke({
    required this.points,
    required this.color,
    required this.style,
    this.wallpaperAsset,
    this.stampAsset,
    this.stampSize = 50,
  });
}

@HiveType(typeId: 21)
class SavedRegion extends HiveObject {
  @HiveField(0)
  int fillColor;

  @HiveField(1)
  int fillStyle;

  @HiveField(2)
  List<SavedStroke> strokes;

  SavedRegion({
    required this.fillColor,
    required this.fillStyle,
    required this.strokes,
  });
}

@HiveType(typeId: 22)
class PaintingSave extends HiveObject {
  @HiveField(0)
  List<SavedRegion> regions;

  PaintingSave(this.regions);
}

