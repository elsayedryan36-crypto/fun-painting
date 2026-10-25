import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';

import '../../common/resources/assets_manager.dart';
import '../../common/resources/values_manager.dart';

// ============================================================
// Lottie cards.
//
// Every card plays its own Lottie file (set per world in
// kid_home_shelf.dart) and, inside that file, only a slice: a start frame
// and an end frame (FrameRange). A file is parsed once and shared.
// ============================================================

/// The slice of a Lottie a card plays, in the frame numbers of that file.
@immutable
class FrameRange {
  final double start;
  final double end;

  const FrameRange(this.start, this.end);

  /// A still card: shows this one frame and never moves.
  const FrameRange.still(double frame) : start = frame, end = frame;

  bool get isStill => start == end;
}

/// An extra Lottie stacked on top of a card's main one (see WorldMeta.layers).
/// Layers are drawn in list order: the last one is on top.
@immutable
class LottieLayer {
  final String lottie;
  final FrameRange? frames;

  /// How the layer fills the card (cover = fill, contain = fit inside).
  final BoxFit fit;

  /// Where the layer sits in the card.
  final Alignment alignment;

  /// 1.0 = the card size; 0.5 = half size, around [alignment].
  final double scale;

  const LottieLayer(
    this.lottie, {
    this.frames,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.scale = 1.0,
  });
}

/// Loads each Lottie file once and shares the parsed composition.
class CardLottie {
  CardLottie._();

  static final Map<String, Future<LottieComposition>> _cache = {};

  static Future<LottieComposition> load(String asset) {
    return _cache.putIfAbsent(
      asset,
      () => AssetLottie(asset).load().then(
        (composition) {
          if (kDebugMode) {
            // Use these numbers to choose the start / end frame.
            debugPrint(
              '$asset: frames ${composition.startFrame}'
              ' to ${composition.endFrame}'
              ' @ ${composition.frameRate} fps'
              ' (${composition.duration.inMilliseconds} ms)',
            );
          }
          return composition;
        },
        onError: (Object error, StackTrace stack) {
          // Forget the failure so a later card can try again.
          _cache.remove(asset);
          Error.throwWithStackTrace(error, stack);
        },
      ),
    );
  }
}

/// A card picture: plays [frames] of the Lottie at [asset], looping by
/// default. No [frames] = the whole file. A [FrameRange.still] = one frame.
///
/// If the file is missing or broken it draws nothing (no error box); the
/// reason is printed in the debug console.
class CardLottieThumb extends StatefulWidget {
  final String asset;
  final FrameRange? frames;
  final bool loop;
  final BoxFit fit;
  final Alignment alignment;
  final double scale;

  const CardLottieThumb({
    super.key,
    required this.asset,
    this.frames,
    this.loop = true,
    this.fit = BoxFit.fill,
    this.alignment = Alignment.center,
    this.scale = 1.0,
  });

  @override
  State<CardLottieThumb> createState() => _CardLottieThumbState();
}

class _CardLottieThumbState extends State<CardLottieThumb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  LottieComposition? _composition;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final asset = widget.asset;
    try {
      final composition = await CardLottie.load(asset);
      if (!mounted || asset != widget.asset) return;
      _composition = composition;
      _play();
      setState(() {});
    } catch (e) {
      debugPrint('lottie failed to load ($asset): $e');
    }
  }

  @override
  void didUpdateWidget(CardLottieThumb oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.asset != oldWidget.asset) {
      _controller.stop();
      _composition = null;
      _load();
      return;
    }

    final range = widget.frames;
    final old = oldWidget.frames;
    final rangeChanged = range?.start != old?.start || range?.end != old?.end;
    if (rangeChanged || widget.loop != oldWidget.loop) _play();
  }

  /// Plays the card's slice. The controller runs 0..1 over the WHOLE file,
  /// so a frame number becomes (frame - firstFrame) / totalFrames.
  void _play() {
    final composition = _composition;
    if (composition == null) return;

    final first = composition.startFrame;
    final last = composition.endFrame;
    final total = last - first;
    if (total <= 0) return;

    final range = widget.frames;
    final startFrame = (range?.start ?? first).clamp(first, last).toDouble();
    final endFrame = (range?.end ?? last).clamp(startFrame, last).toDouble();

    if (kDebugMode &&
        range != null &&
        (range.start < first || range.end > last || range.end < range.start)) {
      debugPrint(
        '${widget.asset} has frames $first to $last, but the card asks for '
        '${range.start} to ${range.end}. Using $startFrame to $endFrame.',
      );
    }

    final from = (startFrame - first) / total;
    final to = (endFrame - first) / total;

    _controller.stop();

    if (to <= from) {
      // Start == end: a still picture.
      _controller.value = from;
      return;
    }

    final span = Duration(
      microseconds: (composition.duration.inMicroseconds * (to - from)).round(),
    );

    if (widget.loop) {
      // Starts at 0 so the repeat begins exactly on the start frame.
      _controller.value = 0;
      _controller.repeat(min: from, max: to, period: span);
    } else {
      _controller.value = from;
      _controller.animateTo(to, duration: span);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final composition = _composition;
    if (composition == null) return const SizedBox.shrink();

    Widget lottie = Lottie(
      composition: composition,
      controller: _controller,
      fit: widget.fit,
      alignment: widget.alignment,
    );
    if (widget.scale != 1.0) {
      lottie = Transform.scale(
        scale: widget.scale,
        alignment: widget.alignment,
        child: lottie,
      );
    }
    return RepaintBoundary(child: lottie);
  }
}

// ============================================================
// The old looping-video card. Cards no longer use it; it stays so anything
// that still imports CollectionWidget keeps compiling.
// ============================================================

class CollectionWidget extends StatefulWidget {
  final String videoPath;

  const CollectionWidget({super.key, required this.videoPath});

  @override
  State<CollectionWidget> createState() => _CollectionWidgetState();
}

class _CollectionWidgetState extends State<CollectionWidget> {
  late final VideoPlayerController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(widget.videoPath);
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {});
          _controller
            ..setLooping(true)
            ..setVolume(0)
            ..play();
        })
        .catchError((Object e) {
          // A missing / undecodable clip must never take the shelf down.
          debugPrint('collection video init failed (${widget.videoPath}): $e');
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();

    if (!_controller.value.isInitialized) {
      return Center(
        child: Lottie.asset(
          JsonAssets.loader,
          width: math.max(AppPx.p60, AppSizeWidth.s20),
          height: math.max(AppPx.p60, AppSizeWidth.s20),
        ),
      );
    }

    // The sticker frame lives in WorldCard, so the video fills its box.
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}
