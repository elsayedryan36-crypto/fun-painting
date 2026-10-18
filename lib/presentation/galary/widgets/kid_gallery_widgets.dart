import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/common/localization/app_language.dart';
import 'package:lottie/lottie.dart';

import '../../common/resources/color_manager.dart';
import '../../common/resources/values_manager.dart';

// ============================================================
// Sticker-book pieces for the category (gallery) screen.
// Calm world background + polaroid cards + present-not-grey
// locking + gold stars for finished pictures.
// ============================================================

/// The top banner: world emoji + name + count + a big home sticker.
/// NOTE: the "Calm & clean" design replaced this on the gallery page with
/// [GalleryTopBar]; kept alive because the sticker-book tests pin it down.
class WorldBanner extends StatelessWidget {
  final String emoji;
  final String name;
  final int count;
  final Color color;
  final VoidCallback onHome;

  const WorldBanner({
    super.key,
    required this.emoji,
    required this.name,
    required this.count,
    required this.color,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: math.max(52, AppSizeHeight.s12),
      margin: EdgeInsets.symmetric(
        horizontal: AppPaddingWidth.p2,
        vertical: AppPaddingHeight.p1,
      ),
      decoration: BoxDecoration(
        color: ColorManager.white,
        borderRadius: BorderRadius.circular(math.max(14, AppSizeHeight.s4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2B142846),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: AppPaddingWidth.p3),
          Text(
            emoji,
            style: TextStyle(fontSize: math.max(18, AppSizeHeight.s5)),
          ),
          SizedBox(width: AppPaddingWidth.p2),
          Flexible(
            child: Text(
              '$name · $count pictures',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: math.max(14, AppSizeHeight.s4),
              ),
            ),
          ),
          GestureDetector(
            onTap: onHome,
            child: Container(
              width: math.max(44, AppSizeWidth.s8),
              height: math.max(44, AppSizeHeight.s10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '🏠',
                  style: TextStyle(fontSize: math.max(16, AppSizeHeight.s4)),
                ),
              ),
            ),
          ),
          SizedBox(width: AppPaddingWidth.p2),
        ],
      ),
    );
  }
}

/// NEW (Calm & clean): round white home button + a white chip carrying the
/// world emoji, name and a count pill tinted with the world colour.
class GalleryTopBar extends StatelessWidget {
  final String emoji;
  final String name;
  final int count;
  final Color color;
  final VoidCallback onHome;

  /// NEW (round 26): optional widget at the right end (the Sound button).
  final Widget? trailing;

  const GalleryTopBar({
    super.key,
    required this.emoji,
    required this.name,
    required this.count,
    required this.color,
    required this.onHome,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppPaddingWidth.p3,
        vertical: AppPaddingHeight.p1,
      ),
      child: Row(
        children: [
          // home: a round white sticker, always >= 44 dp for small fingers
          GestureDetector(
            onTap: onHome,
            child: Container(
              width: math.max(44, AppSizeHeight.s11),
              height: math.max(44, AppSizeHeight.s11),
              decoration: BoxDecoration(
                color: ColorManager.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x24142846),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '🏠',
                  style: TextStyle(fontSize: math.max(18, AppSizeHeight.s5)),
                ),
              ),
            ),
          ),
          SizedBox(width: AppPaddingWidth.p2),
          // the world chip: emoji + name + count pill
          Expanded(
            child: Container(
              height: math.max(44, AppSizeHeight.s11),
              decoration: BoxDecoration(
                color: ColorManager.white,
                borderRadius: BorderRadius.circular(
                  math.max(14, AppSizeHeight.s4),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F142846),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(fontSize: math.max(17, AppSizeHeight.s5)),
                  ),
                  SizedBox(width: AppPaddingWidth.p2),
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: math.max(14, AppSizeHeight.s4),
                        color: const Color(0xFF2E3A46),
                      ),
                    ),
                  ),
                  SizedBox(width: AppPaddingWidth.p2),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppPaddingWidth.p2,
                      vertical: AppPaddingHeight.p_5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        math.max(9, AppSizeHeight.s2),
                      ),
                    ),
                    child: Text(
                      '$count pictures',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: math.max(11, AppSizeHeight.s3),
                      ),
                    ),
                  ),
                  SizedBox(width: AppPaddingWidth.p2),
                ],
              ),
            ),
          ),
          // NEW (round 26): the Sound button, same height as the home sticker
          if (trailing != null) ...[
            SizedBox(width: AppPaddingWidth.p2),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Locked = a wrapped present with a promise, never grey.
/// NEW (Calm & clean): a soft white veil so the child still sees the
/// picture underneath, and the promise pill wears the world colour.
class GiftOverlay extends StatelessWidget {
  final bool isLoading;

  /// The world colour for the "Watch to open" pill.
  final Color pillColor;

  const GiftOverlay({
    super.key,
    this.isLoading = false,
    this.pillColor = const Color(0xFF344D67),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x9EFFFFFF),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(strokeWidth: 3)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: math.max(52, AppSizeWidth.s11),
                    height: math.max(52, AppSizeHeight.s13),
                    child: Lottie.asset(
                      'assets/json/giftBox.json',
                      repeat: true,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppPaddingWidth.p2,
                      vertical: AppPaddingHeight.p_5,
                    ),
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      tr('watch_to_open'),
                      // 'Watch to open',
                      style: TextStyle(
                        color: ColorManager.white,
                        fontWeight: FontWeight.w900,
                        fontSize: math.max(11, AppSizeHeight.s3),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );

    // OLD (sticker-book gold pill, kept commented per the release rule):
    // decoration: BoxDecoration(
    //   color: ColorManager.gold,
    //   borderRadius: BorderRadius.circular(99),
    // ),
    // child: Text('watch to open!',
    //   style: TextStyle(color: const Color(0xFF7A4B00), ...)),
  }
}

/// Gold star for pictures the child already coloured.
/// NEW (Calm & clean): a small white chip that sits INSIDE the card corner.
class StarBadge extends StatelessWidget {
  const StarBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: math.max(26, AppSizeWidth.s5),
      height: math.max(26, AppSizeHeight.s7),
      decoration: BoxDecoration(
        color: ColorManager.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '⭐',
          style: TextStyle(fontSize: math.max(12, AppSizeHeight.s3)),
        ),
      ),
    );

    // OLD (gold sticker with white rim, kept commented per the rule):
    // decoration: BoxDecoration(
    //   color: ColorManager.gold,
    //   shape: BoxShape.circle,
    //   border: Border.all(color: ColorManager.white, width: 3),
    //   boxShadow: [BoxShadow(color: Color(0x4D000000), blurRadius: 6,
    //     offset: Offset(0, 3))],
    // ),
  }
}
