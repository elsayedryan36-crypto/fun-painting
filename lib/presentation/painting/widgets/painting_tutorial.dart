import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:fun_painting/presentation/common/localization/app_language.dart';
import 'package:fun_painting/presentation/common/resources/color_manager.dart';
import 'package:fun_painting/presentation/common/resources/font_manager.dart';
import 'package:fun_painting/presentation/common/resources/styles_manager.dart';
import 'package:fun_painting/presentation/common/resources/values_manager.dart';

/// One step of the painting tutorial: a control to point at and a short
/// explanation. Titles and bodies are translation keys (see translations.dart).
class TutorialStep {
  const TutorialStep({
    required this.target,
    required this.titleKey,
    required this.bodyKey,
    this.icon,
  });

  /// The widget to spotlight. Must be laid out in the same Stack as the overlay.
  final GlobalKey target;
  final String titleKey;
  final String bodyKey;
  final IconData? icon;
}

/// Full-screen coach-mark tutorial. The screen is dimmed except for a spotlight
/// around the current target. Touches inside the spotlight pass through to the
/// widget underneath, so children can try the gesture (for example pinch to zoom).
class PaintingTutorial extends StatefulWidget {
  const PaintingTutorial({
    super.key,
    required this.steps,
    required this.onFinished,
  });

  final List<TutorialStep> steps;
  final VoidCallback onFinished;

  @override
  State<PaintingTutorial> createState() => _PaintingTutorialState();
}

class _PaintingTutorialState extends State<PaintingTutorial> {
  static const Color _dim = ColorManager.hexB3201A2E;
  static const double _spotPadding = 8;

  int _index = 0;
  Rect? _hole; // spotlight, in this overlay's coordinates

  TutorialStep get _step => widget.steps[_index];
  bool get _isLast => _index == widget.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _measureLater();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Screen size or orientation may have changed: measure the target again.
    _measureLater();
  }

  void _measureLater() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;
    final overlayBox = context.findRenderObject() as RenderBox?;
    final targetBox =
        _step.target.currentContext?.findRenderObject() as RenderBox?;
    Rect? hole;
    if (overlayBox != null &&
        overlayBox.hasSize &&
        targetBox != null &&
        targetBox.hasSize) {
      final topLeft = overlayBox.globalToLocal(
        targetBox.localToGlobal(Offset.zero),
      );
      hole = (topLeft & targetBox.size).inflate(_spotPadding);
    }
    if (hole != _hole) setState(() => _hole = hole);
  }

  void _next() {
    if (_isLast) {
      widget.onFinished();
      return;
    }
    setState(() {
      _index++;
      _hole = null;
    });
    _measureLater();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(children: [..._scrim(size), _card(size)]);
      },
    );
  }

  /// Four blocks around the spotlight absorb taps. The spotlight itself is left
  /// open, so touches there reach the painting underneath.
  List<Widget> _scrim(Size size) {
    final full = Offset.zero & size;
    final hole = _hole;
    if (hole == null) {
      return [_block(full)];
    }
    final h = hole.intersect(full);
    return [
      _block(Rect.fromLTRB(0, 0, size.width, h.top)),
      _block(Rect.fromLTRB(0, h.bottom, size.width, size.height)),
      _block(Rect.fromLTRB(0, h.top, h.left, h.bottom)),
      _block(Rect.fromLTRB(h.right, h.top, size.width, h.bottom)),
    ];
  }

  Widget _block(Rect rect) {
    if (rect.width <= 0 || rect.height <= 0) return const SizedBox.shrink();
    return Positioned.fromRect(
      rect: rect,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: const ColoredBox(color: _dim),
      ),
    );
  }

  Widget _card(Size size) {
    final margin = AppPaddingWidth.p3;
    final cardWidth = math.min(AppSizeWidth.s60, size.width - margin * 2);
    final hole = _hole;

    // Horizontal: centred on the spotlight, kept on screen.
    final centreX = hole?.center.dx ?? size.width / 2;
    final maxLeft = math.max(margin, size.width - cardWidth - margin);
    final left = (centreX - cardWidth / 2).clamp(margin, maxLeft).toDouble();

    if (hole == null) {
      return Positioned(
        left: left,
        top: size.height / 2 - AppSizeHeight.s30,
        child: _cardBody(cardWidth),
      );
    }
    final gap = AppPaddingHeight.p3;
    if (hole.height > size.height * 0.8) {
      // The spotlight covers most of the picture (zoom steps): sit at the
      // bottom. The text is see-through to touches, so the picture stays
      // pinchable under it. Only the buttons take touches.
      return Positioned(
        left: left,
        bottom: margin,
        child: _zoomCardBody(cardWidth),
      );
    }
    final card = _cardBody(cardWidth);
    if (hole.center.dy < size.height / 2) {
      return Positioned(left: left, top: hole.bottom + gap, child: card);
    }
    return Positioned(
      left: left,
      bottom: size.height - hole.top + gap,
      child: card,
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: ColorManager.white,
      borderRadius: BorderRadius.circular(AppSizeWidth.s3),
      boxShadow: [
        BoxShadow(
          color: ColorManager.hex40000000,
          blurRadius: AppPx.p16,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  /// Title and explanation.
  Widget _caption(TutorialStep step) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (step.icon != null) ...[
              Icon(
                step.icon,
                color: ColorManager.darkPrimary,
                size: AppSizeWidth.s4,
              ),
              SizedBox(width: AppSizeWidth.s2),
            ],
            Expanded(
              child: Text(
                tr(step.titleKey),
                style: getBoldStyle(
                  fontSize: FontSize.s16,
                  color: ColorManager.darkPrimary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSizeHeight.s2),
        Text(
          tr(step.bodyKey),
          style: getRegularStyle(
            fontSize: FontSize.s14,
            color: ColorManager.darkGrey,
          ),
        ),
      ],
    );
  }

  Widget _stepCounter() {
    return Text(
      tr('tut_step_of', {
        'current': '${_index + 1}',
        'total': '${widget.steps.length}',
      }),
      style: getRegularStyle(
        fontSize: FontSize.s12,
        color: ColorManager.lightGrey,
      ),
    );
  }

  /// Skip and Next.
  Widget _actions() {
    return Material(
      color: ColorManager.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: widget.onFinished,
            style: TextButton.styleFrom(
              minimumSize: Size(AppPx.p44, AppPx.p44),
            ),
            child: Text(
              tr('tut_skip'),
              style: getRegularStyle(
                fontSize: FontSize.s14,
                color: ColorManager.grey,
              ),
            ),
          ),
          SizedBox(width: AppSizeWidth.s2),
          FilledButton(
            onPressed: _next,
            style: FilledButton.styleFrom(
              backgroundColor: ColorManager.darkPrimary,
              minimumSize: Size(AppPx.p44, AppPx.p44),
            ),
            child: Text(
              tr(_isLast ? 'tut_done' : 'tut_next'),
              style: getBoldStyle(
                fontSize: FontSize.s14,
                color: ColorManager.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Normal steps: one card with the text, the counter and the buttons.
  /// Wrap moves the counter or buttons to a new line when text is large or
  /// long, instead of overflowing the card.
  Widget _cardBody(double width) {
    return Material(
      color: ColorManager.transparent,
      child: Container(
        width: width,
        padding: EdgeInsets.all(AppPaddingWidth.p3),
        decoration: _boxDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _caption(_step),
            SizedBox(height: AppSizeHeight.s3),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSizeWidth.s2,
              runSpacing: AppSizeHeight.s2,
              children: [_stepCounter(), _actions()],
            ),
          ],
        ),
      ),
    );
  }

  /// Zoom steps. The text is wrapped in IgnorePointer, so touches on it reach
  /// the picture and both fingers can pinch anywhere on the picture. Only the
  /// buttons, in their own small box, take touches.
  Widget _zoomCardBody(double width) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IgnorePointer(
            child: Container(
              padding: EdgeInsets.all(AppPaddingWidth.p3),
              decoration: _boxDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _caption(_step),
                  SizedBox(height: AppSizeHeight.s2),
                  _stepCounter(),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSizeHeight.s2),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              padding: EdgeInsets.all(AppPaddingWidth.p3),
              decoration: _boxDecoration(),
              child: _actions(),
            ),
          ),
        ],
      ),
    );
  }
}
