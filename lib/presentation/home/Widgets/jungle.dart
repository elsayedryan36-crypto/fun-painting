import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';

import '../../common/resources/assets_manager.dart';
import '../../common/resources/values_manager.dart';

class CollectionWidget extends StatefulWidget {
  final String videoPath;

  const CollectionWidget({super.key, required this.videoPath});

  @override
  State<CollectionWidget> createState() => _CollectionWidgetState();
}

class _CollectionWidgetState extends State<CollectionWidget> {
  late VideoPlayerController _controller;

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
          // NEW (fantastic home): a missing/undecodable clip must never take
          // the shelf down with an unhandled async error.
          debugPrint('collection video init failed (${widget.videoPath}): $e');
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NEW (fantastic home): the sticker frame lives in WorldCard now,
    // so the video simply fills whatever box the card gives it.
    if (!_controller.value.isInitialized) {
      return Center(
        child: Lottie.asset(
          JsonAssets.loader,
          width: math.max(60, AppSizeWidth.s20),
          height: math.max(60, AppSizeWidth.s20),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
      ),
    );

    // OLD (the card frame used to live here; WorldCard owns it now):
    // return Center(
    //   child: Container(
    //     width: AppSizeWidth.s90,
    //     height: AppSizeHeight.s85,
    //     clipBehavior: Clip.hardEdge,
    //     decoration: BoxDecoration(
    //       borderRadius: BorderRadius.circular(AppSizeHeight.s10),
    //     ),
    //     child: _controller.value.isInitialized
    //         ? FittedBox(
    //             fit: BoxFit.cover,
    //             child: SizedBox(
    //               width: _controller.value.size.width,
    //               height: _controller.value.size.height,
    //               child: Center(
    //                 child: FittedBox(
    //                   fit: BoxFit.scaleDown,
    //                   child: SizedBox(
    //                     width: _controller.value.size.width,
    //                     height: _controller.value.size.height,
    //                     child: VideoPlayer(_controller),
    //                   ),
    //                 ),
    //               ),
    //             ),
    //           )
    //         : Center(
    //             child: Lottie.asset(JsonAssets.loader, width: 250, height: 250),
    //           ),
    //   ),
    // );
  }
}
