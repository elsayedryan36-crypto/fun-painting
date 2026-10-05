import 'package:flutter/material.dart';

import '../../common/resources/assets_manager.dart';
import '../../common/resources/values_manager.dart';

import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playClick() async {
    await _player.play(AssetSource('sounds/click.mp3'));
  }
}

/////////////////////////////////////////////////////////////////
class VerticalActionToolsWidget extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onSave;
  final VoidCallback redo;
  final Animation<double> animation;
  final Future<void> Function()? onClose;

  const VerticalActionToolsWidget({
    super.key,
    required this.onUndo,
    required this.onSave,
    required this.redo,
    required this.animation,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: AppSizeHeight.s1,
          horizontal: AppSizeWidth.s1,
        ),
        height: AppSizeHeight.s56,
        width: AppSizeWidth.s8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                await SoundService.playClick();
                await onClose?.call();
              },
              child: SizedBox(
                width: AppSizeWidth.s7,
                height: AppSizeHeight.s14,
                child: Image.asset(ImageAssets.close, fit: BoxFit.contain),
              ),
            ),

            GestureDetector(
              onTap: () async {
                await SoundService.playClick();
                onUndo();
              },
              child: SizedBox(
                width: AppSizeWidth.s7,
                height: AppSizeHeight.s14,
                child: Image.asset(ImageAssets.redo, fit: BoxFit.contain),
              ),
            ),

            GestureDetector(
              onTap: () async {
                await SoundService.playClick();
                redo();
              },
              child: SizedBox(
                width: AppSizeWidth.s7,
                height: AppSizeHeight.s14,
                child: Transform.flip(
                  flipX: true,
                  child: Image.asset(ImageAssets.redo, fit: BoxFit.contain),
                ),
              ),
            ),

            GestureDetector(
              onTap: () async {
                await SoundService.playClick();
                onSave();
              },
              child: SizedBox(
                width: AppSizeWidth.s7,
                height: AppSizeHeight.s14,
                child: Image.asset(ImageAssets.camera, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
