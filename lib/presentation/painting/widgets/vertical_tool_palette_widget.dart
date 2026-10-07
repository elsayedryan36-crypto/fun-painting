import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../common/resources/assets_manager.dart';
import '../coloring_canvas.dart';
import '../models/brush_size.dart';
import '../models/tool_type.dart';
import 'kid_controls.dart';

/// The main tool rail: current colour / pattern / stamp, current tool, eraser
/// and clear.
///
/// ✅ CHANGED (kid-ui round 3): six buttons — colour, tools, eraser and the
/// S / M / L sizes (clear has moved to the left rail, next to Undo). Every
/// button is sized as a percentage of the screen by [KidRail] instead of a
/// fixed 64 dp, has a bright face colour so a pre-reader can tell them apart,
/// and carries a short word under the icon.
///
/// ✅ CHANGED (kid-ui): the old version sized its container as
/// `height: 98% of screen height` and `width: 22% of screen height` — and then
/// put 20%-of-screen-height-wide children inside it. On a wide screen the
/// container was narrower than its own children (they overflowed), and the
/// whole thing floated over the drawing. It is now a docked rail of fixed
/// 64 dp buttons that never covers the canvas, laid out vertically (side rail)
/// or horizontally (bottom bar) depending on the screen shape.
class VerticalToolPaletteWidget extends StatelessWidget {
  final VoidCallback onEraserSelected;
  final VoidCallback onMagicSelected;
  // ✅ CHANGED (kid-ui round 3): clear moved to the action rail.
  // ----- old version (kept for reference) -----
  // final VoidCallback onClearSelected;
  final Color selectedColor;
  final VoidCallback isToolOpen;
  final VoidCallback isColorOpen;
  final SelectedTool? selectedTool;
  final String selectedImage;
  final String? selectedStampAsset;
  final List<String> stamps;
  final BrushMode brushMode;

  /// ✅ NEW (kid-ui): the current S / M / L brush preset and its callback.
  final BrushSize brushSize;
  final ValueChanged<BrushSize> onBrushSizeChanged;

  /// ✅ NEW: Axis.vertical = side rail, Axis.horizontal = bottom bar.
  final Axis axis;

  const VerticalToolPaletteWidget({
    super.key,
    required this.onEraserSelected,
    required this.onMagicSelected,
    required this.selectedColor,
    required this.isToolOpen,
    required this.isColorOpen,
    required this.selectedTool,
    required this.selectedImage,
    this.selectedStampAsset,
    required this.stamps,
    // ----- old version (kept for reference) -----
    // required this.onClearSelected,
    required this.brushMode,
    required this.brushSize,
    required this.onBrushSizeChanged,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return KidRail(
      axis: axis,
      children: [
        // 1. Current colour / pattern / stamp — opens the matching panel.
        KidRailButton(
          onTap: isColorOpen,
          label: 'Colour',
          faceColor: selectedColor,
          // Pale colours need dark ink, dark colours need white ink.
          inkColor: _inkOn(selectedColor),
          child: _buildPreview(),
        ),

        // 2. Current tool — opens the tool grid. Amber face: the "paints"
        // button.
        KidRailButton(
          onTap: isToolOpen,
          label: 'Tools',
          faceColor: const Color(0xFFFFE082),
          child: _buildSelectedToolIcon(),
        ),

        // 3. Eraser — pink face, and it shows when it is the active mode.
        KidRailButton(
          onTap: onEraserSelected,
          label: 'Eraser',
          selected: brushMode == BrushMode.eraser,
          faceColor: const Color(0xFFF8BBD0),
          child: Image.asset(ImageAssets.eraser, fit: BoxFit.contain),
        ),

        // 4. The S / M / L brush sizes, replacing the widths that used to be
        // hard-coded in coloring_painter.dart (15.0 / 14.0 / 12.0 / 8.0) with
        // a control the child can actually see and press. Handed to the rail
        // as three items so it sizes them like every other button.
        ...KidBrushSizeControl.railButtons(
          selected: brushSize,
          onChanged: onBrushSizeChanged,
          previewColor: selectedColor,
        ),

        // ----- old version (kept for reference) -----
        // KidBrushSizeControl(
        //   selected: brushSize,
        //   onChanged: onBrushSizeChanged,
        //   previewColor: selectedColor,
        //   axis: axis,
        // ),
        //
        // // 5. Clear everything — moved to the left rail in round 3 so a small
        // // finger cannot hit it while reaching for the eraser.
        // KidRailButton(
        //   onTap: onClearSelected,
        //   label: 'Clear',
        //   child: SvgPicture.asset(ImageAssets.delete, fit: BoxFit.contain),
        // ),
      ],
    );
  }

  /// White ink on a dark face, dark ink on a light one, so the word under the
  /// icon stays readable whatever colour the child picked.
  static Color _inkOn(Color face) =>
      face.computeLuminance() < 0.45 ? Colors.white : const Color(0xFF1A1A1A);

  /// Small preview of whatever the colour panel will let the child change:
  /// a colour, a wallpaper pattern, a stamp, or the magic wand.
  Widget _buildPreview() {
    if (selectedTool?.type == ToolType.wallpaper) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(selectedImage, fit: BoxFit.cover),
      );
    }

    if (selectedTool?.type == ToolType.stamp) {
      final currentStamp =
          selectedStampAsset ?? (stamps.isNotEmpty ? stamps[0] : null);
      if (currentStamp != null) {
        return SvgPicture.asset(currentStamp, fit: BoxFit.scaleDown);
      }
      return const SizedBox.shrink();
    }

    if (selectedTool?.type == ToolType.magic) {
      return Image.asset(ImageAssets.magic, fit: BoxFit.scaleDown);
    }

    // Plain colour swatch (with the glitter texture on top when it applies).
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: selectedColor,
        child: selectedTool?.type == ToolType.glitter
            ? Image.asset(ImageAssets.glitter, fit: BoxFit.cover)
            : null,
      ),
    );
  }

  Widget _buildSelectedToolIcon() {
    if (selectedTool == null) {
      return const SizedBox.shrink();
    }

    switch (selectedTool!.type) {
      case ToolType.fill:
        return Stack(
          fit: StackFit.expand,
          children: [
            SvgPicture.asset(ImageAssets.fill1, fit: BoxFit.contain),
            SvgPicture.asset(
              ImageAssets.fill2,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
            ),
          ],
        );
      case ToolType.glitter:
        return Stack(
          fit: StackFit.expand,
          children: [
            SvgPicture.asset(ImageAssets.glitter1, fit: BoxFit.contain),
            SvgPicture.asset(ImageAssets.glitter2, fit: BoxFit.contain),
            SvgPicture.asset(
              ImageAssets.glitter3,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
            ),
          ],
        );
      case ToolType.freehand:
        return Stack(
          fit: StackFit.expand,
          children: [
            SvgPicture.asset(ImageAssets.freeHand1, fit: BoxFit.contain),
            SvgPicture.asset(
              ImageAssets.freeHand2,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
            ),
          ],
        );
      case ToolType.pencil:
        return Stack(
          fit: StackFit.expand,
          children: [
            SvgPicture.asset(
              ImageAssets.pencil1,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
            ),
            SvgPicture.asset(ImageAssets.pencil2, fit: BoxFit.contain),
          ],
        );
      case ToolType.wallpaper:
        return SvgPicture.asset(ImageAssets.wallpaper, fit: BoxFit.contain);
      case ToolType.stamp:
        return SvgPicture.asset(ImageAssets.stamp, fit: BoxFit.scaleDown);
      case ToolType.magic:
        return Image.asset(ImageAssets.magic, fit: BoxFit.scaleDown);
    }
  }
}

// ----- old version (kept for reference) -----
// The previous implementation: a floating card whose container and children
// were both sized as percentages of the screen, so on a wide screen the
// children (156 dp wide) overflowed the 79 dp container.
//
// class VerticalToolPaletteWidget extends StatelessWidget {
//   ... same fields, no `axis` ...
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.symmetric(vertical: AppSizeHeight.s1),
//       decoration: BoxDecoration(
//         color: ColorManager.darkPrimary,
//         border: Border(
//           top: BorderSide(color: ColorManager.darkPrimary, width: AppSizeHeight.s0_5),
//           left: BorderSide(color: ColorManager.darkPrimary, width: AppSizeHeight.s0_5),
//           bottom: BorderSide(color: ColorManager.darkPrimary, width: AppSizeHeight.s0_5),
//         ),
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(AppSizeWidth.s4),
//           bottomLeft: Radius.circular(AppSizeWidth.s4),
//         ),
//       ),
//       height: AppSizeHeight.s98,
//       width: AppSizeHeight.s22,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildEraserTool(brushMode),
//           _buildClearTool(),
//           _buildColorPatternOrStamp(brushMode),
//           _buildToolSelected(brushMode),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildColorPatternOrStamp(BrushMode brushMode) {
//     if (selectedTool?.type == ToolType.wallpaper) {
//       return _buildPatternSelected();
//     } else if (selectedTool?.type == ToolType.stamp) {
//       return _buildStampSelected();
//     } else if (selectedTool?.type == ToolType.magic) {
//       return _buildMagicSelected();
//     } else {
//       return _buildColorSelected();
//     }
//   }
//
//   Widget _buildMagicSelected() => ClipRRect(... Container(
//         height: AppSizeHeight.s26,
//         width: AppSizeWidth.s20,
//         child: GestureDetector(onTap: () {}, child: Center(child: Image.asset(ImageAssets.magic, fit: BoxFit.scaleDown))),
//       ));
//
//   Widget _buildClearTool() => ClipRRect(... Container(
//         height: AppSizeHeight.s18,
//         width: AppSizeWidth.s20,
//         child: GestureDetector(onTap: onClearSelected, child: SvgPicture.asset(ImageAssets.delete, fit: BoxFit.cover)),
//       ));
//
//   Widget _buildEraserTool(dynamic widget) => ClipRRect(... Container(
//         height: AppSizeHeight.s18,
//         width: AppSizeWidth.s20,
//         child: GestureDetector(onTap: onEraserSelected, child: Image.asset(ImageAssets.eraser, fit: BoxFit.scaleDown)),
//       ));
//
//   Widget _buildColorSelected() => GestureDetector(
//         onTap: isColorOpen,
//         child: Container(
//           height: AppSizeHeight.s26,
//           width: AppSizeWidth.s20,
//           decoration: BoxDecoration(color: selectedColor, ...),
//           child: selectedTool?.type == ToolType.glitter ? ClipRRect(...Image.asset(ImageAssets.glitter, fit: BoxFit.cover)) : SizedBox(),
//         ),
//       );
//
//   Widget _buildPatternSelected() => ... Image.asset(selectedImage, fit: BoxFit.cover) ...
//   Widget _buildStampSelected() => ... SvgPicture.asset(currentStamp, fit: BoxFit.scaleDown) ...
//   Widget _buildToolSelected(BrushMode brushMode) => ... GestureDetector(onTap: isToolOpen, child: _buildSelectedToolIcon()) ...
//   Widget _buildSelectedToolIcon() => (unchanged — kept above)
