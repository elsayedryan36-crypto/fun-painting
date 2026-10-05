import 'package:hive/hive.dart';

part 'coloring_save_model.g.dart';

@HiveType(typeId: 30)
class ColoringSaveModel extends HiveObject {

  @HiveField(0)
  String imageId;

  @HiveField(1)
  List<RegionSaveModel> regions;

  ColoringSaveModel({
    required this.imageId,
    required this.regions,
  });
}

@HiveType(typeId: 31)
class RegionSaveModel {

  @HiveField(0)
  int fillColor;

  @HiveField(1)
  int fillStyle;

  @HiveField(2)
  List<StrokeSaveModel> strokes;

  RegionSaveModel({
    required this.fillColor,
    required this.fillStyle,
    required this.strokes,
  });
}

@HiveType(typeId: 32)
class StrokeSaveModel {
  

  @HiveField(0)
  List<double> points;

  @HiveField(1)
  int color;

  @HiveField(2)
  int style;

  @HiveField(3)
  String? stampAsset;

  @HiveField(4)
  double stampSize;

  @HiveField(5)
String? wallpaperAsset;

StrokeSaveModel({
  required this.points,
  required this.color,
  required this.style,
  this.stampAsset,
  required this.stampSize,
  this.wallpaperAsset,
});
}