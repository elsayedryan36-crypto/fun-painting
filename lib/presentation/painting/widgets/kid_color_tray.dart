import 'package:flutter/material.dart';

import '../../common/resources/color_manager.dart';
import 'kid_layout.dart';

/// ✅ NEW (Option B, round 7) — "your app + a colour tray".
///
/// The app's own layout is kept as it is (canvas + the two floating rails);
/// the one thing that changes is the colour panel: instead of a panel that
/// floats over the drawing when the child opens it, the colours live in a
/// **tray along the bottom of the screen, always visible**.
///
/// Why this shape:
/// * the tray has a strip of its own, so it can never cover the picture;
/// * every colour is one tap away — no opening, no second tap;
/// * the buttons that used to sit on the rails (tools, eraser, clear) are
///   repeated here, under the thumb, where a child looks for them;
/// * the full 78-colour grid is still there behind "more" (＋) and behind the
///   colour-preview button, so nothing is lost.
///
/// The tray is deliberately dumb: it paints nothing and holds no state. Every
/// tap is handed back to the page through a callback.
class KidColorTray extends StatelessWidget {
  const KidColorTray({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
    required this.onMoreColors,
    required this.onTools,
    required this.onEraser,
    required this.onClear,
    this.moreOpen = false,
    this.toolsOpen = false,
  });

  /// Every colour the app has, in the order the palette shows them
  /// (`ColorPaletteWidget.allSwatches`).
  final List<Color> colors;

  /// The colour that will paint the next stroke — shown with a ring, so the
  /// child can always see what is "in their hand".
  final Color selectedColor;

  final ValueChanged<Color> onColorSelected;

  /// The ＋ button and the colour-preview button both open the full grid.
  final VoidCallback onMoreColors;
  final VoidCallback onTools;
  final VoidCallback onEraser;
  final VoidCallback onClear;

  /// Highlight the buttons whose panel is currently open.
  final bool moreOpen;
  final bool toolsOpen;

  /// Stable keys so a widget test (and a QA script) can find everything.
  static const Key trayKey = Key('kid_color_tray');
  static const Key stripKey = Key('kid_tray_strip');
  static const Key moreKey = Key('kid_tray_more');
  static const Key colorKey = Key('kid_tray_color');
  static const Key toolsKey = Key('kid_tray_tools');
  static const Key eraserKey = Key('kid_tray_eraser');
  static const Key clearKey = Key('kid_tray_clear');
  static Key swatchKey(int index) => Key('kid_tray_swatch_$index');

  @override
  Widget build(BuildContext context) {
    final height = KidLayout.trayHeight;
    final dot = KidLayout.trayDotSize;
    final button = KidLayout.trayButtonSize;

    return Container(
      key: trayKey,
      height: height,
      decoration: BoxDecoration(
        color: ColorManager.darkPrimary,
        // A shadow along the top edge separates the tray from the picture,
        // which is what makes "the tray is below the drawing, not on it" read
        // at a glance.
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ---- the colours themselves: always visible, one tap each -------
          Expanded(
            child: ListView.builder(
              key: stripKey,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: KidLayout.trayPadding),
              itemCount: colors.length,
              // Each cell is wider than its dot, so the tap target is a
              // fingertip even for a small dot (and the whole tray height
              // tall).
              itemExtent: dot + KidLayout.trayGap,
              itemBuilder: (context, index) => _KidTraySwatch(
                index: index,
                color: colors[index],
                size: dot,
                selected: colors[index] == selectedColor,
                onTap: () => onColorSelected(colors[index]),
              ),
            ),
          ),
          _KidTrayDivider(height: height),

          // ---- the buttons, all fingertip-sized --------------------------
          KidTrayButton(
            key: moreKey,
            size: button,
            label: 'More',
            icon: Icons.add,
            active: moreOpen,
            onTap: onMoreColors,
          ),
          KidTrayButton(
            key: colorKey,
            size: button,
            label: 'Colour',
            // The face of this button IS the current colour.
            faceColor: selectedColor,
            active: moreOpen,
            onTap: onMoreColors,
          ),
          _KidTrayDivider(height: height),
          KidTrayButton(
            key: toolsKey,
            size: button,
            label: 'Tools',
            icon: Icons.brush,
            active: toolsOpen,
            onTap: onTools,
          ),
          KidTrayButton(
            key: eraserKey,
            size: button,
            label: 'Eraser',
            icon: Icons.auto_fix_normal,
            onTap: onEraser,
          ),
          KidTrayButton(
            key: clearKey,
            size: button,
            label: 'Clear',
            icon: Icons.delete_outline,
            onTap: onClear,
          ),
          SizedBox(width: KidLayout.trayPadding),
        ],
      ),
    );
  }
}

/// One colour dot of the tray. The tappable area is the whole cell (a tall,
/// finger-wide rectangle); the coloured circle is drawn in the middle of it.
class _KidTraySwatch extends StatelessWidget {
  const _KidTraySwatch({
    required this.index,
    required this.color,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final Color color;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'colour ${index + 1}',
      child: GestureDetector(
        key: KidColorTray.swatchKey(index),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              // The colour "in the hand" is ringed in the app's gold, so the
              // child can see what will paint the next stroke.
              border: Border.all(
                color: selected ? ColorManager.gold : const Color(0x59FFFFFF),
                width: selected ? 3 : 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tray button: a rounded square face with an icon (or a colour dot) and a
/// word under it. Sized from [KidLayout] like everything else.
class KidTrayButton extends StatelessWidget {
  const KidTrayButton({
    super.key,
    required this.size,
    required this.label,
    required this.onTap,
    this.icon,
    this.faceColor,
    this.active = false,
  });

  /// The face: at least 48 dp (the platform minimum, and what the proposal
  /// asks for: 48–56 dp targets).
  final double size;

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  /// If set, the face is a filled circle of this colour instead of an icon
  /// (the "colour preview" button).
  final Color? faceColor;

  final bool active;

  @override
  Widget build(BuildContext context) {
    final face = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? const Color(0x33FFD700) : const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: active ? ColorManager.gold : const Color(0x40FFFFFF),
          width: 2,
        ),
      ),
      child: faceColor != null
          ? Center(
              child: Container(
                width: size * 0.52,
                height: size * 0.52,
                decoration: BoxDecoration(
                  color: faceColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            )
          : Icon(icon, size: size * 0.5, color: Colors.white),
    );

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // The tap target is the full tray height (and a little wider than the
        // face), never just the drawn square.
        child: SizedBox(
          width: size + KidLayout.trayGap,
          height: KidLayout.trayHeight,
          child: Center(
            // If a very short screen leaves no room for face + word, the
            // whole button shrinks together instead of overflowing.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  face,
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: KidLayout.trayLabelSize(size),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

class _KidTrayDivider extends StatelessWidget {
  const _KidTrayDivider({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: height * 0.62,
      margin: EdgeInsets.symmetric(horizontal: KidLayout.trayPadding * 0.5),
      color: const Color(0x33FFFFFF),
    );
  }
}
