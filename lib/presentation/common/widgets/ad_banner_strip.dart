import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/common/localization/app_language.dart';
import 'package:fun_painting/presentation/common/resources/color_manager.dart';
import 'package:fun_painting/presentation/common/resources/values_manager.dart';
import 'package:fun_painting/presentation/common/widgets/banner_ad_widget.dart';

/// A banner ad on a plain grey strip with an "Advertisement" label.
/// It must not look like the game's own artwork (Families ad policy).
class AdBannerStrip extends StatelessWidget {
  const AdBannerStrip({super.key, required this.adUnitId});

  final String adUnitId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ColorManager.hexFFF2F2F2,
      padding: EdgeInsets.fromLTRB(AppPx.p8, AppPx.p4, AppPx.p8, AppPx.p6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('advertisement'),
            style: TextStyle(
              color: ColorManager.hexFF555555,
              fontSize: AppPx.p10,
            ),
          ),
          SizedBox(height: AppPx.p3),
          DecoratedBox(
            decoration: BoxDecoration(
              color: ColorManager.white,
              borderRadius: BorderRadius.circular(AppPx.p6),
              border: Border.all(color: ColorManager.hexFFCFCFCF),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppPx.p6),
              child: BannerAdWidget(adUnitId: adUnitId),
            ),
          ),
        ],
      ),
    );
  }
}

/// The small "AD" tag on locked pictures and gift boxes.
class AdBadge extends StatelessWidget {
  const AdBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppPx.p6, vertical: AppPx.p2),
      decoration: BoxDecoration(
        color: ColorManager.white,
        borderRadius: BorderRadius.circular(AppPx.p5),
        border: Border.all(color: ColorManager.hexFF888888),
      ),
      child: Text(
        tr('ad_badge'),
        style: TextStyle(
          color: ColorManager.hexFF333333,
          fontSize: AppPx.p10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
