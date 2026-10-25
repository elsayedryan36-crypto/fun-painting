import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/common/localization/app_language.dart';

import '../../common/local_data/Class.dart';
import '../../common/resources/color_manager.dart';
import '../../common/resources/values_manager.dart';
import 'jungle.dart' show FrameRange, LottieLayer;
import 'package:fun_painting/presentation/common/resources/assets_manager.dart';

// ============================================================
// The "pick your world" storybook shelf.
//
// Worlds sit on a shelf of sticker cards: an animated picture, plus a name
// plate with an emoji. The whiteboard "Free Draw" card is the hero at slot 1.
//
// Every card has its own Lottie file and plays a slice of it: a start frame
// and an end frame (FrameRange). Make a card still with FrameRange.still(n).
// ============================================================

/// One world on the shelf: name, emoji, ribbon colour and its animation.
class WorldMeta {
  final String name;
  final String emoji;
  final Color color;

  /// Path of this card's Lottie (.json) file. null = no animation.
  final String? lottie;

  /// Start / end frame of that file for this card.
  /// null = the card plays the whole file.
  final FrameRange? frames;

  /// Extra Lotties stacked on top of the main one, in order (last = top).
  final List<LottieLayer> layers;

  const WorldMeta(
    this.name,
    this.emoji,
    this.color, {
    this.lottie,
    this.frames,
    this.layers = const [],
  });
}

/// The Free Draw hero card: its Lottie file and frames.
/// Put the real file name here (the file itself goes in assets/images/cards/).
const String kFreeDrawLottie = CardAssets.freeHand;
const FrameRange kFreeDrawFrames = FrameRange(0, 60);

/// The hero card used to draw an orange gradient and a big "FREE DRAW!" over
/// its picture. The name plate already says it, so this is off by default.
const bool kShowHeroOverlay = false;

/// In the SAME order buildGalleryItems() builds the worlds.
/// The whiteboard "Free Draw" card is the LAST item there; on the shelf it
/// becomes the FIRST one, so it has no entry here.
///
/// Per card: `lottie` is its file, `frames` is FrameRange(start, end).
/// Examples:
///   frames: FrameRange(13, 72)        plays frames 13 to 72, looping
///   frames: FrameRange.still(40)      a still card showing frame 40
///   (no frames line)                  plays the whole file
const List<WorldMeta> kWorldMeta = [
  WorldMeta(
    'Zoo',
    '🦁',
    ColorManager.hexFF3D9142,
    lottie: CardAssets.jungle,
    frames: FrameRange(13, 72),
  ),
  WorldMeta(
    'Sea',
    '🌊',
    ColorManager.hexFF1976D2,
    lottie: CardAssets.sea,
    frames: FrameRange(0, 60),
  ),
  WorldMeta(
    'Dragons',
    '🐉',
    ColorManager.hexFF7B1FA2,
    lottie: CardAssets.dragons,
    frames: FrameRange(20, 130),

    // A second Lottie stacked on top of the dragon. Put its file in
    // assets/images/cards/ and use its real name and frames.
  ),
  WorldMeta(
    'Fairy',
    '🧚',
    ColorManager.hexFFE91E63,
    lottie: CardAssets.fairy,
    frames: FrameRange(0, 30),
  ),
  WorldMeta(
    'Space',
    '🚀',
    ColorManager.hexFF303F9F,
    lottie: CardAssets.space,
    frames: FrameRange(0, 70),
  ),
  WorldMeta(
    'Cars',
    '🚗',
    ColorManager.hexFFF57C00,
    lottie: CardAssets.cars,
    frames: FrameRange(0, 19),
  ),
  WorldMeta(
    'Circus',
    '🎪',
    ColorManager.hexFFE53935,
    lottie: CardAssets.circus,
    frames: FrameRange(0, 95),
  ),
  WorldMeta(
    'Food',
    '🍓',
    ColorManager.hexFFEF6C00,
    lottie: CardAssets.food,
    frames: FrameRange(0, 29),
  ),
  WorldMeta(
    'Flowers',
    '🌸',
    ColorManager.hexFFEC407A,
    lottie: CardAssets.flowers,
    frames: FrameRange(0, 133),
  ),
  WorldMeta(
    'Letters',
    '🔤',
    ColorManager.hexFF00897B,
    lottie: CardAssets.letters,
    frames: FrameRange(0, 61),
  ),
  WorldMeta(
    'Numbers',
    '🔢',
    ColorManager.hexFF5D4037,
    lottie: CardAssets.numbers,
    frames: FrameRange(0, 72),
  ),
];

/// One slot on the shelf. [meta] == null marks the Free Draw hero.
class ShelfSlot {
  final Collections item;
  final WorldMeta? meta;
  final double tilt; // radians; a tiny "sticker on the fridge" tilt

  const ShelfSlot(this.item, this.meta, this.tilt);

  bool get isHero => meta == null;
}

/// Shelf order: Free Draw first (it is the LAST item of
/// buildGalleryItems), then the worlds in their usual order.
/// Every world keeps the onTap it was born with, so re-ordering the
/// display never breaks the routes.
List<ShelfSlot> buildShelfSlots(List<Collections> items) {
  final slots = <ShelfSlot>[];
  if (items.isEmpty) return slots;

  // The hero: the whiteboard card.
  slots.add(ShelfSlot(items.last, null, 0.02));

  for (var i = 0; i < items.length - 1 && i < kWorldMeta.length; i++) {
    final tilt = (i.isEven ? -1 : 1) * 0.018;
    slots.add(ShelfSlot(items[i], kWorldMeta[i], tilt));
  }
  return slots;
}

/// Flat slot list -> pages of [perPage] cards each.
List<List<ShelfSlot>> chunkShelf(List<ShelfSlot> slots, int perPage) {
  final pages = <List<ShelfSlot>>[];
  for (var i = 0; i < slots.length; i += perPage) {
    pages.add(slots.sublist(i, math.min(i + perPage, slots.length)));
  }
  return pages;
}

/// A sticker card: white frame, picture, name plate.
class WorldCard extends StatelessWidget {
  final ShelfSlot slot;
  final Widget thumb;
  final VoidCallback onTap;

  /// A child's fingertip: nothing on the card may shrink below this.
  static const double minTap = 48;

  const WorldCard({
    super.key,
    required this.slot,
    required this.thumb,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = math.max(AppPx.p14_0, AppSizeHeight.s4);

    return Semantics(
      button: true,
      label: slot.isHero ? tr('free_draw') : trName(slot.meta!.name),
      // label: slot.isHero ? 'Free draw' : slot.meta!.name,
      child: GestureDetector(
        onTap: onTap,
        child: Transform.rotate(
          angle: slot.tilt,
          child: Container(
            decoration: BoxDecoration(
              color: ColorManager.white,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: ColorManager.hex40142846,
                  blurRadius: AppPx.p12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            padding: EdgeInsets.all(math.max(AppPx.p5_0, AppSizeHeight.s1_5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius * 0.7),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        thumb,
                        if (slot.isHero && kShowHeroOverlay) ..._heroOverlay(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: math.max(AppPx.p4_0, AppSizeHeight.s1)),
                _namePlate(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _heroOverlay() {
    return [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ColorManager.hex14FFFFFF, ColorManager.hexB8FF9800],
          ),
        ),
      ),
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🖍️',
              style: TextStyle(fontSize: math.max(AppPx.p30, AppSizeHeight.s9)),
            ),
            Text(
              tr('free_draw_upper'),
              // 'FREE DRAW!',
              style: TextStyle(
                fontSize: math.max(AppPx.p16, AppSizeHeight.s4),
                fontWeight: FontWeight.w900,
                color: ColorManager.hexFF7A4B00,
                shadows: [
                  Shadow(color: ColorManager.white, blurRadius: AppPx.p6),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _namePlate() {
    final meta = slot.meta;
    return Container(
      height: math.max(minTap * 0.6, AppSizeHeight.s7),
      decoration: BoxDecoration(
        gradient: slot.isHero
            ? const LinearGradient(
                colors: [ColorManager.hexFFFFD400, ColorManager.hexFFFF9800],
              )
            : null,
        color: slot.isHero ? null : meta!.color,
        borderRadius: BorderRadius.circular(
          math.max(AppPx.p10_0, AppSizeHeight.s3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            slot.isHero ? '🖍️' : meta!.emoji,
            style: TextStyle(fontSize: math.max(AppPx.p14, AppSizeHeight.s4)),
          ),
          SizedBox(width: AppPx.p6),
          Flexible(
            child: Text(
              slot.isHero ? tr('free_draw_upper') : trName(meta!.name),
              // slot.isHero ? 'FREE DRAW!' : meta!.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ColorManager.white,
                fontWeight: FontWeight.w900,
                fontSize: math.max(AppPx.p13, AppSizeHeight.s4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
