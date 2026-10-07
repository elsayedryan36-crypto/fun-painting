import 'package:flutter/material.dart';

import '../../common/resources/color_manager.dart';
import '../models/brush_size.dart';
import 'kid_layout.dart';

/// ✅ NEW (kid-ui round 4): the "nothing reserved" controls.
///
/// The previous rounds docked rails beside the drawing, which always took
/// width or height away from the artwork. These controls **float on top of a
/// full-screen canvas** in translucent bubbles, so the painting really does
/// fill the screen — and they fade while a stroke is in progress so a small
/// finger is never fighting the UI.

/// A round, kid-sized floating button.
class KidFloatButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Draws the ring used for the active tool / active size.
  final bool selected;

  /// Face colour of the bubble (defaults to a frosted white).
  final Color? faceColor;

  /// Short word under the icon (pre-readers match the icon, readers the word).
  final String? label;

  /// Accessibility label / tooltip.
  final String? tooltip;

  const KidFloatButton({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.faceColor,
    this.label,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final size = KidLayout.floatButtonSize;
    final radius = KidLayout.buttonRadius * 0.9;

    return Semantics(
      button: true,
      selected: selected,
      label: tooltip ?? label,
      child: Tooltip(
        message: tooltip ?? label ?? '',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            splashColor: ColorManager.gold.withValues(alpha: 0.35),
            child: Container(
              width: size,
              height: size,
              padding: EdgeInsets.all(size * 0.16),
              decoration: BoxDecoration(
                color: faceColor ?? Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: selected
                      ? ColorManager.gold
                      : Colors.black.withValues(alpha: 0.10),
                  width: selected ? size * 0.075 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: size * 0.16,
                    offset: Offset(0, size * 0.05),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: FittedBox(fit: BoxFit.contain, child: child),
                  ),
                  if (label != null && label!.isNotEmpty)
                    Text(
                      label!,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: (size * 0.20).clamp(8.0, 15.0),
                        fontWeight: FontWeight.w800,
                        color: ColorManager.darkPrimary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A translucent rounded bubble holding a row or column of floating controls.
class KidFloatCluster extends StatelessWidget {
  final List<Widget> children;
  final Axis axis;
  final Color? background;

  const KidFloatCluster({
    super.key,
    required this.children,
    this.axis = Axis.vertical,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final gap = KidLayout.floatGap;
    final pad = gap * 0.9;

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: background ?? Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(KidLayout.buttonRadius * 1.6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: axis == Axis.vertical
          ? Column(mainAxisSize: MainAxisSize.min, children: _spaced(gap))
          : Row(mainAxisSize: MainAxisSize.min, children: _spaced(gap)),
    );
  }

  List<Widget> _spaced(double gap) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0)
        out.add(
          axis == Axis.vertical ? SizedBox(height: gap) : SizedBox(width: gap),
        );
      out.add(children[i]);
    }
    return out;
  }
}

/// ✅ NEW: the always-visible colour strip that sits along the bottom edge.
///
/// One big circle per colour family (Red, Orange, Yellow, … Neon) plus a
/// "more" button that opens the full 78-colour grid. The child never has to
/// open anything to pick a normal colour, and the strip is thin enough that
/// the drawing still uses the screen.
class KidColorStrip extends StatelessWidget {
  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  /// Opens the full grid. `null` hides the "more" button.
  final VoidCallback? onMore;
  final bool moreOpen;

  const KidColorStrip({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
    this.onMore,
    this.moreOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    final dot = KidLayout.colorDotSize;
    final gap = KidLayout.floatGap;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: gap, vertical: gap * 0.8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(dot),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The strip scrolls when it cannot fit (small phones), but on a
          // normal landscape phone every family is visible at once.
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final color in colors) ...[
                    _Dot(
                      size: dot,
                      color: color,
                      selected: color == selectedColor,
                      onTap: () => onColorSelected(color),
                    ),
                    SizedBox(width: gap * 0.7),
                  ],
                ],
              ),
            ),
          ),
          if (onMore != null)
            KidFloatButton(
              key: const Key('kid_more_colors'),
              onTap: onMore,
              selected: moreOpen,
              faceColor: const Color(0xFFFFE082),
              tooltip: 'All colours',
              child: Icon(
                moreOpen ? Icons.keyboard_arrow_down_rounded : Icons.add,
                color: ColorManager.darkPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final double size;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Dot({
    required this.size,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? ColorManager.darkPrimary : Colors.white,
              width: selected ? size * 0.14 : size * 0.08,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ NEW: the S / M / L size chips as compact floating buttons.
class KidSizeChips extends StatelessWidget {
  final BrushSize selected;
  final ValueChanged<BrushSize> onChanged;
  final Color previewColor;
  final Axis axis;

  const KidSizeChips({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.previewColor,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final chips = BrushSize.values.map((size) {
      return KidFloatButton(
        key: Key('kid_brush_size_${size.name}'),
        onTap: () => onChanged(size),
        selected: size == selected,
        tooltip: size.label,
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

    return KidFloatCluster(axis: axis, children: chips);
  }
}
