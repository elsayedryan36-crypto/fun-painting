import 'package:flutter/material.dart';

import '../../common/local_data/list.dart';
import '../../common/resources/assets_manager.dart';
import '../../common/resources/color_manager.dart';
import '../models/tool_type.dart';
import 'kid_layout.dart';

/// Grid of selectable colors: [KidLayout.colorColumns] (8) kid-sized swatches
/// per row, always visible, with a ring on the one that is selected. When
/// [toolType] is [ToolType.glitter], each swatch shows the glitter texture.
///
/// ✅ CHANGED (kid-ui): the old version was a `ListView` of one
/// `GridView.count(crossAxisCount: 6)` per colour group, and the swatch was
/// whatever was left of the cell after a 6 dp margin. In portrait that panel
/// was sized from the *screen height*, so the swatches came out tiny; on a
/// wide screen the panel was narrower than its own grid. This version flattens
/// the palette into one 8-per-row grid of square, 44 dp+ targets, and lets the
/// panel (see [KidLayout.colorPanelWidth]) be exactly as wide as eight of them
/// need, so nothing is ever squeezed.
class ColorPaletteWidget extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback isColorChanged;
  final ToolType? toolType;

  const ColorPaletteWidget({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    required this.isColorChanged,
    this.toolType,
  });

  /// Every colour of every group, in the order the groups are defined (which
  /// is a rainbow: red → brown → grey → neon). Exposed for tests.
  static List<({Color color, String group})> get allSwatches => [
    for (final group in groupedPalette)
      for (final color in group.colors) (color: color, group: group.name),
  ];

  @override
  Widget build(BuildContext context) {
    final swatches = allSwatches;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        // Never stretch the swatches past [KidLayout.maxSwatch]: on a wide
        // bottom bar the grid would otherwise grow to 100 dp + circles.
        constraints: const BoxConstraints(maxWidth: KidLayout.swatchGridWidth),
        child: GridView.builder(
          padding: const EdgeInsets.all(KidLayout.swatchGridPadding),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: KidLayout.colorColumns,
            mainAxisSpacing: KidLayout.swatchGap,
            crossAxisSpacing: KidLayout.swatchGap,
          ),
          itemCount: swatches.length,
          itemBuilder: (context, index) {
            final swatch = swatches[index];
            return _ColorSwatch(
              key: Key('kid_color_swatch_$index'),
              color: swatch.color,
              name: swatch.group,
              selected: swatch.color == selectedColor,
              glitter: toolType == ToolType.glitter,
              onTap: () {
                isColorChanged();
                onColorSelected(swatch.color);
              },
            );
          },
        ),
      ),
    );

    // ----- old version (kept for reference) -----
    // return ListView.builder(
    //   itemCount: groupedPalette.length,
    //   itemBuilder: (context, groupIndex) {
    //     final group = groupedPalette[groupIndex];
    //     return Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         GridView.count(
    //           crossAxisCount: 6,
    //           shrinkWrap: true,
    //           physics: const NeverScrollableScrollPhysics(),
    //           padding: const EdgeInsets.all(8),
    //           children: group.colors.map((c) {
    //             return GestureDetector(
    //               onTap: () {
    //                 isColorChanged();
    //                 onColorSelected(c);
    //               },
    //               child: Container(
    //                 margin: const EdgeInsets.all(6),
    //                 child: Stack(
    //                   children: [
    //                     Container(
    //                       decoration: BoxDecoration(
    //                         color: c,
    //                         shape: BoxShape.circle,
    //                         border: Border.all(
    //                           color: selectedColor == c
    //                               ? ColorManager.gold
    //                               : Colors.transparent,
    //                           width: 2,
    //                         ),
    //                       ),
    //                     ),
    //                     if (toolType == ToolType.glitter)
    //                       Positioned.fill(
    //                         child: ClipOval(
    //                           child: Image.asset(
    //                             ImageAssets.glitter,
    //                             fit: BoxFit.cover,
    //                           ),
    //                         ),
    //                       ),
    //                   ],
    //                 ),
    //               ),
    //             );
    //           }).toList(),
    //         ),
    //       ],
    //     );
    //   },
    // );
  }
}

/// One tappable colour: a filled circle with a white rim (so pale colours stay
/// visible) and a thick gold ring when it is the selected one.
class _ColorSwatch extends StatelessWidget {
  final Color color;
  final String name;
  final bool selected;
  final bool glitter;
  final VoidCallback onTap;

  const _ColorSwatch({
    super.key,
    required this.color,
    required this.name,
    required this.selected,
    required this.glitter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: Tooltip(
        message: name,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? ColorManager.gold : Colors.white,
                width: selected ? 5 : 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: glitter
                ? ClipOval(
                    child: Image.asset(ImageAssets.glitter, fit: BoxFit.cover),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
