import 'package:flutter/material.dart';

import '../../common/local_data/list.dart';
import '../../common/resources/assets_manager.dart';
import '../../common/resources/color_manager.dart';
import '../models/tool_type.dart';

/// Grid of selectable colors, grouped into palette rows. When [toolType]
/// is [ToolType.glitter], each swatch is overlaid with a glitter texture.
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

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: groupedPalette.length,
      itemBuilder: (context, groupIndex) {
        final group = groupedPalette[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              children: group.colors.map((c) {
                return GestureDetector(
                  onTap: () {
                    isColorChanged();
                    onColorSelected(c);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    child: Stack(
                      children: [
                        // Background color circle
                        Container(
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == c
                                  ? ColorManager.gold
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        if (toolType == ToolType.glitter)
                          Positioned.fill(
                            child: ClipOval(
                              child: Image.asset(
                                ImageAssets.glitter,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
