import 'dart:ui';

import 'package:flutter/material.dart';

class Collections {
  final String imagePath;
final Future<void> Function() onTap;
  Collections({required this.imagePath, required this.onTap});
}

/// A named group of colors
class ColorGroup {
  final String name;
  final List<Color> colors;

  ColorGroup(this.name, this.colors);
}
