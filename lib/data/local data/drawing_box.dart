import 'package:fun_painting/data/local%20data/hive.dart';
import 'package:hive/hive.dart';


class DrawingBox {

  static Box<DrawingModel> get box =>
      Hive.box<DrawingModel>("drawings");

}