import 'package:flutter/material.dart';

import '../../common/resources/color_manager.dart';
import '../models/brush_size.dart';
import 'kid_layout.dart';

/// A single big, rounded, kid-sized button used by both rails.
///
/// Replaces the old pattern of `Container(width: % of screen height, ...)`
/// scattered through the palette widgets: one fixed size, one tap target,
/// one selected state.
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

  const KidRailButton({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.label,
    this.faceColor,
  });

  @override
  Widget build(BuildContext context) {
    final size = KidLayout.buttonSize;

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label ?? '',
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: size,
            height: size,
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: faceColor ?? Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? ColorManager.gold : Colors.black12,
                width: selected ? 4 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A docked rail of [KidRailButton]s.
///
/// The rail is a sibling of the canvas, not an overlay, so it never covers the
/// drawing and every shape stays tappable. [axis] decides whether it is a
/// vertical side rail or a horizontal bottom bar; the same children work in
/// both. If the content does not fit, the rail scrolls rather than overflowing.
class KidRail extends StatelessWidget {
  final Axis axis;
  final List<Widget> children;
  final double thickness;

  const KidRail({
    super.key,
    required this.axis,
    required this.children,
    this.thickness = KidLayout.railThickness,
  });

  @override
  Widget build(BuildContext context) {
    final isHorizontal = axis == Axis.horizontal;

    final content = isHorizontal
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: children,
          );

    return Container(
      width: isHorizontal ? null : thickness,
      height: isHorizontal ? thickness : null,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: axis,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: content,
      ),
    );
  }
}

/// ✅ NEW (kid-ui): the S / M / L brush-size picker.
///
/// Three plain buttons with a dot that grows, so a pre-reader can see which
/// one draws a fat line without reading a word. It replaces nothing on its own
/// — the widths used to be hard-coded in `coloring_painter.dart`, which is why
/// the child had no size control at all before.
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

  @override
  Widget build(BuildContext context) {
    final buttons = BrushSize.values.map((size) {
      return KidRailButton(
        key: Key('kid_brush_size_${size.name}'),
        onTap: () => onChanged(size),
        selected: size == selected,
        label: size.label,
        child: Center(
          child: Container(
            width: size.dotDiameter,
            height: size.dotDiameter,
            decoration: BoxDecoration(
              color: previewColor,
              shape: BoxShape.circle,
              // A dark rim keeps a white dot visible on the white button.
              border: Border.all(color: Colors.black38, width: 2),
            ),
          ),
        ),
      );
    }).toList();

    final group = axis == Axis.vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: buttons)
        : Row(mainAxisSize: MainAxisSize.min, children: buttons);

    return group;
  }
}
