import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/painting.dart' show Alignment;
import 'package:sizer/sizer.dart';

/// Layout maths for the kid-friendly painting screen.
///
/// ✅ CHANGED (kid-ui round 3): this now sizes everything the way the rest of
/// the app does — as a **percentage of the screen** (`.h` / `.w` from the
/// `sizer` package, the same helpers `values_manager.dart` is built on), e.g.
/// the original rail was `22.h` and a tool button `18.h` x `20.w`. What is
/// *not* copied from the original is the inconsistency that made it break: the
/// original took the button's **height** from the screen height and its
/// **width** from the screen width, so on a wide screen the two stopped
/// matching and the buttons overflowed their own rail.
///
/// Here one number drives both axes ([buttonH] percent of the height and
/// [buttonW] percent of the width, whichever is *smaller*), it is clamped to a
/// sane range, and a rail that cannot fit its buttons shrinks them instead of
/// making the child scroll.
/// How the drawing is scaled into the canvas.
enum ArtFit {
  /// Stretch to the canvas on both axes: **the painting fills the whole
  /// screen**. Everything stays visible and tappable; the trade-off is that
  /// the artwork is stretched by the difference between its own aspect
  /// (16:9) and the screen's. This is what the app did before round 1, and
  /// what "the colouring area must fill the screen" asks for.
  fill,

  /// Keep the artwork's own aspect ratio and centre it. Nothing is
  /// distorted, but on a 20:9 phone the drawing is ~20 % narrower than the
  /// screen, leaving bands at the sides.
  keepShape,
}

class KidLayout {
  KidLayout._();

  // ---------------------------------------------------------------------------
  // Screen measurement (falls back to a small phone when `Sizer` has not
  // measured yet — a widget test mounts the page without the app's `Sizer`, and
  // `Device.height`/`width` are `late`, so reading them there would throw).
  // ---------------------------------------------------------------------------

  static const double _fallbackW = 800;
  static const double _fallbackH = 400;

  static double get screenW {
    try {
      final w = Device.width;
      return w > 0 ? w : _fallbackW;
    } catch (_) {
      return _fallbackW;
    }
  }

  static double get screenH {
    try {
      final h = Device.height;
      return h > 0 ? h : _fallbackH;
    } catch (_) {
      return _fallbackH;
    }
  }

  /// The app's sizing language: [p] percent of the screen, in dp.
  /// `18.pctH` is what the original code wrote as `AppSizeHeight.s18`.
  static double pctH(num p) => screenH * p / 100;
  static double pctW(num p) => screenW * p / 100;

  // ---------------------------------------------------------------------------
  // Design numbers, all in "percent of the screen" like the original code.
  // ---------------------------------------------------------------------------

  /// A rail button: 18 % of the screen height / 20 % of the screen width,
  /// whichever is smaller (the original: 18.h tall, 20.w wide).
  static const double buttonH = 18;
  static const double buttonW = 20;

  /// Padding inside a rail, on each side (the original rail was 22.h wide,
  /// i.e. a button plus this padding on both sides).
  static const double railPaddingH = 2;

  /// Space between two rail buttons.
  static const double buttonGapH = 1.2;

  /// Space between the button face and its own edge (the tap halo).
  static const double buttonMarginH = 0.6;

  /// The smallest a touch target may ever get (platform minimum) and the
  /// largest a button may grow on a big screen, so a tablet does not end up
  /// with one button per screen.
  static const double minButton = 48;
  static const double maxButton = 104;

  // ---------------------------------------------------------------------------
  // Floating controls (round 4: the "nothing reserved" layout).
  // ---------------------------------------------------------------------------

  /// A floating button: 14 % of the screen height, clamped to a real touch
  /// target.
  static const double floatButtonH = 14;
  static const double minFloatButton = 44;
  static const double maxFloatButton = 96;

  static double get floatButtonSize => _bounded(
    pctH(floatButtonH),
    minFloatButton,
    math.min(maxFloatButton, screenH * 0.30),
  );

  /// Gap between floating buttons / padding inside a floating cluster.
  static double get floatGap => _bounded(pctH(1.2), 4, floatButtonSize * 0.30);

  /// A colour dot in the always-visible bottom strip.
  static const double colorDotH = 11;
  static const double minColorDot = 38;
  static const double maxColorDot = 72;

  static double get colorDotSize => _bounded(
    pctH(colorDotH),
    minColorDot,
    math.min(maxColorDot, screenH * 0.22),
  );

  /// How many colour dots the strip shows before the "more" button.
  static const int stripColors = 11;

  // ---------------------------------------------------------------------------
  // Fitting the artwork to the screen.
  // ---------------------------------------------------------------------------

  /// Even in [ArtFit.fill], never stretch one axis more than this much more
  /// than the other — beyond it the drawing stops looking like the artwork
  /// (a 20:9 phone is 1.25, a tablet is ~1.33; portrait would be 3+).
  static const double maxStretch = 1.6;

  /// The transform that maps artwork-space into canvas-space for [fit].
  ///
  /// Returns the same key names the painter and the hit-testing already use:
  /// `scaleX`, `scaleY`, `tx`, `ty`.
  static Map<String, double> fitTransform({
    required Rect bounds,
    required Size canvas,
    required ArtFit fit,
    double maxStretchRatio = maxStretch,
  }) {
    final bw = bounds.width <= 0 ? 1.0 : bounds.width;
    final bh = bounds.height <= 0 ? 1.0 : bounds.height;

    var scaleX = canvas.width / bw;
    var scaleY = canvas.height / bh;

    if (fit == ArtFit.keepShape) {
      // One scale for both axes, centred.
      final scale = math.min(scaleX, scaleY);
      scaleX = scale;
      scaleY = scale;
    } else {
      // Fill: use both scales, but do not let one axis run away from the
      // other (that is the "circles became ovals" extreme).
      final ratio = scaleX > scaleY ? scaleX / scaleY : scaleY / scaleX;
      if (ratio > maxStretchRatio) {
        if (scaleX > scaleY) {
          scaleX = scaleY * maxStretchRatio;
        } else {
          scaleY = scaleX * maxStretchRatio;
        }
      }
    }

    final drawnWidth = bw * scaleX;
    final drawnHeight = bh * scaleY;

    final tx = (canvas.width - drawnWidth) / 2 - bounds.left * scaleX;
    final ty = (canvas.height - drawnHeight) / 2 - bounds.top * scaleY;

    return {'scaleX': scaleX, 'scaleY': scaleY, 'tx': tx, 'ty': ty};
  }

  // ---------------------------------------------------------------------------
  // The "Coloring Book" controls (round 6): bubbles and the colour fan.
  // ---------------------------------------------------------------------------

  /// The bubble a thumb rests on at the bottom right: 22 % of the screen
  /// height, big enough to find without looking.
  static const double crayonBubbleH = 22;
  static const double minCrayonBubble = 64;
  static const double maxCrayonBubble = 120;

  static double get crayonBubbleSize => _bounded(
    pctH(crayonBubbleH),
    minCrayonBubble,
    math.min(maxCrayonBubble, screenH * 0.34),
  );

  /// The tool bubble above it, and the small corner bubbles (home, save).
  static const double bubbleH = 16;
  static const double minBubble = 50;

  static double get bubbleSize =>
      _bounded(pctH(bubbleH), minBubble, crayonBubbleSize * 0.78);

  /// The undo / redo pill.
  static const double pillH = 13;
  static const double minPill = 44;

  static double get pillHeight => _bounded(pctH(pillH), minPill, 68);

  /// How far the fan reaches from the bubble, and how big its circles are.
  static const double fanRadiusH = 42;
  static const double minFanRadius = 118;
  static const double maxFanRadius = 190;

  static double get fanOuterRadius => _bounded(
    pctH(fanRadiusH),
    minFanRadius,
    math.min(maxFanRadius, screenH * 0.52),
  );

  static double get fanInnerRadius => fanOuterRadius * 0.62;

  /// ✅ FIXED: how many colours the fan shows before the "more" circle.
  ///
  /// It was 12, which cannot work: from a bubble in the corner the fan only has
  /// a quarter turn of usable space, and 12 circles of 46 dp need an arc of
  /// ~600 dp — that either runs off the screen or makes the circles overlap.
  /// Eight families (the ones children reach for) plus "＋" for the full grid is
  /// the honest maximum for this shape, and every one of them stays big.
  static const int fanColorCount = 8;

  /// A fan circle: at least a fingertip, never smaller than 44.
  static const double fanDotH = 13;
  static const double minFanDot = 44;

  static double get fanDotSize => _bounded(pctH(fanDotH), minFanDot, 66);

  /// Where a fan's circles start and end, in degrees, **in screen
  /// coordinates** (0° = right, 90° = down, 270° = up).
  ///
  /// ✅ FIXED: it is a **quarter turn (90°) that opens into the screen**, so
  /// every circle stays on screen. The earlier version swept up to 300° for a
  /// bottom-right bubble, which put the last two circles past the right edge.
  static ({double start, double end}) fanArcFor(Alignment anchor) {
    if (anchor == Alignment.bottomRight) {
      // Straight left (180°) round to straight up (270°).
      return (start: 180, end: 270);
    }
    if (anchor == Alignment.bottomLeft) {
      // Straight up (270°) round to straight right (360°).
      return (start: 270, end: 360);
    }
    if (anchor == Alignment.topRight) {
      // Straight down (90°) round to straight left (180°).
      return (start: 90, end: 180);
    }
    // topLeft: straight right (0°) round to straight down (90°).
    return (start: 0, end: 90);
  }

  /// The centre of the bubble that the fan is built around: [inset] dp from the
  /// corner of [size] given by [anchor] (the bubble's own centre).
  static Offset fanAnchor(Size size, Alignment anchor, {double? inset}) {
    final margin = inset ?? fanMargin + crayonBubbleSize / 2;
    final x = anchor.x < 0 ? margin : size.width - margin;
    final y = anchor.y < 0 ? margin : size.height - margin;
    return Offset(x, y);
  }

  /// Distance from the screen edge to the nearest edge of the corner bubbles.
  static double get fanMargin => _bounded(pctH(2.4), 6, 22);

  /// ✅ NEW: the biggest circle size that still fits [count] circles on an arc
  /// of [radius] without them colliding — never below [minFanDot], never above
  /// [fanDotSize].
  ///
  /// With the quarter-turn arcs above, the two rows of the fan carry different
  /// numbers of circles, so they need different sizes: five circles on the
  /// outer arc can be large, four on the shorter inner arc must be smaller.
  static double fanDotSizeFor({
    required int count,
    required double radius,
    required ({double start, double end}) arc,
  }) {
    if (count <= 0) return fanDotSize;
    final sweepRad = (arc.end - arc.start).abs() * math.pi / 180.0;
    final arcLength = radius * sweepRad;
    final spacing = count <= 1 ? arcLength : arcLength / (count - 1);
    return _bounded(spacing * 0.92, minFanDot, fanDotSize);
  }

  /// One circle of a fan: [index] of [count] placed on an arc of [radius]
  /// between [arc].start and [arc].end degrees.
  static Offset fanDotOffset({
    required int index,
    required int count,
    required double radius,
    required ({double start, double end}) arc,
  }) {
    final t = count <= 1 ? 0.0 : index / (count - 1);
    final deg = arc.start + (arc.end - arc.start) * t;
    final rad = deg * math.pi / 180.0;
    return Offset(math.cos(rad) * radius, math.sin(rad) * radius);
  }

  /// All twelve artworks are 1920 x 1080, i.e. 16:9 landscape.
  static const double artAspect = 1920 / 1080;

  // ---------------------------------------------------------------------------
  // Derived sizes.
  // ---------------------------------------------------------------------------

  /// The size a rail button would like to be on this screen, before the rail
  /// checks whether it actually fits.
  static double get buttonSize => math.max(
    minButton,
    math.min(pctH(buttonH), math.min(pctW(buttonW), maxButton)),
  );

  static double get buttonGap => math.max(2, pctH(buttonGapH));
  static double get buttonMargin => math.max(1, pctH(buttonMarginH));
  static double get railPadding => math.max(3, pctH(railPaddingH));

  /// Thickness of a docked rail: a button plus the padding on both sides.
  static double get railThickness => buttonSize + 2 * railPadding;

  /// The radius of a button face — rounded, kid-friendly, scales with the
  /// screen like everything else.
  static double get buttonRadius => math.max(12, buttonSize * 0.30);

  /// ✅ NEW: the size to really use inside a rail that has [railExtent] dp
  /// along its axis and must hold [count] buttons. It never scrolls: when the
  /// screen is short the buttons shrink (but never below [minButton]) and
  /// extra pressure is absorbed by the rail scrolling instead of overflowing.
  static double railButtonSize({
    required double railExtent,
    required int count,
    double? gap,
  }) {
    if (count <= 0) return buttonSize;
    final g = gap ?? buttonGap;
    final m = 2 * buttonMargin;
    final available = railExtent - 2 * railPadding - (count - 1) * g;
    final perButton = available / count - m;
    if (perButton >= buttonSize) return buttonSize;
    return math.max(minButton, perButton);
  }

  /// The area the drawing occupies if it is fitted (aspect preserved) into
  /// [availW] x [availH] — used to check what a layout costs the child.
  static double artArea(double availW, double availH) {
    if (availW <= 0 || availH <= 0) return 0;
    final scale = math.min(availW / 1920.0, availH / 1080.0);
    return (1920.0 * scale) * (1080.0 * scale);
  }

  // ---------------------------------------------------------------------------
  // The docked colour / stamp / pattern panel.
  // ---------------------------------------------------------------------------

  /// Clamp that cannot throw (an inverted min/max throws in Dart).
  static double _bounded(double want, double lo, double hi) =>
      math.max(lo, math.min(hi, want));

  /// Width of the docked tool / stamp / pattern panel: 34 % of the screen
  /// width (the percentage the original palette block used). Bounded on a
  /// small screen so it never swallows the canvas, and capped on a big one so
  /// a desktop-sized window does not get a 800 dp panel.
  static double panelWidth(double screenWidth) {
    final lo = math.min(180.0, screenWidth * 0.30);
    final hi = math.max(lo, math.min(420.0, screenWidth * 0.45));
    return _bounded(pctW(34), lo, hi);
  }

  /// Height of the same panel (kept for the portrait / tablet fallback).
  static double panelHeight(double screenHeight) =>
      _bounded(pctH(60), 120, screenHeight * 0.5);

  // ---------------------------------------------------------------------------
  // Colour grid.
  // ---------------------------------------------------------------------------

  /// The most swatches we ever put on one row.
  static const int maxColorColumns = 8;

  /// A swatch is never smaller than this — a small finger must be able to hit
  /// it without aiming (the UI plan asked for 44 dp).
  static const double minSwatch = 44;

  /// …and never bigger than this, or the grid looks silly on a big screen.
  static const double maxSwatch = 64;

  static const double swatchGap = 6;
  static const double swatchGridPadding = 8;

  /// Width the grid wants so that [maxColorColumns] swatches fit at
  /// [minSwatch]: cells + gaps + padding on both sides.
  static const double swatchGridWidth =
      maxColorColumns * minSwatch +
      (maxColorColumns - 1) * swatchGap +
      2 * swatchGridPadding;

  /// ✅ NEW: how many swatches fit on one row inside [panelWidth] while staying
  /// at least [minSwatch] big. Between 4 and [maxColorColumns].
  ///
  /// This is the fix for the real bug: on a 640 dp-wide phone the panel is
  /// ~269 dp, so eight columns would have made 26 dp swatches. Six columns at
  /// 44 dp beat eight at 26 dp every time.
  static int colorColumnsFor(double panelWidth) {
    final usable = panelWidth - 2 * swatchGridPadding + swatchGap;
    final fits = (usable / (minSwatch + swatchGap)).floor();
    return fits.clamp(4, maxColorColumns);
  }

  /// Width of the docked panel while a colour palette is inside it: 42 % of the
  /// screen width (the percentage the original colour panel used). Bounded so
  /// four swatches always fit on a small screen, and capped at the full
  /// [swatchGridWidth] so the swatches never grow past [maxSwatch] on a big
  /// one.
  static double colorPanelWidth(double screenWidth) {
    final lo = math.min(
      4 * minSwatch + 2 * swatchGridPadding,
      screenWidth * 0.32,
    );
    final hi = math.max(lo, math.min(swatchGridWidth, screenWidth * 0.50));
    return _bounded(pctW(42), lo, hi);
  }
}

// ----- old version (kept for reference) -----
// The fixed-dp version this replaces (round 2). It sized everything in
// logical pixels — 64 dp buttons, 76 dp rails — which did not scale the way
// the rest of the app does:
//
// import 'dart:math' as math;
//
// class KidLayout {
//   KidLayout._();
//   static const double buttonSize = 64;
//   static const double buttonGap = 10;
//   static const double railThickness = buttonSize + 12;
//   static const double artAspect = 1920 / 1080;
//   static double artArea(double availW, double availH) { ... }
//   static bool preferSideRails(double screenW, double screenH) {
//     final sideArea = artArea(screenW - 2 * railThickness, screenH);
//     final bottomArea = artArea(screenW, screenH - railThickness);
//     return sideArea >= bottomArea;
//   }
//   static double panelWidth(double screenW) => math.min(360.0, screenW * 0.34);
//   static double panelHeight(double screenH) => math.min(230.0, screenH * 0.5);
//   static const int colorColumns = 8;
//   static const double minSwatch = 44;
//   static const double maxSwatch = 64;
//   static const double swatchGridWidth = ...;
//   static double colorPanelWidth(double screenW) =>
//       math.min(swatchGridWidth, screenW * 0.42);
// }
