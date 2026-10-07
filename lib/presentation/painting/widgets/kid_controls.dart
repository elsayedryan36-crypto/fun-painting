import 'package:flutter/material.dart';

import '../../common/resources/color_manager.dart';
import '../models/brush_size.dart';
import 'kid_layout.dart';

/// ✅ NEW (kid-ui round 3): the size a rail has worked out for its buttons,
/// handed down to the buttons themselves.
///
/// A rail knows how much room it has (it is inside a `LayoutBuilder`), the
/// buttons do not. This is how a button can shrink to fit a short phone screen
/// without every button having to measure the screen itself.
class KidRailMetrics extends InheritedWidget {
  /// The size of one button face (the tap halo is drawn inside it).
  final double buttonSize;

  /// Vertical = side rail, horizontal = bottom bar.
  final Axis axis;

  const KidRailMetrics({
    super.key,
    required this.buttonSize,
    required this.axis,
    required super.child,
  });

  static KidRailMetrics? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KidRailMetrics>();

  @override
  bool updateShouldNotify(KidRailMetrics old) =>
      old.buttonSize != buttonSize || old.axis != axis;
}

/// A single big, rounded, kid-sized button used by both rails.
///
/// ✅ CHANGED (kid-ui round 3): it sizes itself with the rail's percentage
/// maths ([KidLayout]) instead of the 64 dp constant, it ripples when pressed
/// (little fingers need to *see* that the tap landed), it can carry a bright
/// face colour, and its icon fills more of the face than before.
class KidRailButton extends StatelessWidget {
  final Widget child;

  /// Called on tap. `null` = the button looks disabled.
  final VoidCallback? onTap;

  /// Draws the high-contrast ring + tint used for the active tool.
  final bool selected;

  /// Optional small label under the icon (kid-friendly: pre-readers match the
  /// colour/icon, readers can read the word).
  final String? label;

  /// Background of the button face (e.g. the current colour for the swatch).
  final Color? faceColor;

  /// ✅ NEW: the colour of the icon/label on top of the face. Defaults to the
  /// app's dark ink colour.
  final Color? inkColor;

  /// ✅ NEW: the ring drawn on the selected button.
  final Color? selectedColor;

  const KidRailButton({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.label,
    this.faceColor,
    this.inkColor,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = KidRailMetrics.maybeOf(context);
    final size = metrics?.buttonSize ?? KidLayout.buttonSize;
    final margin = KidLayout.buttonMargin;
    final radius = KidLayout.buttonRadius;
    final ink = inkColor ?? ColorManager.darkPrimary;

    // The label sits under the icon, so the icon gets most of the face.
    final hasLabel = label != null && label!.isNotEmpty;
    final iconExtent = hasLabel ? size * 0.52 : size * 0.68;
    final labelSize = (size * 0.22).clamp(9.0, 18.0);

    final face = Container(
      width: size,
      height: size,
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: faceColor ?? Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: selected
              ? (selectedColor ?? ColorManager.gold)
              : Colors.black12,
          width: selected ? size * 0.06 : size * 0.03,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: size * 0.08,
            offset: Offset(0, size * 0.03),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: iconExtent,
            height: iconExtent,
            child: FittedBox(fit: BoxFit.contain, child: child),
          ),
          if (hasLabel) ...[
            SizedBox(height: size * 0.03),
            Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label ?? '',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            splashColor: ColorManager.gold.withValues(alpha: 0.35),
            child: face,
          ),
        ),
      ),
    );

    // ----- old version (kept for reference) -----
    // final size = KidLayout.buttonSize;           // hard-coded 64 dp
    // return Semantics(
    //   button: true,
    //   label: label,
    //   child: Tooltip(
    //     message: label ?? '',
    //     child: GestureDetector(
    //       onTap: onTap,
    //       behavior: HitTestBehavior.opaque,
    //       child: Container(
    //         width: size,
    //         height: size,
    //         margin: const EdgeInsets.all(2),
    //         padding: const EdgeInsets.all(6),
    //         decoration: BoxDecoration(
    //           color: faceColor ?? Colors.white,
    //           borderRadius: BorderRadius.circular(18),
    //           border: Border.all(
    //             color: selected ? ColorManager.gold : Colors.black12,
    //             width: selected ? 4 : 2,
    //           ),
    //           boxShadow: [ BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 2)) ],
    //         ),
    //         child: child,
    //       ),
    //     ),
    //   ),
    // );
  }
}

/// A docked rail of [KidRailButton]s.
///
/// The rail is a sibling of the canvas, not an overlay, so it never covers the
/// drawing and every shape stays tappable. It measures itself and tells its
/// buttons what size to be ([KidRailMetrics]), so a short screen shrinks the
/// buttons instead of making the child scroll; the scroll view is only a last
/// resort.
class KidRail extends StatelessWidget {
  final Axis axis;
  final List<Widget> children;
  final double? thickness;

  /// Optional background — the action rail is tinted, the tool rail white.
  final Color? background;

  const KidRail({
    super.key,
    required this.axis,
    required this.children,
    this.thickness,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final isHorizontal = axis == Axis.horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The page may have already worked out ONE size for BOTH rails, so a
        // short screen does not end up with two different button sizes; if it
        // has not, this rail works its own size out from the room it has.
        final inherited = KidRailMetrics.maybeOf(context)?.buttonSize;
        final extent = isHorizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        final size =
            inherited ??
            KidLayout.railButtonSize(
              railExtent: extent.isFinite && extent > 0 ? extent : 0,
              count: children.length,
            );

        return Container(
          width: isHorizontal ? null : (thickness ?? KidLayout.railThickness),
          height: isHorizontal ? (thickness ?? KidLayout.railThickness) : null,
          margin: EdgeInsets.all(KidLayout.railPadding * 0.6),
          decoration: BoxDecoration(
            color: background ?? Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(KidLayout.buttonRadius * 1.5),
            border: Border.all(
              color: ColorManager.darkPrimary.withValues(alpha: 0.25),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: axis,
            padding: EdgeInsets.symmetric(
              vertical: KidLayout.railPadding * 0.5,
              horizontal: KidLayout.railPadding * 0.5,
            ),
            child: KidRailMetrics(
              axis: axis,
              buttonSize: size,
              child: isHorizontal
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: children,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: children,
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// The S / M / L brush-size picker.
///
/// ✅ CHANGED (kid-ui round 3): the three buttons can be handed to a rail as
/// items ([railButtons]) so the rail counts them like any other button — that
/// is how six buttons still fit a short screen without scrolling.
class KidBrushSizeControl extends StatelessWidget {
  final BrushSize selected;
  final ValueChanged<BrushSize> onChanged;

  /// The colour of the preview dot — the currently selected paint colour, so
  /// the child sees colour + thickness together.
  final Color previewColor;

  /// Side rail (vertical) or bottom bar (horizontal).
  final Axis axis;

  const KidBrushSizeControl({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.previewColor,
    this.axis = Axis.vertical,
  });

  /// The three size buttons as plain rail items.
  static List<Widget> railButtons({
    required BrushSize selected,
    required ValueChanged<BrushSize> onChanged,
    required Color previewColor,
  }) {
    return BrushSize.values.map((size) {
      return KidRailButton(
        key: Key('kid_brush_size_${size.name}'),
        onTap: () => onChanged(size),
        selected: size == selected,
        label: size.shortLabel,
        inkColor: const Color(0xFF1565C0),
        child: Container(
          width: size.dotDiameter,
          height: size.dotDiameter,
          decoration: BoxDecoration(
            color: previewColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black38, width: 2),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final buttons = railButtons(
      selected: selected,
      onChanged: onChanged,
      previewColor: previewColor,
    );

    return axis == Axis.vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: buttons)
        : Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }

  // ----- old version (kept for reference) -----
  // Each size was a KidRailButton with a dot + the full label ('Thin brush',
  // 'Medium brush', 'Thick brush') and the group was one widget the rail could
  // not count:
  //
  // class KidBrushSizeControl extends StatelessWidget {
  //   ...
  //   Widget build(BuildContext context) {
  //     final buttons = BrushSize.values.map((size) {
  //       return KidRailButton(
  //         key: Key('kid_brush_size_${size.name}'),
  //         onTap: () => onChanged(size),
  //         selected: size == selected,
  //         label: size.label,
  //         child: Center(child: Container(width: size.dotDiameter, height: size.dotDiameter, decoration: ...)),
  //       );
  //     }).toList();
  //     return axis == Axis.vertical ? Column(...) : Row(...);
  //   }
  // }
}
