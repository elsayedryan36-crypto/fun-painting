import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../common/resources/assets_manager.dart';
import '../coloring_canvas.dart';
import '../models/tool_type.dart';
import '../region.dart';
import 'kid_controls.dart';

/// Grid of the seven drawing tools, opened from the "Tools" button on the rail.
///
/// ✅ CHANGED (kid-ui): every tool used to be sized `width: % of screen HEIGHT,
/// height: % of screen WIDTH` (the units were swapped), inside a card that was
/// itself a percentage of the screen. On a wide screen the buttons came out
/// 156 dp tall inside an 83 dp strip, i.e. they overflowed. Each tool is now a
/// fixed 64 dp [KidRailButton], and the palette simply fills the docked panel
/// it is placed in.
class ToolPaletteWidget extends StatelessWidget {
  final BrushMode mode;
  final Color selectedColor;
  final StrokeStyle selectedStyle;
  final SelectedTool? selectedTool;
  final ValueChanged<BrushMode> onModeChanged;
  final ValueChanged<StrokeStyle> onStyleChanged;
  final ValueChanged<SelectedTool> onToolSelected;
  final VoidCallback isToolOpen;
  final String? selectedStampAsset;
  final List<String> stamps;

  const ToolPaletteWidget({
    super.key,
    required this.mode,
    required this.selectedColor,
    required this.selectedStyle,
    required this.selectedTool,
    required this.onModeChanged,
    required this.onStyleChanged,
    required this.onToolSelected,
    required this.isToolOpen,
    this.selectedStampAsset,
    required this.stamps,
  });

  @override
  Widget build(BuildContext context) {
    // Fill the docked panel; wrap into rows and scroll if the panel is small.
    // ✅ CHANGED (kid-ui): the old version was a single scrolling row, which
    // left a tall side panel mostly empty.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          if (selectedTool?.type != ToolType.fill) _buildFillTool(),
          if (selectedTool?.type != ToolType.glitter) _buildGlitterTool(),
          if (selectedTool?.type != ToolType.freehand) _buildFreehandTool(),
          if (selectedTool?.type != ToolType.pencil) _buildPencilTool(),
          if (selectedTool?.type != ToolType.wallpaper) _buildWallPaperTool(),
          if (selectedTool?.type != ToolType.stamp) _buildStampTool(),
          if (selectedTool?.type != ToolType.magic) _buildMagicTool(),
        ],
      ),
    );
  }

  Widget _buildMagicTool() {
    return KidRailButton(
      onTap: () {
        isToolOpen();
        onToolSelected(
          SelectedTool(
            mode: BrushMode.magic,
            style: StrokeStyle.solid,
            type: ToolType.magic,
          ),
        );
      },
      child: Image.asset(ImageAssets.magic, fit: BoxFit.scaleDown),
    );
  }

  Widget _buildStampTool() {
    return KidRailButton(
      onTap: () {
        isToolOpen();
        onToolSelected(
          SelectedTool(
            mode: BrushMode.stamp,
            style: StrokeStyle.solid,
            type: ToolType.stamp,
          ),
        );
      },
      child: SvgPicture.asset(ImageAssets.stamp, fit: BoxFit.scaleDown),
    );
  }

  Widget _buildWallPaperTool() {
    return KidRailButton(
      onTap: () {
        isToolOpen();
        onToolSelected(
          SelectedTool(
            mode: BrushMode.freehand,
            style: StrokeStyle.wallpaper,
            type: ToolType.wallpaper,
          ),
        );
      },
      child: SvgPicture.asset(ImageAssets.wallpaper, fit: BoxFit.scaleDown),
    );
  }

  Widget _buildFillTool() {
    return KidRailButton(
      onTap: () {
        isToolOpen();
        onToolSelected(
          SelectedTool(
            mode: BrushMode.fill,
            style: StrokeStyle.solid,
            type: ToolType.fill,
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(ImageAssets.fill1, fit: BoxFit.contain),
          SvgPicture.asset(
            ImageAssets.fill2,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
          ),
        ],
      ),
    );
  }

  Widget _buildGlitterTool() {
    return KidRailButton(
      onTap: () {
        isToolOpen();
        onToolSelected(
          SelectedTool(
            mode: BrushMode.freehand,
            style: StrokeStyle.glitter,
            type: ToolType.glitter,
          ),
        );
      },
      child: Stack(
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
      ),
    );
  }

  Widget _buildFreehandTool() {
    return KidRailButton(
      onTap: () {
        isToolOpen();
        onToolSelected(
          SelectedTool(
            mode: BrushMode.freehand,
            style: StrokeStyle.solid,
            type: ToolType.freehand,
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(ImageAssets.freeHand1, fit: BoxFit.contain),
          SvgPicture.asset(
            ImageAssets.freeHand2,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
          ),
        ],
      ),
    );
  }

  Widget _buildPencilTool() {
    return KidRailButton(
      onTap: () {
        isToolOpen();
        onToolSelected(
          SelectedTool(
            mode: BrushMode.freehand,
            style: StrokeStyle.neon,
            type: ToolType.pencil,
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            ImageAssets.pencil1,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
          ),
          SvgPicture.asset(ImageAssets.pencil2, fit: BoxFit.contain),
        ],
      ),
    );
  }
}

// ----- old version (kept for reference) -----
// The previous implementation wrapped everything in a card sized as a
// percentage of the screen and sized each tool with swapped units
// (`width: AppSizeHeight.s20, height: AppSizeWidth.s20`), which overflowed on
// wide screens.
//
// class ToolPaletteWidget extends StatelessWidget {
//   ... same fields ...
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.symmetric(
//         vertical: AppSizeHeight.s1,
//         horizontal: AppSizeHeight.s1,
//       ),
//       decoration: BoxDecoration(
//         color: ColorManager.darkPrimary,
//         border: Border(
//           top: BorderSide(color: ColorManager.darkPrimary, width: AppSizeHeight.s0_5),
//           left: BorderSide(color: ColorManager.darkPrimary, width: AppSizeHeight.s0_5),
//           bottom: BorderSide(color: ColorManager.darkPrimary, width: AppSizeHeight.s0_5),
//         ),
//         borderRadius: BorderRadius.all(Radius.circular(AppSizeWidth.s4)),
//       ),
//       height: AppSizeHeight.s23,
//       width: AppSizeWidth.s62,
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             if (selectedTool?.type != ToolType.fill) _buildFillTool(),
//             if (selectedTool?.type != ToolType.glitter) _buildGlitterTool(),
//             if (selectedTool?.type != ToolType.freehand) _buildFreehandTool(),
//             if (selectedTool?.type != ToolType.pencil) _buildPencilTool(),
//             if (selectedTool?.type != ToolType.wallpaper) _buildWallPaperTool(),
//             if (selectedTool?.type != ToolType.stamp) _buildStampTool(),
//             if (selectedTool?.type != ToolType.magic) _buildMagicTool(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMagicTool() {
//     return Container(
//       margin: EdgeInsets.all(AppSizeHeight.s1),
//       decoration: BoxDecoration(
//         color: ColorManager.white,
//         border: Border.all(color: ColorManager.gold, width: AppSizeHeight.s1),
//         borderRadius: BorderRadius.all(Radius.circular(AppSizeWidth.s4)),
//       ),
//       width: AppSizeHeight.s20,
//       height: AppSizeWidth.s20,
//       child: GestureDetector(
//         onTap: () { isToolOpen(); onToolSelected(SelectedTool(mode: BrushMode.magic, style: StrokeStyle.solid, type: ToolType.magic)); },
//         child: Image.asset(ImageAssets.magic, fit: BoxFit.scaleDown),
//       ),
//     );
//   }
//
//   Widget _buildStampTool() { ... same but child: Stack(children: [SvgPicture.asset(ImageAssets.stamp, fit: BoxFit.scaleDown)]) ... }
//   Widget _buildWallPaperTool() { ... ToolType.wallpaper, StrokeStyle.wallpaper ... }
//   Widget _buildFillTool() { ... Stack of fill1 + fill2 tinted with selectedColor ... }
//   Widget _buildGlitterTool() { ... Stack of glitter1/2/3 ... }
//   Widget _buildFreehandTool() { ... Stack of freeHand1/2 ... }
//   Widget _buildPencilTool() { ... Center(child: Container(... pencil1 tinted + pencil2 ...)) ... }
// }
