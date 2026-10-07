import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/resources/color_manager.dart';
import 'kid_layout.dart';

/// ✅ NEW (kid-ui round 6 — "Coloring Book" / Option C): the whole control
/// surface of the painting page.
///
/// The idea: the picture gets the whole screen and the app keeps out of the
/// way. There are only **two** things a child has to find:
///
///   * a big **crayon bubble** at the bottom right, under the drawing thumb —
///     tap it and the colours fan out around it;
///   * a **tool bubble** just above it — tap it and the tools fan out.
///
/// Everything else (home, save, undo) is small and out of the way.

// ---------------------------------------------------------------------------
// Bubbles
// ---------------------------------------------------------------------------

/// A round, translucent, kid-sized bubble. The building block of this UI.
class KidRoundBubble extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Face colour of the bubble (defaults to a frosted white).
  final Color? faceColor;

  /// Draws the ring used for the active choice.
  final bool selected;

  /// Accessibility label / tooltip.
  final String? tooltip;

  /// Overrides the size from [KidLayout] (used for the small corner bubbles).
  final double? size;

  const KidRoundBubble({
    super.key,
    required this.child,
    this.onTap,
    this.faceColor,
    this.selected = false,
    this.tooltip,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final side = size ?? KidLayout.bubbleSize;

    return Semantics(
      button: true,
      selected: selected,
      label: tooltip,
      child: Tooltip(
        message: tooltip ?? '',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            splashColor: ColorManager.gold.withValues(alpha: 0.35),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: side,
              height: side,
              padding: EdgeInsets.all(side * 0.15),
              decoration: BoxDecoration(
                color: faceColor ?? Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? ColorManager.gold
                      : Colors.black.withValues(alpha: 0.10),
                  width: selected ? side * 0.09 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: side * 0.18,
                    offset: Offset(0, side * 0.06),
                  ),
                ],
              ),
              child: FittedBox(fit: BoxFit.contain, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// The crayon bubble: shows the colour that is about to be painted, big and
/// obvious, and opens the colour fan.
class KidCrayonBubble extends StatelessWidget {
  final Color color;
  final bool open;
  final VoidCallback onTap;

  const KidCrayonBubble({
    super.key,
    required this.color,
    required this.onTap,
    this.open = false,
  });

  @override
  Widget build(BuildContext context) {
    final side = KidLayout.crayonBubbleSize;

    return KidRoundBubble(
      key: const Key('kid_crayon_bubble'),
      size: side,
      selected: open,
      tooltip: 'Colours',
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // A small crayon tip in the corner, so a pre-reader knows what this is.
        child: Align(
          alignment: const Alignment(0.85, 0.85),
          child: Container(
            width: side * 0.28,
            height: side * 0.28,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.brush_rounded,
              size: side * 0.20,
              color: ColorManager.darkPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small pill (undo / redo). Long, easy to hit, with a word on it.
class KidPill extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final Color? faceColor;
  final bool enabled;

  const KidPill({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.faceColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final height = KidLayout.pillHeight;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(height / 2),
          splashColor: ColorManager.gold.withValues(alpha: 0.35),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: enabled ? 1 : 0.35,
            child: Container(
              height: height,
              padding: EdgeInsets.symmetric(horizontal: height * 0.42),
              decoration: BoxDecoration(
                color: faceColor ?? Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(height / 2),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.10),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: height * 0.22,
                    offset: Offset(0, height * 0.08),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: height * 0.52,
                    height: height * 0.52,
                    child: FittedBox(fit: BoxFit.contain, child: icon),
                  ),
                  SizedBox(width: height * 0.18),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: height * 0.34,
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

// ---------------------------------------------------------------------------
// The fan
// ---------------------------------------------------------------------------

/// One choice in a fan: a colour, or an action (the "more" / "fun" circle).
class KidFanItem {
  final Color color;
  final Widget? child;
  final String? label;
  final VoidCallback onTap;
  final bool selected;

  const KidFanItem.color({
    required this.color,
    required this.onTap,
    this.selected = false,
  }) : child = null,
       label = null;

  const KidFanItem.action({
    required this.child,
    required this.label,
    required this.onTap,
  }) : color = Colors.transparent,
       selected = false;

  bool get isColor => child == null;
}

/// ✅ NEW: the fan itself — a cascade of big circles that opens around the
/// bubble that was tapped, in two arcs so the circles stay finger-sized even on
/// a small phone.
///
/// It is transparent to nothing: a dim scrim sits behind it and closes the fan
/// when tapped, so a child can always back out with one tap anywhere.
class KidFan extends StatelessWidget {
  final List<KidFanItem> items;
  final bool open;

  /// Where the bubble that opens this fan sits.
  final Alignment anchor;

  /// The list is split across two arcs; this many go on the outer one.
  final int outerCount;

  const KidFan({
    super.key,
    required this.items,
    required this.open,
    this.anchor = Alignment.bottomRight,
    this.outerCount = 7,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: open ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: IgnorePointer(
        ignoring: !open,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(
              constraints.maxWidth.isFinite ? constraints.maxWidth : 800,
              constraints.maxHeight.isFinite ? constraints.maxHeight : 400,
            );
            final centre = KidLayout.fanAnchor(size, anchor);
            final arc = KidLayout.fanArcFor(anchor);
            final outerCountHere = math.min(outerCount, items.length);
            final innerCountHere = math.max(0, items.length - outerCount);

            final outer = <Widget>[];
            final inner = <Widget>[];

            for (var i = 0; i < items.length; i++) {
              final isOuter = i < outerCount;
              final groupCount = isOuter
                  ? math.min(outerCount, items.length)
                  : items.length - outerCount;
              final indexInGroup = isOuter ? i : i - outerCount;

              final radius = isOuter
                  ? KidLayout.fanOuterRadius
                  : KidLayout.fanInnerRadius;
              final offset = KidLayout.fanDotOffset(
                index: indexInGroup,
                count: groupCount,
                radius: radius,
                arc: arc,
              );
              // Each row carries a different number of circles, so each row
              // gets the biggest size that still fits it without collisions.
              final dot = KidLayout.fanDotSizeFor(
                count: isOuter ? outerCountHere : innerCountHere,
                radius: radius,
                arc: arc,
              );

              final position = Positioned(
                key: ValueKey('kid_fan_item_$i'),
                left: centre.dx + offset.dx - dot / 2,
                top: centre.dy + offset.dy - dot / 2,
                child: _FanDot(
                  item: items[i],
                  size: dot,
                  // A little cascade, so the fan feels like it pops open.
                  delayMs: 16 * i,
                ),
              );

              (isOuter ? outer : inner).add(position);
            }

            return Stack(
              children: [
                // Tap anywhere to close.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                ...inner,
                ...outer,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FanDot extends StatelessWidget {
  final KidFanItem item;
  final double size;
  final int delayMs;

  const _FanDot({
    required this.item,
    required this.size,
    required this.delayMs,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + delayMs),
      curve: Curves.easeOutBack,
      builder: (context, t, child) =>
          Transform.scale(scale: t.clamp(0.0, 1.6), child: child),
      child: Semantics(
        button: true,
        selected: item.selected,
        label: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: item.isColor ? item.color : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.selected
                      ? ColorManager.darkPrimary
                      : Colors.white,
                  width: item.selected ? size * 0.13 : size * 0.09,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: size * 0.16,
                    offset: Offset(0, size * 0.05),
                  ),
                ],
              ),
              child: item.isColor
                  ? null
                  : Padding(
                      padding: EdgeInsets.all(size * 0.22),
                      child: FittedBox(fit: BoxFit.contain, child: item.child),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
