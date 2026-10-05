import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../common/resources/assets_manager.dart';
import '../../common/resources/color_manager.dart';
import '../../common/resources/values_manager.dart';
import '../coloring_canvas.dart';
import '../models/tool_type.dart';
import '../region.dart';

/// Horizontal palette that lets the user pick which drawing tool to use
/// (fill, glitter, freehand, pencil, wallpaper, stamp or magic).
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
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: AppSizeHeight.s1,
        horizontal: AppSizeHeight.s1,
      ),
      decoration: BoxDecoration(
        color: ColorManager.darkPrimary,
        border: Border(
          top: BorderSide(
            color: ColorManager.darkPrimary,
            width: AppSizeHeight.s0_5,
          ),
          left: BorderSide(
            color: ColorManager.darkPrimary,
            width: AppSizeHeight.s0_5,
          ),
          bottom: BorderSide(
            color: ColorManager.darkPrimary,
            width: AppSizeHeight.s0_5,
          ),
        ),
        borderRadius: BorderRadius.all(Radius.circular(AppSizeWidth.s4)),
      ),
      height: AppSizeHeight.s23,
      width: AppSizeWidth.s62,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
      ),
    );
  }

  Widget _buildMagicTool() {
    return Container(
      margin: EdgeInsets.all(AppSizeHeight.s1),
      decoration: BoxDecoration(
        color: ColorManager.white,
        border: Border.all(color: ColorManager.gold, width: AppSizeHeight.s1),
        borderRadius: BorderRadius.all(Radius.circular(AppSizeWidth.s4)),
      ),
      width: AppSizeHeight.s20,
      height: AppSizeWidth.s20,
      child: GestureDetector(
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
      ),
    );
  }

  Widget _buildStampTool() {
    return Container(
      margin: EdgeInsets.all(AppSizeHeight.s1),
      decoration: BoxDecoration(
        color: ColorManager.white,
        border: Border.all(color: ColorManager.gold, width: AppSizeHeight.s1),
        borderRadius: BorderRadius.all(Radius.circular(AppSizeWidth.s4)),
      ),
      width: AppSizeHeight.s20,
      height: AppSizeWidth.s20,
      child: GestureDetector(
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
        child: Stack(
          children: [
            SvgPicture.asset(ImageAssets.stamp, fit: BoxFit.scaleDown),
          ],
        ),
      ),
    );
  }

  Widget _buildWallPaperTool() {
    return Container(
      margin: EdgeInsets.all(AppSizeHeight.s1),
      decoration: BoxDecoration(
        color: ColorManager.white,
        border: Border.all(color: ColorManager.gold, width: AppSizeHeight.s1),
        borderRadius: BorderRadius.all(Radius.circular(AppSizeWidth.s4)),
      ),
      width: AppSizeHeight.s20,
      height: AppSizeWidth.s20,
      child: GestureDetector(
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
        child: Stack(
          children: [
            SvgPicture.asset(ImageAssets.wallpaper, fit: BoxFit.scaleDown),
          ],
        ),
      ),
    );
  }

  Widget _buildFillTool() {
    return Container(
      margin: EdgeInsets.all(AppSizeHeight.s1),
      decoration: BoxDecoration(
        color: ColorManager.white,
        border: Border.all(color: ColorManager.gold, width: AppSizeHeight.s1),
        borderRadius: BorderRadius.all(Radius.circular(AppSizeWidth.s4)),
      ),
      width: AppSizeHeight.s20,
      height: AppSizeWidth.s20,
      child: GestureDetector(
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
          children: [
            SvgPicture.asset(ImageAssets.fill1, fit: BoxFit.scaleDown),
            SvgPicture.asset(
              ImageAssets.fill2,
              fit: BoxFit.scaleDown,
              colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlitterTool() {
    return Container(
      margin: EdgeInsets.all(AppSizeHeight.s1),
      decoration: BoxDecoration(
        color: ColorManager.white,
        border: Border.all(color: ColorManager.gold, width: AppSizeHeight.s1),
        borderRadius: BorderRadius.all(Radius.circular(AppSizeWidth.s4)),
      ),
      width: AppSizeHeight.s20,
      height: AppSizeWidth.s20,
      child: GestureDetector(
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
          children: [
            SvgPicture.asset(ImageAssets.glitter1, fit: BoxFit.scaleDown),
            SvgPicture.asset(ImageAssets.glitter2, fit: BoxFit.scaleDown),
            SvgPicture.asset(
              ImageAssets.glitter3,
              fit: BoxFit.scaleDown,
              colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreehandTool() {
    return Container(
      margin: EdgeInsets.all(AppSizeHeight.s1),
      decoration: BoxDecoration(
        color: ColorManager.white,
        border: Border.all(color: ColorManager.gold, width: AppSizeHeight.s1),
        borderRadius: BorderRadius.all(Radius.circular(AppSizeWidth.s4)),
      ),
      width: AppSizeHeight.s20,
      height: AppSizeWidth.s20,
      child: GestureDetector(
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
          children: [
            SvgPicture.asset(ImageAssets.freeHand1, fit: BoxFit.scaleDown),
            SvgPicture.asset(
              ImageAssets.freeHand2,
              fit: BoxFit.scaleDown,
              colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPencilTool() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(AppSizeHeight.s1),
        decoration: BoxDecoration(
          color: ColorManager.white,
          border: Border.all(color: ColorManager.gold, width: AppSizeHeight.s1),
          borderRadius: BorderRadius.all(Radius.circular(AppSizeWidth.s4)),
        ),
        width: AppSizeHeight.s20,
        height: AppSizeWidth.s20,
        child: GestureDetector(
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
            children: [
              SvgPicture.asset(
                ImageAssets.pencil1,
                fit: BoxFit.scaleDown,
                colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
              ),
              SvgPicture.asset(ImageAssets.pencil2, fit: BoxFit.scaleDown),
            ],
          ),
        ),
      ),
    );
  }
}
