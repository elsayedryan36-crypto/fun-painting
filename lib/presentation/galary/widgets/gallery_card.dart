import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/galary/widgets/gallery_svg.dart';
import 'package:lottie/lottie.dart';

import '../../../data/local data/painting_repository.dart';
import '../../../data/services/rewarded_ad_service.dart';
import '../../../data/services/unlocked_images_store.dart';
import '../../common/resources/color_manager.dart';
import '../../common/resources/routs_manager.dart';
import '../../common/resources/values_manager.dart';
import '../../common/local_data/Class.dart';

class GalleryCard extends StatefulWidget {
  final Collections item;
  final PaintingRepository repository;
  final int refreshId;
  final bool isFree;
  final VoidCallback onReturn;

  const GalleryCard({
    super.key,
    required this.item,
    required this.repository,
    required this.refreshId,
    required this.isFree,
    required this.onReturn,
  });

  @override
  State<GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<GalleryCard> {
  bool _isUnlocked = false;
  bool _isLoadingAd = false;
  bool _checkedUnlockState = false;

  String get _imageId => widget.item.imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.isFree) {
      _isUnlocked = true;
      _checkedUnlockState = true;
    } else {
      _loadUnlockState();
      RewardedAdService.instance.preload();
    }
  }

  Future<void> _loadUnlockState() async {
    final unlocked = await UnlockedImagesStore.instance.isUnlocked(_imageId);
    if (!mounted) return;
    setState(() {
      _isUnlocked = unlocked;
      _checkedUnlockState = true;
    });
  }

  Future<void> _openPainting() async {
    await Navigator.pushNamed(
      context,
      Routes.painting,
      arguments: widget.item.imagePath,
    );
    widget.onReturn();
  }

  Future<void> _handleTap() async {
    if (_isUnlocked) {
      _openPainting();
      return;
    }

    setState(() => _isLoadingAd = true);

    final success = await RewardedAdService.instance.showToUnlock(
      imageId: _imageId,
      onUnlocked: () {
        if (mounted) setState(() => _isUnlocked = true);
      },
    );

    if (!mounted) return;
    setState(() => _isLoadingAd = false);

    if (success) {
      _openPainting();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad not ready yet — try again in a moment.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showLocked = _checkedUnlockState && !_isUnlocked;

    return GestureDetector(
      onTap: _isLoadingAd ? null : _handleTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizeHeight.s5_6),
        ),
        elevation: 5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizeHeight.s5_6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: showLocked
                    ? const ColorFilter.matrix(<double>[
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
                      ])
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
                child: GallerySvg(
                  key: ValueKey("${widget.item.imagePath}_${widget.refreshId}"),
                  assetName: widget.item.imagePath,
                  imageId: widget.item.imagePath,
                  repository: widget.repository,
                  fillColor: ColorManager.white,
                  strokeWidth: 5,
                ),
              ),

              if (showLocked)
                Positioned.fill(
                  child: Container(color: Colors.grey.withOpacity(0.40)),
                ),

              if (showLocked)
                Positioned(
                  top: 0,
                  right: 0,
                  child: _LockBadge(isLoading: _isLoadingAd),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small badge shown in the top-right corner of locked cards.
/// Plays a continuously looping gift-box animation so it reads as
/// "something's waiting here" even before the user taps.
class _LockBadge extends StatefulWidget {
  const _LockBadge({required this.isLoading});

  final bool isLoading;

  @override
  State<_LockBadge> createState() => _LockBadgeState();
}

class _LockBadgeState extends State<_LockBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: widget.isLoading
          ? SizedBox(
              width: AppSizeWidth.s20,
              height: AppSizeHeight.s20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : SizedBox(
              // Explicit size is required — with no width/height, Lottie
              // sizes to the raw composition dimensions, which can render
              // far too small/large or effectively invisible here.
              width: AppSizeWidth.s30,
              height: AppSizeHeight.s30,
              child: Lottie.asset(
                'assets/json/giftBox.json',
                controller: _controller,
                onLoaded: (composition) {
                  _controller
                    ..duration = composition.duration
                    // Passing repeat:true to Lottie.asset does nothing
                    // once a controller is supplied — the controller
                    // itself is what must be told to loop.
                    ..repeat();
                },
              ),
            ),
    );
  }
}
