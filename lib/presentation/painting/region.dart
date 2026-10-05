// lib/presentation/painting/region.dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// StrokeStyle enum (added new styles)
enum StrokeStyle {
  solid,
  glitter,
  rainbow,
  patternStars,
  patternHearts,
  neon,
  crayon,
  sticker,
  wallpaper, // ✅ NEW
  stampSvg, // ✅ new
}

/// Stroke model carries style
class Stroke {
  String? stampAsset;
  String? wallpaperAsset;
  List<Offset> points; // mutable so we can append
  Color color;
  StrokeStyle style;
  ui.Image? wallpaperImage; // ✅ NEW
  ui.Picture? svgPicture; // ← CHANGED
  double stampSize;
  Size? svgSize; // ← NEW

  Stroke({
    required this.points,
    required this.color,
    this.style = StrokeStyle.solid,
    this.wallpaperImage,
    this.wallpaperAsset,
    this.svgPicture,
    this.stampAsset,
    this.stampSize = 40,
    this.svgSize,
  });
  // Add copyWith method for easier cloning
  Stroke copyWith({
    String? stampAsset,
    String? wallpaperAsset,
    List<Offset>? points,
    Color? color,
    StrokeStyle? style,
    ui.Image? wallpaperImage,
    ui.Picture? svgPicture,
    double? stampSize,
    Size? svgSize,
  }) {
    return Stroke(
      points: points ?? List<Offset>.from(this.points),
      color: color ?? this.color,
      style: style ?? this.style,
      wallpaperImage: wallpaperImage ?? this.wallpaperImage,
      wallpaperAsset: wallpaperAsset ?? this.wallpaperAsset,
      svgPicture: svgPicture ?? this.svgPicture,
      stampAsset: stampAsset ?? this.stampAsset,
      stampSize: stampSize ?? this.stampSize,
      svgSize: svgSize ?? this.svgSize,
    );
  }
}

class Region {
  final String id;
  Path path;
  Color strokeColor;
  double strokeWidth;
  Color originalFillColor;
  final bool keepColor; // NEW
  final bool keepOriginalColor; // ✅ ADD THIS

  Color currentFillColor;
  StrokeStyle currentFillStyle; // NEW: fill style for region
  List<Stroke> strokes; // UPDATED: mutable list so it can be reassigned

  Region({
    required this.id,
    required this.path,
    required this.strokeColor,
    required this.strokeWidth,
    this.keepColor = false, // NEW
    this.keepOriginalColor = false, // ✅ ADD

    required this.originalFillColor,
    Color? initialFillColor, // NEW: optional initial fill
  }) : currentFillColor =
           initialFillColor ?? Colors.white, // start white by default
       currentFillStyle = StrokeStyle.solid, // default fill style
       strokes = [];

  void fill(Color c, StrokeStyle style) {
    if (keepOriginalColor) {
      return;
    }

    currentFillColor = c;
    currentFillStyle = style;
  }

  void resetToOriginal() {
    currentFillColor = originalFillColor;
    currentFillStyle = StrokeStyle.solid;
    strokes.clear();
  }

  void resetToWhite() {
    if (keepOriginalColor) {
      currentFillColor = originalFillColor;
      currentFillStyle = StrokeStyle.solid;
      strokes.clear();
      return;
    }

    currentFillColor = const Color(0xFFFFFFFF);
    currentFillStyle = StrokeStyle.solid;
    strokes.clear();
  }

  bool contains(Offset p) => path.contains(p);

  Rect getBounds() => path.getBounds();

  // Add method to create a deep copy of the region state
  RegionState createStateSnapshot() {
    return RegionState(
      color: currentFillColor,
      style: currentFillStyle,
      strokes: strokes.map((stroke) => stroke.copyWith()).toList(),
    );
  }

  // Add method to restore from state snapshot
  void restoreFromState(RegionState state) {
    currentFillColor = state.color;
    currentFillStyle = state.style;
    strokes
      ..clear()
      ..addAll(state.strokes.map((stroke) => stroke.copyWith()));
  }
}

// =============================================================================
// ACTION SYSTEM CLASSES - Add these at the bottom of the file
// =============================================================================

/// Represents a snapshot of a region's state for undo/redo
class RegionState {
  final Color color;
  final StrokeStyle style;
  final List<Stroke> strokes;

  RegionState({
    required this.color,
    required this.style,
    required this.strokes,
  });

  // Create a deep copy
  RegionState copy() {
    return RegionState(
      color: color,
      style: style,
      strokes: strokes.map((stroke) => stroke.copyWith()).toList(),
    );
  }
}

/// Base class for all coloring actions
abstract class ColoringAction {
  void apply(List<Region> regions);
  void revert(List<Region> regions);
}

/// Action for fill operations
class FillAction implements ColoringAction {
  final int regionIndex;
  final Color previousColor;
  final Color newColor;
  final StrokeStyle previousStyle;
  final StrokeStyle newStyle;
  final List<Stroke> previousStrokes;

  FillAction({
    required this.regionIndex,
    required this.previousColor,
    required this.newColor,
    required this.previousStyle,
    required this.newStyle,
    required this.previousStrokes,
  });

  @override
  void apply(List<Region> regions) {
    if (regionIndex >= regions.length) return;

    final region = regions[regionIndex];

    if (region.keepOriginalColor) {
      return;
    }

    region.currentFillColor = newColor;
    region.currentFillStyle = newStyle;
    region.strokes.clear();
  }

  @override
  void revert(List<Region> regions) {
    if (regionIndex >= regions.length) return;
    final region = regions[regionIndex];

    region.currentFillColor = previousColor;
    region.currentFillStyle = previousStyle;
    region.strokes
      ..clear()
      ..addAll(previousStrokes.map((s) => s.copyWith()));
  }

  @override
  String toString() => 'FillAction(region: $regionIndex, color: $newColor)';
}

/// Action for stroke operations (freehand, eraser, stamps)
class StrokeAction implements ColoringAction {
  final int regionIndex;
  final Stroke stroke;

  StrokeAction({required this.regionIndex, required this.stroke});

  @override
  void apply(List<Region> regions) {
    if (regionIndex >= regions.length) return;

    final region = regions[regionIndex];

    if (region.keepOriginalColor) {
      return;
    }

    if (!region.strokes.contains(stroke)) {
      region.strokes.add(stroke);
    }
  }

  @override
  void revert(List<Region> regions) {
    if (regionIndex >= regions.length) return;
    regions[regionIndex].strokes.remove(stroke);
  }

  @override
  String toString() =>
      'StrokeAction(region: $regionIndex, points: ${stroke.points.length})';
}

/// Action for magic wand operations
class MagicAction implements ColoringAction {
  final int regionIndex;
  final Color previousColor;
  final StrokeStyle previousStyle;
  final List<Stroke> previousStrokes;

  MagicAction({
    required this.regionIndex,
    required this.previousColor,
    required this.previousStyle,
    required this.previousStrokes,
  });

  @override
  void apply(List<Region> regions) {
    if (regionIndex < regions.length) {
      regions[regionIndex].resetToOriginal();
    }
  }

  @override
  void revert(List<Region> regions) {
    if (regionIndex < regions.length) {
      regions[regionIndex].currentFillColor = previousColor;
      regions[regionIndex].currentFillStyle = previousStyle;
      regions[regionIndex].strokes
        ..clear()
        ..addAll(previousStrokes.map((stroke) => stroke.copyWith()));
    }
  }

  @override
  String toString() => 'MagicAction(region: $regionIndex)';
}

/// Action for clear all operations
class ClearAction implements ColoringAction {
  final List<RegionState> previousStates;

  ClearAction(this.previousStates);

  @override
  void apply(List<Region> regions) {
    for (final region in regions) {
      region.resetToWhite(); // ✅ white, not original
    }
  }

  @override
  void revert(List<Region> regions) {
    for (int i = 0; i < regions.length && i < previousStates.length; i++) {
      regions[i].restoreFromState(previousStates[i]);
    }
  }
}

/// Action for multiple strokes in one operation (for freehand drawing)
class MultiStrokeAction implements ColoringAction {
  final List<StrokeAction> strokeActions;

  MultiStrokeAction(this.strokeActions);

  @override
  void apply(List<Region> regions) {
    for (final action in strokeActions) {
      action.apply(regions);
    }
  }

  @override
  void revert(List<Region> regions) {
    // Reverse to undo in correct order
    for (final action in strokeActions.reversed) {
      action.revert(regions);
    }
  }

  @override
  String toString() => 'MultiStrokeAction(strokes: ${strokeActions.length})';
}
