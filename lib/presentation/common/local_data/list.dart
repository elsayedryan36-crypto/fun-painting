import 'dart:ui';

import '../resources/assets_manager.dart';
import 'Class.dart';
import 'package:fun_painting/presentation/common/resources/color_manager.dart';

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
    ColorManager.hexFFB71C1C,
    ColorManager.hexFFF44336,
    ColorManager.hexFFE57373,
    ColorManager.hexFFEF9A9A,
    ColorManager.hexFFFFCDD2,
    ColorManager.hexFFFFEBEE,
  ]),
  ColorGroup("Orange", [
    ColorManager.hexFFE65100,
    ColorManager.hexFFF57C00,
    ColorManager.hexFFFB8C00,
    ColorManager.hexFFFFB74D,
    ColorManager.hexFFFFE0B2,
    ColorManager.hexFFFFF3E0,
  ]),
  ColorGroup("Yellow", [
    ColorManager.hexFFF57F17,
    ColorManager.hexFFFBC02D,
    ColorManager.hexFFFFEB3B,
    ColorManager.hexFFFFF176,
    ColorManager.hexFFFFF9C4,
    ColorManager.hexFFFFFDE7,
  ]),
  ColorGroup("Green", [
    ColorManager.hexFF1B5E20,
    ColorManager.hexFF388E3C,
    ColorManager.hexFF4CAF50,
    ColorManager.hexFF81C784,
    ColorManager.hexFFC8E6C9,
    ColorManager.hexFFE8F5E9,
  ]),
  ColorGroup("Teal", [
    ColorManager.hexFF004D40,
    ColorManager.hexFF00796B,
    ColorManager.hexFF009688,
    ColorManager.hexFF4DB6AC,
    ColorManager.hexFFB2DFDB,
    ColorManager.hexFFE0F2F1,
  ]),
  ColorGroup("Blue", [
    ColorManager.hexFF0D47A1,
    ColorManager.hexFF2196F3,
    ColorManager.hexFF1976D2,
    ColorManager.hexFF64B5F6,
    ColorManager.hexFF90CAF9,
    ColorManager.hexFFE3F2FD,
  ]),
  ColorGroup("Indigo", [
    ColorManager.hexFF1A237E,
    ColorManager.hexFF303F9F,
    ColorManager.hexFF3F51B5,
    ColorManager.hexFF7986CB,
    ColorManager.hexFF9FA8DA,
    ColorManager.hexFFE8EAF6,
  ]),
  ColorGroup("Purple", [
    ColorManager.hexFF4A148C,
    ColorManager.hexFF7B1FA2,
    ColorManager.hexFF9C27B0,
    ColorManager.hexFFBA68C8,
    ColorManager.hexFFCE93D8,
    ColorManager.hexFFF3E5F5,
  ]),
  ColorGroup("Pink", [
    ColorManager.hexFF880E4F,
    ColorManager.hexFFC2185B,
    ColorManager.hexFFE91E63,
    ColorManager.hexFFF48FB1,
    ColorManager.hexFFF8BBD0,
    ColorManager.hexFFFCE4EC,
  ]),
  ColorGroup("Brown", [
    ColorManager.hexFF3E2723,
    ColorManager.hexFF5D4037,
    ColorManager.hexFF795548,
    ColorManager.hexFFA1887F,
    ColorManager.hexFFD7CCC8,
    ColorManager.hexFFEFEBE9,
  ]),
  ColorGroup("Gray", [
    ColorManager.hexFF212121,
    ColorManager.hexFF616161,
    ColorManager.lightGrey,
    ColorManager.hexFFBDBDBD,
    ColorManager.hexFFE0E0E0,
    ColorManager.hexFFFAFAFA,
  ]),
  ColorGroup("Black & White", [
    ColorManager.black,
    ColorManager.hexFF333333,
    ColorManager.hexFF666666,
    ColorManager.hexFFCCCCCC,
    ColorManager.hexFFF5F5F5,
    ColorManager.white,
  ]),
  ColorGroup("Neon", [
    ColorManager.hexFFFF6EC7, // Neon Pink
    ColorManager.hexFF39FF14, // Neon Green
    ColorManager.hexFF04D9FF, // Neon Blue
    ColorManager.hexFFFFFF33, // Neon Yellow
    ColorManager.hexFFFF5F1F, // Neon Orange
    ColorManager.hexFFBC13FE, // Neon Purple
  ]),
];
