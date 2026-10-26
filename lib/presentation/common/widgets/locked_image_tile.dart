import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/common/localization/app_language.dart';

import '../../../data/services/rewarded_ad_service.dart';
import 'package:fun_painting/presentation/common/widgets/ad_banner_strip.dart';
import 'package:fun_painting/presentation/common/resources/values_manager.dart';
import 'package:fun_painting/presentation/common/resources/color_manager.dart';

/// A gallery tile for a single coloring image. If [isUnlocked] is false,
/// shows a dimmed thumbnail with a lock badge; tapping triggers the
/// rewarded-ad unlock flow via [RewardedAdService].
class LockedImageTile extends StatefulWidget {
  const LockedImageTile({
    super.key,
    required this.imageId,
    required this.thumbnail,
    required this.isUnlocked,
    required this.onTapUnlocked,
    required this.onImageUnlocked,
  });

  final String imageId;
  final Widget thumbnail;
  final bool isUnlocked;

  /// Called when an already-unlocked (or free) image is tapped.
  final VoidCallback onTapUnlocked;

  /// Called after a locked image is successfully unlocked via ad.
  final VoidCallback onImageUnlocked;

  @override
  State<LockedImageTile> createState() => _LockedImageTileState();
}

class _LockedImageTileState extends State<LockedImageTile> {
  bool _isShowingAd = false;

  Future<void> _handleTap() async {
    if (widget.isUnlocked) {
      widget.onTapUnlocked();
      return;
    }

    setState(() => _isShowingAd = true);

    final result = await RewardedAdService.instance.showToUnlock(
      imageId: widget.imageId,
      onUnlocked: widget.onImageUnlocked,
    );

    if (mounted) setState(() => _isShowingAd = false);

    if (result != UnlockResult.unlocked && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(result == UnlockResult.queued ? 'ad_queued' : 'ad_not_finished'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isShowingAd ? null : _handleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: widget.isUnlocked
                ? const ColorFilter.mode(
                    ColorManager.transparent,
                    BlendMode.multiply,
                  )
                : const ColorFilter.matrix(<double>[
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]), // grayscale for locked thumbnails
            child: widget.thumbnail,
          ),
          if (!widget.isUnlocked)
            Positioned.fill(
              child: Container(
                color: ColorManager.materialBlack26,
                alignment: Alignment.center,
                child: _isShowingAd
                    ? const CircularProgressIndicator(color: ColorManager.white)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock,
                            color: ColorManager.white,
                            size: AppPx.p28,
                          ),
                          SizedBox(height: AppPx.p4),
                          Text(
                            tr('watch_ad_to_unlock'),
                            // 'Watch an ad to unlock',
                            style: TextStyle(
                              color: ColorManager.white,
                              fontSize: AppPx.p12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          if (!widget.isUnlocked)
            Positioned(top: AppPx.p6, left: AppPx.p6, child: const AdBadge()),
        ],
      ),
    );
  }
}
