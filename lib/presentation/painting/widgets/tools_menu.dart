import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/common/localization/app_language.dart';
import 'package:fun_painting/presentation/common/resources/color_manager.dart';
import 'package:fun_painting/presentation/common/resources/values_manager.dart';

/// The card behind the tune button on the painting page (approved mockup):
/// Sound levels and How to paint, instead of two buttons in the corner.
class ToolsMenuCard extends StatelessWidget {
  final double width;
  final double rowHeight;
  final VoidCallback onSound;
  final VoidCallback onHelp;

  const ToolsMenuCard({
    super.key,
    required this.width,
    required this.rowHeight,
    required this.onSound,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorManager.white,
      elevation: AppPx.p6,
      borderRadius: BorderRadius.circular(AppPx.p18),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: EdgeInsets.all(AppPx.p8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolsMenuRow(
                height: rowHeight,
                icon: Icons.volume_up_rounded,
                chipColor: ColorManager.hexFFBBDEFB,
                label: tr('sound_levels'),
                onTap: onSound,
              ),
              SizedBox(height: AppPx.p4),
              _ToolsMenuRow(
                height: rowHeight,
                icon: Icons.help_outline_rounded,
                chipColor: ColorManager.hexFFE1D5FF,
                label: tr('how_to_paint'),
                onTap: onHelp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolsMenuRow extends StatelessWidget {
  final double height;
  final IconData icon;
  final Color chipColor;
  final String label;
  final VoidCallback onTap;

  const _ToolsMenuRow({
    required this.height,
    required this.icon,
    required this.chipColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppPx.p12),
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppPx.p12),
          child: Row(
            children: [
              Container(
                width: height * 0.7,
                height: height * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: chipColor,
                ),
                child: Icon(
                  icon,
                  color: ColorManager.darkPrimary,
                  size: height * 0.38,
                ),
              ),
              SizedBox(width: AppPx.p12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppPx.p18,
                    fontWeight: FontWeight.w700,
                    color: ColorManager.darkPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
