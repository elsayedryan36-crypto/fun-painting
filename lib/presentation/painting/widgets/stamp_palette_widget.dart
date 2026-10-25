import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/common/localization/app_language.dart';
import 'package:flutter_svg/svg.dart';

import '../../common/resources/color_manager.dart';
import '../../common/resources/values_manager.dart';

/// Grid of selectable stamp images plus a slider to control stamp size.
class StampPaletteWidget extends StatelessWidget {
  final String selectedImage;
  final ValueChanged<String> onImageSelected;
  final VoidCallback isImageChanged;
  final double stampSize;
  final ValueChanged<double> onStampSizeChanged;
  final String? selectedStampAsset;
  final List<String> stamps;

  const StampPaletteWidget({
    super.key,
    required this.selectedImage,
    required this.onImageSelected,
    required this.isImageChanged,
    required this.stampSize,
    required this.onStampSizeChanged,
    this.selectedStampAsset,
    required this.stamps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppPx.p8_0),
          child: Column(
            children: [
              Text(
                tr('stamp_size', {'size': '${stampSize.round()}'}),
                style: TextStyle(
                  color: ColorManager.black,
                  fontSize: AppPx.p15,
                ),
              ),
              Slider(
                value: stampSize,
                min: 20.0,
                max: 150.0,
                divisions: 13,
                label: stampSize.round().toString(),
                onChanged: onStampSizeChanged,
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(AppPx.p8),
            itemCount: stamps.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final imagePath = stamps[index];
              return GestureDetector(
                onTap: () {
                  onImageSelected(imagePath);
                },
                child: Container(
                  height: AppSizeHeight.s18,
                  width: AppSizeWidth.s20,
                  padding: EdgeInsets.all(AppPx.p3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedImage == imagePath
                          ? ColorManager.gold
                          : ColorManager.transparent,
                      width: AppPx.p2,
                    ),
                  ),
                  child: ClipOval(
                    child: SvgPicture.asset(
                      imagePath,
                      fit: BoxFit.scaleDown,
                      height: AppSizeHeight.s18,
                      width: AppSizeWidth.s20,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
