import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/galary/widgets/gallery_svg.dart';
import 'package:fun_painting/presentation/galary/widgets/kid_gallery_widgets.dart';

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

  /// NEW (sticker book): the world colour for the ribbon, and the
  /// tiny "sticker on the fridge" tilt.
  final Color ribbonColor;
  final double tilt;

  const GalleryCard({
    super.key,
    required this.item,
    required this.repository,
    required this.refreshId,
    required this.isFree,
    required this.onReturn,
    this.ribbonColor = const Color(0xFF344D67),
    this.tilt = 0,
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
    // NEW (sticker book): polaroid frame, coloured ribbon, the picture
    // keeps its colours when locked (a present, never grey), and a gold
    // star when the child already coloured it.
    final showLocked = _checkedUnlockState && !_isUnlocked;
    final hasStar = widget.repository.box.containsKey(_imageId);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _isLoadingAd ? null : _handleTap,
          child: Transform.rotate(
            angle: widget.tilt,
            child: Container(
              decoration: BoxDecoration(
                color: ColorManager.white,
                borderRadius: BorderRadius.circular(
                  math.max(12, AppSizeHeight.s3),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33142846),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              padding: EdgeInsets.all(math.max(5, AppSizeHeight.s1_5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        math.max(10, AppSizeHeight.s2),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: ColorManager.white,
                            child: GallerySvg(
                              key: ValueKey(
                                '${widget.item.imagePath}_${widget.refreshId}',
                              ),
                              assetName: widget.item.imagePath,
                              imageId: widget.item.imagePath,
                              repository: widget.repository,
                              fillColor: ColorManager.white,
                              strokeWidth: 5,
                            ),
                          ),
                          if (showLocked) GiftOverlay(isLoading: _isLoadingAd),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: math.max(4, AppSizeHeight.s1)),
                  Container(
                    height: math.max(14, AppSizeHeight.s4),
                    decoration: BoxDecoration(
                      color: widget.ribbonColor,
                      borderRadius: BorderRadius.circular(
                        math.max(8, AppSizeHeight.s2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasStar) const Positioned(top: -6, right: -6, child: StarBadge()),
      ],
    );

    // OLD (locked = greyscale + grey veil + tiny corner gift badge):
    // return GestureDetector(
    //   onTap: _isLoadingAd ? null : _handleTap,
    //   child: Card(
    //     shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(AppSizeHeight.s5_6),
    //     ),
    //     elevation: 5,
    //     child: ClipRRect(
    //       borderRadius: BorderRadius.circular(AppSizeHeight.s5_6),
    //       child: Stack(
    //         fit: StackFit.expand,
    //         children: [
    //           ColorFiltered(
    //             colorFilter: showLocked
    //                 ? const ColorFilter.matrix(<double>[ greyscale matrix ])
    //                 : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
    //             child: GallerySvg(...),
    //           ),
    //           if (showLocked)
    //             Positioned.fill(child: Container(color: Colors.grey.withOpacity(0.40))),
    //           if (showLocked)
    //             Positioned(top: 0, right: 0, child: _LockBadge(isLoading: _isLoadingAd)),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }
}
