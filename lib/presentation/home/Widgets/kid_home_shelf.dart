import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/local_data/Class.dart';
import '../../common/resources/color_manager.dart';
import '../../common/resources/values_manager.dart';

// ============================================================
// The "pick your world" storybook shelf (fantastic home).
//
// The home screen used to show ONE world at a time (12 swipes to
// reach Numbers, no names anywhere). Now the worlds sit on a shelf
// of sticker cards: looping video thumbnail + name plate with an
// emoji, and the whiteboard "Free Draw" card is the hero at slot 1.
//
// Sizing follows the app's own percent-of-screen language
// (AppSizeHeight / AppSizeWidth), clamped to real fingertip targets.
// ============================================================

/// One world on the shelf: name, emoji and ribbon colour.
class WorldMeta {
  final String name;
  final String emoji;
  final Color color;

  /// NEW (card art round): generated sticker art for the card.
  /// null = this world keeps the old looping video for now.
  final String? art;

  /// NEW (Lottie round): a real Lottie scene for the card — the clean
  /// background stays fixed while vector animals swim / fly / bounce
  /// on top of it. null = not generated yet.
  final String? lottie;

  const WorldMeta(this.name, this.emoji, this.color, [this.art, this.lottie]);
}

/// In the SAME order buildGalleryItems() builds the worlds.
/// The whiteboard "Free Draw" card is the LAST item there; on the
/// shelf it becomes the FIRST one, so it has no entry here.
/// The Free Draw hero card art.
const String kFreeDrawArt = 'assets/images/cards/free_bg.jpg';

const List<WorldMeta> kWorldMeta = [
  // Calm category backgrounds (4:3, matching the card). The Lottie
  // field stays null until a downloaded Lottie is dropped into
  // assets/json/cards/<world>.json — see LOTTIE-SOURCES.md.
  WorldMeta('Zoo', '🦁', Color(0xFF3D9142), 'assets/images/cards/zoo_bg.jpg'),
  WorldMeta('Sea', '🌊', Color(0xFF1976D2), 'assets/images/cards/sea_bg.jpg'),
  WorldMeta(
    'Dragons',
    '🐉',
    Color(0xFF7B1FA2),
    'assets/images/cards/dragons_bg.jpg',
  ),
  WorldMeta(
    'Fairy',
    '🧚',
    Color(0xFFE91E63),
    'assets/images/cards/fairy_bg.jpg',
  ),
  WorldMeta(
    'Space',
    '🚀',
    Color(0xFF303F9F),
    'assets/images/cards/space_bg.jpg',
  ),
  WorldMeta('Cars', '🚗', Color(0xFFF57C00), 'assets/images/cards/cars_bg.jpg'),
  WorldMeta(
    'Circus',
    '🎪',
    Color(0xFFE53935),
    'assets/images/cards/circus_bg.jpg',
  ),
  WorldMeta('Food', '🍓', Color(0xFFEF6C00), 'assets/images/cards/food_bg.jpg'),
  WorldMeta(
    'Flowers',
    '🌸',
    Color(0xFFEC407A),
    'assets/images/cards/flowers_bg.jpg',
  ),
  WorldMeta(
    'Letters',
    '🔤',
    Color(0xFF00897B),
    'assets/images/cards/letters_bg.jpg',
  ),
  WorldMeta(
    'Numbers',
    '🔢',
    Color(0xFF5D4037),
    'assets/images/cards/numbers_bg.jpg',
  ),
  // OLD (kept commented per the release rule) — no backgrounds yet:
  // // backgrounds land in the next round; until then a soft tint shows:
  // WorldMeta('Letters', '🔤', Color(0xFF00897B)),
  // WorldMeta('Numbers', '🔢', Color(0xFF5D4037)),
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

/// A sticker card: white frame, looping-video thumb, name plate.
/// The hero card (Free Draw) gets a sunrise gradient and a big label.
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

    return GestureDetector(
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
                      if (slot.isHero)
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x14FFFFFF), Color(0xB8FF9800)],
                            ),
                          ),
                        ),
                      if (slot.isHero)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '🖍️',
                                style: TextStyle(
                                  fontSize: math.max(30, AppSizeHeight.s9),
                                ),
                              ),
                              Text(
                                'FREE DRAW!',
                                style: TextStyle(
                                  fontSize: math.max(16, AppSizeHeight.s4),
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF7A4B00),
                                  shadows: const [
                                    Shadow(color: Colors.white, blurRadius: 6),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
    );
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

/// The card picture that *breathes*: a slow Ken-Burns zoom, a floating
/// emoji bubble and a soft gradient. Animated like a video, but at
/// ~200 KB of art instead of ~5 MB of MP4 per world.
///
/// If a world has no art yet — or the art cannot be loaded on this
/// device — the old looping video shows instead, so a card can never
/// appear broken.
class AnimatedWorldThumb extends StatefulWidget {
  final String? artPath;
  final String emoji;
  final Widget fallback;

  /// Test override: inject the picture instead of loading an asset.
  final Widget? art;

  const AnimatedWorldThumb({
    super.key,
    required this.artPath,
    required this.emoji,
    required this.fallback,
    this.art,
  });

  @override
  State<AnimatedWorldThumb> createState() => _AnimatedWorldThumbState();
}

class _AnimatedWorldThumbState extends State<AnimatedWorldThumb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _broken = false;
  bool _checked = false;

  bool get _useArt => widget.artPath != null && !_broken;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final path = widget.artPath;
    if (widget.art == null && path != null && !_checked) {
      _checked = true;
      // If the art file is not on this device yet, show the old
      // video instead of a grey error box.
      precacheImage(Image.asset(path).image, context).catchError((Object e) {
        if (mounted) setState(() => _broken = true);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_useArt) return widget.fallback;

    final art =
        widget.art ??
        Image.asset(
          widget.artPath!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // the picture breathes: slow zoom + drift
          AnimatedBuilder(
            animation: _controller,
            child: art,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_controller.value);
              return Transform.scale(
                scale: 1.05 + 0.07 * t,
                alignment: Alignment(0, -0.2 + 0.4 * (1 - t)),
                child: child,
              );
            },
          ),
          // a floating emoji bubble
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              return Positioned(
                right: 6 + 4 * math.sin(t * math.pi),
                top: 8 + 10 * (1 - t),
                child: child!,
              );
            },
            child: Container(
              width: math.max(26, AppSizeHeight.s7),
              height: math.max(26, AppSizeHeight.s7),
              decoration: const BoxDecoration(
                color: Color(0xB3FFFFFF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33142846),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.emoji,
                  style: TextStyle(fontSize: math.max(13, AppSizeHeight.s4)),
                ),
              ),
            ),
          ),
          // soft floor so the name plate always reads
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x33000000)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
