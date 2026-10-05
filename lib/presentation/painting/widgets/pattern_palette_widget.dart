import 'package:flutter/material.dart';

import '../../common/local_data/list.dart';
import '../../common/resources/color_manager.dart';
import '../../common/resources/values_manager.dart';

/// Grid of selectable wallpaper/pattern images used by the wallpaper tool.
class PatternPaletteWidget extends StatelessWidget {
  final String selectedImage;
  final ValueChanged<String> onImageSelected;
  final VoidCallback isImageChanged;

  const PatternPaletteWidget({
    super.key,
    required this.selectedImage,
    required this.onImageSelected,
    required this.isImageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: Pattern.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final imagePath = Pattern[index];

        return GestureDetector(
          onTap: () {
            onImageSelected(imagePath);
          },
          child: Container(
            height: AppSizeHeight.s18,
            width: AppSizeWidth.s20,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selectedImage == imagePath
                    ? ColorManager.gold
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                height: AppSizeHeight.s18,
                width: AppSizeWidth.s20,
              ),
            ),
          ),
        );
      },
    );
  }
}
