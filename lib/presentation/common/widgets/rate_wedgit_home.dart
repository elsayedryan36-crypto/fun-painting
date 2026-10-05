import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/common/resources/color_manager.dart';
import 'package:fun_painting/presentation/common/resources/values_manager.dart';
import 'package:in_app_review/in_app_review.dart';

import '../resources/font_manager.dart';

class RateAppWidgetHome extends StatefulWidget {
  const RateAppWidgetHome({super.key});

  @override
  State<RateAppWidgetHome> createState() => _RateAppWidgetState();
}

class _RateAppWidgetState extends State<RateAppWidgetHome>
    with TickerProviderStateMixin {
  final InAppReview _inAppReview = InAppReview.instance;

  static const int _starCount = 5;

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(_starCount, (index) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      );

      // Stagger the start of each star's loop
      Future.delayed(Duration(milliseconds: index * 120), () {
        if (mounted) controller.repeat(reverse: true);
      });

      return controller;
    });

    _scaleAnimations = _controllers
        .map(
          (c) => Tween<double>(
            begin: 0.9,
            end: 1.2,
          ).chain(CurveTween(curve: Curves.easeInOut)).animate(c),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleTap() async {
    debugPrint('Rate widget tapped — opening Play Store listing');
    try {
      await _inAppReview.openStoreListing();
    } catch (e) {
      debugPrint('openStoreListing error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorManager.lightPrimary,
      child: Row(
        children: [
          Text(
            'Enjoying The App?',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: ColorManager.darkBluPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(width: AppSizeWidth.s11),
          GestureDetector(
            onTap: _handleTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: AppSizeHeight.s5),
                Text(
                  'Tap to rate us on Google Play',
                  style: TextStyle(
                    fontSize: FontSize.s16,
                    color: ColorManager.gold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_starCount, (index) {
                    return AnimatedBuilder(
                      animation: _scaleAnimations[index],
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimations[index].value,
                          child: child,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFF176),
                              Color(0xFFFFC107),
                              Color(0xFFFF8F00),
                            ],
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.star_rounded,
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
