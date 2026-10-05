import 'package:hive/hive.dart';

part 'hive.g.dart';

@HiveType(typeId: 26)
class DrawingModel extends HiveObject {

  @HiveField(0)
  String imageId;

  /// key = path id
  /// value = color
  @HiveField(1)
  Map<String,int> colors;

  DrawingModel({
    required this.imageId,
    required this.colors,
  });
}