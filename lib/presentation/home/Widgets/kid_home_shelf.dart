import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/local_data/Class.dart';
import '../../common/resources/color_manager.dart';
import '../../common/resources/values_manager.dart';
import 'jungle.dart' show FrameRange, LottieLayer;

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
const String kFreeDrawLottie = 'assets/images/cards/free hand.json';
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
    Color(0xFF3D9142),
    lottie: 'assets/images/cards/jungle.json',
    frames: FrameRange(13, 72),
  ),
  WorldMeta(
    'Sea',
    '🌊',
    Color(0xFF1976D2),
    lottie: 'assets/images/cards/sea.json',
    frames: FrameRange(0, 60),
  ),
  WorldMeta(
    'Dragons',
    '🐉',
    Color(0xFF7B1FA2),
    lottie: 'assets/images/cards/dragons.json',
    frames: FrameRange(20, 130),

    // A second Lottie stacked on top of the dragon. Put its file in
    // assets/images/cards/ and use its real name and frames.
  ),
  WorldMeta(
    'Fairy',
    '🧚',
    Color(0xFFE91E63),
    lottie: 'assets/images/cards/fairy.json',
    frames: FrameRange(0, 30),
  ),
  WorldMeta(
    'Space',
    '🚀',
    Color(0xFF303F9F),
    lottie: 'assets/images/cards/space.json',
    frames: FrameRange(0, 70),
  ),
  WorldMeta(
    'Cars',
    '🚗',
    Color(0xFFF57C00),
    lottie: 'assets/images/cards/cars.json',
    frames: FrameRange(0, 19),
  ),
  WorldMeta(
    'Circus',
    '🎪',
    Color(0xFFE53935),
    lottie: 'assets/images/cards/circus.json',
    frames: FrameRange(0, 95),
  ),
  WorldMeta(
    'Food',
    '🍓',
    Color(0xFFEF6C00),
    lottie: 'assets/images/cards/food.json',
    frames: FrameRange(0, 29),
  ),
  WorldMeta(
    'Flowers',
    '🌸',
    Color(0xFFEC407A),
    lottie: 'assets/images/cards/flowers.json',
    frames: FrameRange(0, 133),
  ),
  WorldMeta(
    'Letters',
    '🔤',
    Color(0xFF00897B),
    lottie: 'assets/images/cards/letters.json',
    frames: FrameRange(0, 61),
  ),
  WorldMeta(
    'Numbers',
    '🔢',
    Color(0xFF5D4037),
    lottie: 'assets/images/cards/numbers.json',
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
    final radius = math.max(14.0, AppSizeHeight.s4);

    return Semantics(
      button: true,
      label: slot.isHero ? 'Free draw' : slot.meta!.name,
      child: GestureDetector(
        onTap: onTap,
        child: Transform.rotate(
          angle: slot.tilt,
          child: Container(
            decoration: BoxDecoration(
              color: ColorManager.white,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40142846),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            padding: EdgeInsets.all(math.max(5.0, AppSizeHeight.s1_5)),
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
                SizedBox(height: math.max(4.0, AppSizeHeight.s1)),
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
            colors: [Color(0x14FFFFFF), Color(0xB8FF9800)],
          ),
        ),
      ),
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🖍️',
              style: TextStyle(fontSize: math.max(30, AppSizeHeight.s9)),
            ),
            Text(
              'FREE DRAW!',
              style: TextStyle(
                fontSize: math.max(16, AppSizeHeight.s4),
                fontWeight: FontWeight.w900,
                color: const Color(0xFF7A4B00),
                shadows: const [Shadow(color: Colors.white, blurRadius: 6)],
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
                colors: [Color(0xFFFFD400), Color(0xFFFF9800)],
              )
            : null,
        color: slot.isHero ? null : meta!.color,
        borderRadius: BorderRadius.circular(math.max(10.0, AppSizeHeight.s3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            slot.isHero ? '🖍️' : meta!.emoji,
            style: TextStyle(fontSize: math.max(14, AppSizeHeight.s4)),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              slot.isHero ? 'FREE DRAW!' : meta!.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ColorManager.white,
                fontWeight: FontWeight.w900,
                fontSize: math.max(13, AppSizeHeight.s4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
