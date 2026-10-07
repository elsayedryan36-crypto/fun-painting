import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../common/resources/assets_manager.dart';
import '../../common/resources/color_manager.dart';
import '../../common/resources/values_manager.dart';
import '../coloring_canvas.dart';
import '../models/tool_type.dart';

/// Vertical palette showing the currently selected tool, its color /
/// pattern / stamp, plus quick access to the eraser and clear actions.
class VerticalToolPaletteWidget extends StatelessWidget {
  final VoidCallback onEraserSelected;
  final VoidCallback onMagicSelected;
  final VoidCallback onClearSelected;
  final Color selectedColor;
  final VoidCallback isToolOpen;
  final VoidCallback isColorOpen;
  final SelectedTool? selectedTool;
  final String selectedImage;
  final String? selectedStampAsset;
  final List<String> stamps;
  final BrushMode brushMode;

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
    required this.onClearSelected,
    required this.brushMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSizeHeight.s1),
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
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSizeWidth.s4),
          bottomLeft: Radius.circular(AppSizeWidth.s4),
        ),
      ),
      height: AppSizeHeight.s98,
      width: AppSizeHeight.s22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEraserTool(brushMode),
          _buildClearTool(),
          _buildColorPatternOrStamp(brushMode),
          _buildToolSelected(brushMode),
        ],
      ),
    );
  }

  Widget _buildColorPatternOrStamp(BrushMode brushMode) {
    if (selectedTool?.type == ToolType.wallpaper) {
      return _buildPatternSelected();
    } else if (selectedTool?.type == ToolType.stamp) {
      return _buildStampSelected();
    } else if (selectedTool?.type == ToolType.magic) {
      return _buildMagicSelected();
    } else {
      return _buildColorSelected();
    }
  }

  Widget _buildMagicSelected() {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppSizeWidth.s4),
      ),
      child: Container(
        margin: EdgeInsets.all(AppSizeHeight.s1),
        decoration: BoxDecoration(
          color: ColorManager.white,
          border: Border.all(color: ColorManager.gold, width: AppSizeHeight.s1),
          borderRadius: BorderRadius.all(Radius.circular(AppSizeWidth.s4)),
        ),
        height: AppSizeHeight.s26,
        width: AppSizeWidth.s20,
        child: GestureDetector(
          onTap: () {},
          child: Center(
            child: Image.asset(ImageAssets.magic, fit: BoxFit.scaleDown),
          ),
        ),
      ),
    );
  }

  Widget _buildClearTool() {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppSizeWidth.s4),
      ),
      child: Container(
        margin: EdgeInsets.all(AppSizeHeight.s1),
        decoration: BoxDecoration(
          color: ColorManager.white,
          border: Border.all(color: ColorManager.grey, width: AppSizeHeight.s1),
          borderRadius: BorderRadius.all(Radius.circular(AppSizeWidth.s4)),
        ),
        height: AppSizeHeight.s18,
        width: AppSizeWidth.s20,
        child: GestureDetector(
          onTap: onClearSelected,
          child: SvgPicture.asset(ImageAssets.delete, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildEraserTool(dynamic widget) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppSizeWidth.s4),
      ),
      child: Container(
        margin: EdgeInsets.all(AppSizeHeight.s1),
        decoration: BoxDecoration(
          color: ColorManager.white,
          border: Border.all(
            color: brushMode == BrushMode.eraser
                ? ColorManager.gold
                : ColorManager.grey,
            width: AppSizeHeight.s1,
          ),
          borderRadius: BorderRadius.all(Radius.circular(AppSizeWidth.s4)),
        ),
        height: AppSizeHeight.s18,
        width: AppSizeWidth.s20,
        child: GestureDetector(
          onTap: onEraserSelected,
          child: Image.asset(ImageAssets.eraser, fit: BoxFit.scaleDown),
        ),
      ),
    );
  }

  Widget _buildColorSelected() {
    return GestureDetector(
      onTap: isColorOpen,
      child: Container(
        margin: EdgeInsets.all(AppSizeHeight.s1),
        decoration: BoxDecoration(
          color: selectedColor,
          border: Border.all(
            color: brushMode != BrushMode.eraser
                ? ColorManager.gold
                : ColorManager.grey,
            width: AppSizeHeight.s1,
          ),
          borderRadius: BorderRadius.all(Radius.circular(AppSizeWidth.s4)),
        ),
        height: AppSizeHeight.s26,
        width: AppSizeWidth.s20,
        child: selectedTool?.type == ToolType.glitter
            ? ClipRRect(
                borderRadius: BorderRadius.all(
                  Radius.circular(AppSizeWidth.s4),
                ),
                child: Image.asset(ImageAssets.glitter, fit: BoxFit.cover),
              )
            : SizedBox(),
      ),
    );
  }

  Widget _buildPatternSelected() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizeWidth.s4),
      child: GestureDetector(
        onTap: isColorOpen,
        child: Container(
          margin: EdgeInsets.all(AppSizeHeight.s1),
          decoration: BoxDecoration(
            border: Border.all(
              color: ColorManager.gold,
              width: AppSizeHeight.s1,
            ),
            borderRadius: BorderRadius.circular(AppSizeWidth.s4),
          ),
          height: AppSizeHeight.s26,
          width: AppSizeWidth.s20,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizeWidth.s3_5),
            child: Image.asset(selectedImage, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _buildStampSelected() {
    final currentStamp =
        selectedStampAsset ?? (stamps.isNotEmpty ? stamps[0] : null);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizeWidth.s4),
      child: GestureDetector(
        onTap: isColorOpen,
        child: Container(
          margin: EdgeInsets.all(AppSizeHeight.s1),
          decoration: BoxDecoration(
            border: Border.all(
              color: ColorManager.gold,
              width: AppSizeHeight.s1,
            ),
            borderRadius: BorderRadius.circular(AppSizeWidth.s4),
            color: ColorManager.white,
          ),
          height: AppSizeHeight.s26,
          width: AppSizeWidth.s20,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizeWidth.s3_5),
            child: currentStamp != null
                ? SvgPicture.asset(currentStamp, fit: BoxFit.scaleDown)
                : Container(
                    color: ColorManager.white,
                    child: Center(
                      child: Text(
                        'Stamp',
                        style: TextStyle(
                          fontSize: 10,
                          color: ColorManager.darkPrimary,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolSelected(BrushMode brushMode) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppSizeWidth.s4),
      ),
      child: Container(
        margin: EdgeInsets.all(AppSizeHeight.s1),
        decoration: BoxDecoration(
          color: ColorManager.white,
          border: Border.all(
            color: brushMode != BrushMode.eraser
                ? ColorManager.gold
                : ColorManager.grey,
            width: AppSizeHeight.s1,
          ),
          borderRadius: BorderRadius.all(Radius.circular(AppSizeWidth.s4)),
        ),
        height: AppSizeHeight.s26,
        width: AppSizeWidth.s20,
        child: GestureDetector(
          onTap: isToolOpen,
          child: _buildSelectedToolIcon(),
        ),
      ),
    );
  }

  Widget _buildSelectedToolIcon() {
    if (selectedTool == null) {
      return Container();
    }

    switch (selectedTool!.type) {
      case ToolType.fill:
        return Center(
          child: Stack(
            children: [
              SvgPicture.asset(ImageAssets.fill1, fit: BoxFit.cover),
              SvgPicture.asset(
                ImageAssets.fill2,
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
              ),
            ],
          ),
        );
      case ToolType.glitter:
        return Center(
          child: Stack(
            children: [
              SvgPicture.asset(ImageAssets.glitter1, fit: BoxFit.fill),
              SvgPicture.asset(ImageAssets.glitter2, fit: BoxFit.fill),
              SvgPicture.asset(
                ImageAssets.glitter3,
                fit: BoxFit.fill,
                colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
              ),
            ],
          ),
        );
      case ToolType.freehand:
        return Center(
          child: Stack(
            children: [
              SvgPicture.asset(ImageAssets.freeHand1, fit: BoxFit.cover),
              SvgPicture.asset(
                ImageAssets.freeHand2,
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
              ),
            ],
          ),
        );
      case ToolType.pencil:
        return Center(
          child: Stack(
            children: [
              SvgPicture.asset(
                ImageAssets.pencil1,
                fit: BoxFit.fill,
                colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
              ),
              SvgPicture.asset(ImageAssets.pencil2, fit: BoxFit.fill),
            ],
          ),
        );

      case ToolType.wallpaper:
        return Center(
          child: Stack(
            children: [
              SvgPicture.asset(ImageAssets.wallpaper, fit: BoxFit.fitWidth),
            ],
          ),
        );

      case ToolType.stamp:
        return SvgPicture.asset(ImageAssets.stamp, fit: BoxFit.scaleDown);

      case ToolType.magic:
        return Center(
          child: Image.asset(ImageAssets.magic, fit: BoxFit.scaleDown),
        );
    }
  }
}
