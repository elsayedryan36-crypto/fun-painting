import 'dart:math' as math;

/// Layout maths for the kid-friendly painting screen.
///
/// Every number here is in logical pixels (dp) — deliberately NOT a percentage
/// of the screen. The old layout sized the toolbars as a percentage of the
/// screen *height* (and used that number for their *width* too), which made
/// them enormous on some aspect ratios and useless on others.
class KidLayout {
  KidLayout._();

  /// Side of a single rail button. 64 dp is comfortably above the 48 dp
  /// minimum touch target and is easy for small fingers.
  static const double buttonSize = 64;

  /// Gap between rail buttons.
  static const double buttonGap = 10;

  /// Thickness of one docked rail (button + padding on both sides).
  static const double railThickness = buttonSize + 12;

  /// All shipped artworks are 1920 x 1080, i.e. 16:9 landscape. The parser
  /// fits the drawing to its own bounds, but the aspect ratio to plan around
  /// is this one.
  static const double artAspect = 1920 / 1080;

  /// The area the drawing occupies if it is fitted (aspect preserved) into
  /// [availW] x [availH].
  static double artArea(double availW, double availH) {
    if (availW <= 0 || availH <= 0) return 0;
    final scale = math.min(availW / 1920.0, availH / 1080.0);
    return (1920.0 * scale) * (1080.0 * scale);
  }

  /// True when docking the two rails on the LEFT and RIGHT leaves a bigger
  /// colouring area than docking them as a single bar at the BOTTOM.
  ///
  /// Wide phones in landscape (20:9 and wider) have empty bands down each side
  /// because the artwork is 16:9 — the side rails fit in that dead space and
  /// cost the child nothing. On a 16:9 screen there is no dead space, so a
  /// bottom bar is the cheaper option.
  static bool preferSideRails(double screenW, double screenH) {
    final sideArea = artArea(screenW - 2 * railThickness, screenH);
    final bottomArea = artArea(screenW, screenH - railThickness);
    return sideArea >= bottomArea;
  }

  /// Width of the docked colour / stamp / pattern panel in side-rail mode.
  /// Bounded so it never swallows the canvas.
  static double panelWidth(double screenW) => math.min(360.0, screenW * 0.34);

  /// ✅ NEW (kid-ui): how many colour swatches go on one row.
  static const int colorColumns = 8;

  /// Smallest / largest a colour swatch may be. 44 dp is the floor from the
  /// UI plan — big enough for a small finger to hit without aiming.
  static const double minSwatch = 44;
  static const double maxSwatch = 64;

  /// Padding on each side of the swatch grid.
  static const double swatchGridPadding = 8;

  /// Gap between two swatches.
  static const double swatchGap = 6;

  /// Width the swatch grid wants so that 8 columns are at least [minSwatch]
  /// wide: 8 cells + 7 gaps + the padding on both sides. `const` so it can be
  /// used in a const BoxConstraints.
  static const double swatchGridWidth =
      colorColumns * minSwatch +
      (colorColumns - 1) * swatchGap +
      2 * swatchGridPadding;

  /// Width of the docked panel while a colour palette is inside it. Wider than
  /// [panelWidth] because eight kid-sized swatches need the room; still capped
  /// at 42 % of the screen so the canvas keeps the majority of the width.
  static double colorPanelWidth(double screenW) =>
      math.min(swatchGridWidth, screenW * 0.42);

  /// Height of the same panel when the rails are at the bottom.
  static double panelHeight(double screenH) => math.min(230.0, screenH * 0.5);
}
