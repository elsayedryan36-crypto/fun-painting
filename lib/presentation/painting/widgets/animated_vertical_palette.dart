import 'package:flutter/material.dart';

/// Animates [child] in/out with a horizontal slide + fade, driven by
/// [animation]. Used to show/hide the right-hand tool palette.
class AnimatedVerticalPalette extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const AnimatedVerticalPalette({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset((1 - animation.value) * 100, 0),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: child,
    );
  }
}
