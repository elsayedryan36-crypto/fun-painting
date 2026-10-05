import 'dart:ui';

import '../resources/assets_manager.dart';
import 'Class.dart';

List<String> junglePhotos = List.generate(
  89,
  (index) => ZooAssets.asset(index + 1),
);

List<String> seaPhotos = List.generate(
  62,
  (index) => SeaAssets.asset(index + 1),
);

List<String> dragonsPhotos = List.generate(
  34,
  (index) => DragonsAssets.asset(index + 1),
);

List<String> fairyPhotos = List.generate(
 57,
  (index) => FairyAssets.asset(index + 1),
);

List<String> spacePhotos = List.generate(
  36,
  (index) => SpaceAssets.asset(index + 1),
);


List<String> circisPhotos = List.generate(
  60,
  (index) => CirclesAssets.asset(index + 1),
);


List<String> transportationPhotos = List.generate(
  28,
  (index) => TransportationAssets.asset(index + 1),
);

List<String> foodPhotos = List.generate(
  74,
  (index) => FoodAssets.asset(index + 1),
);

List<String> flowersPhotos = List.generate(
  9,
  (index) => FlowersAssets.asset(index + 1),
);


List<String> lettersPhotos = List.generate(
  26,
  (index) => LettersAssets.asset(index + 1),
);


List<String> nummbersPhotos = List.generate(
 10,
  (index) => NumbersAssets.asset(index + 1),
);

List<String> Pattern = List.generate(
79,
  (index) => PatternAssets.asset(index + 1),
);


List<String> stamps = List.generate(
 501,
  (index) => StampsAssets.asset(index + 1),
);



final List<ColorGroup> groupedPalette = [
  ColorGroup("Red", [
    Color(0xFFB71C1C),
    Color(0xFFF44336),
    Color(0xFFE57373),
    Color(0xFFEF9A9A),
    Color(0xFFFFCDD2),
    Color(0xFFFFEBEE),
  ]),
  ColorGroup("Orange", [
    Color(0xFFE65100),
    Color(0xFFF57C00),
    Color(0xFFFB8C00),
    Color(0xFFFFB74D),
    Color(0xFFFFE0B2),
    Color(0xFFFFF3E0),
  ]),
  ColorGroup("Yellow", [
    Color(0xFFF57F17),
    Color(0xFFFBC02D),
    Color(0xFFFFEB3B),
    Color(0xFFFFF176),
    Color(0xFFFFF9C4),
    Color(0xFFFFFDE7),
  ]),
  ColorGroup("Green", [
    Color(0xFF1B5E20),
    Color(0xFF388E3C),
    Color(0xFF4CAF50),
    Color(0xFF81C784),
    Color(0xFFC8E6C9),
    Color(0xFFE8F5E9),
  ]),
  ColorGroup("Teal", [
    Color(0xFF004D40),
    Color(0xFF00796B),
    Color(0xFF009688),
    Color(0xFF4DB6AC),
    Color(0xFFB2DFDB),
    Color(0xFFE0F2F1),
  ]),
  ColorGroup("Blue", [
    Color(0xFF0D47A1),
    Color(0xFF2196F3),
    Color(0xFF1976D2),
    Color(0xFF64B5F6),
    Color(0xFF90CAF9),
    Color(0xFFE3F2FD),
  ]),
  ColorGroup("Indigo", [
    Color(0xFF1A237E),
    Color(0xFF303F9F),
    Color(0xFF3F51B5),
    Color(0xFF7986CB),
    Color(0xFF9FA8DA),
    Color(0xFFE8EAF6),
  ]),
  ColorGroup("Purple", [
    Color(0xFF4A148C),
    Color(0xFF7B1FA2),
    Color(0xFF9C27B0),
    Color(0xFFBA68C8),
    Color(0xFFCE93D8),
    Color(0xFFF3E5F5),
  ]),
  ColorGroup("Pink", [
    Color(0xFF880E4F),
    Color(0xFFC2185B),
    Color(0xFFE91E63),
    Color(0xFFF48FB1),
    Color(0xFFF8BBD0),
    Color(0xFFFCE4EC),
  ]),
  ColorGroup("Brown", [
    Color(0xFF3E2723),
    Color(0xFF5D4037),
    Color(0xFF795548),
    Color(0xFFA1887F),
    Color(0xFFD7CCC8),
    Color(0xFFEFEBE9),
  ]),
  ColorGroup("Gray", [
    Color(0xFF212121),
    Color(0xFF616161),
    Color(0xFF9E9E9E),
    Color(0xFFBDBDBD),
    Color(0xFFE0E0E0),
    Color(0xFFFAFAFA),
  ]),
  ColorGroup("Black & White", [
    Color(0xFF000000),
    Color(0xFF333333),
    Color(0xFF666666),
    Color(0xFFCCCCCC),
    Color(0xFFF5F5F5),
    Color(0xFFFFFFFF),
  ]),
  ColorGroup("Neon", [
    Color(0xFFFF6EC7), // Neon Pink
    Color(0xFF39FF14), // Neon Green
    Color(0xFF04D9FF), // Neon Blue
    Color(0xFFFFFF33), // Neon Yellow
    Color(0xFFFF5F1F), // Neon Orange
    Color(0xFFBC13FE), // Neon Purple
  ]),
];


