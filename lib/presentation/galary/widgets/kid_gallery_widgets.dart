import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../common/resources/color_manager.dart';
import '../../common/resources/values_manager.dart';

// ============================================================
// Sticker-book pieces for the category (gallery) screen.
// Calm world background + polaroid cards + present-not-grey
// locking + gold stars for finished pictures.
// ============================================================

/// The top banner: world emoji + name + count + a big home sticker.
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

/// Locked = a wrapped present with a promise, never grey.
class GiftOverlay extends StatelessWidget {
  final bool isLoading;

  const GiftOverlay({super.key, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x8CFFFFFF),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(strokeWidth: 3)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: math.max(56, AppSizeWidth.s12),
                    height: math.max(56, AppSizeHeight.s14),
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
                      color: ColorManager.gold,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'watch to open!',
                      style: TextStyle(
                        color: const Color(0xFF7A4B00),
                        fontWeight: FontWeight.w900,
                        fontSize: math.max(11, AppSizeHeight.s3),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Gold star for pictures the child already coloured.
class StarBadge extends StatelessWidget {
  const StarBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: math.max(30, AppSizeWidth.s6),
      height: math.max(30, AppSizeHeight.s8),
      decoration: BoxDecoration(
        color: ColorManager.gold,
        shape: BoxShape.circle,
        border: Border.all(color: ColorManager.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 6,
            offset: Offset(0, 3),
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
  }
}
