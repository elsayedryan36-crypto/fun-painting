import 'package:flutter/material.dart';

import '../../common/resources/assets_manager.dart';

import 'package:audioplayers/audioplayers.dart';

import 'kid_controls.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playClick() async {
    await _player.play(AssetSource('sounds/click.mp3'));
  }
}

/////////////////////////////////////////////////////////////////
/// Close / Undo / Redo / Save rail.
///
/// ✅ CHANGED (kid-ui): this used to be a floating column sized as a percentage
/// of the screen height (`height: AppSizeHeight.s56`, buttons `s14` tall) and
/// it was *positioned on top of* the canvas. It is now a docked rail with fixed
/// 64 dp buttons, and it can lay itself out vertically (side rail) or
/// horizontally (bottom bar) depending on what the screen shape allows.
class VerticalActionToolsWidget extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onSave;
  final VoidCallback redo;
  final Animation<double> animation;
  final Future<void> Function()? onClose;

  /// ✅ NEW: Axis.vertical = side rail, Axis.horizontal = bottom bar.
  final Axis axis;

  const VerticalActionToolsWidget({
    super.key,
    required this.onUndo,
    required this.onSave,
    required this.redo,
    required this.animation,
    this.onClose,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return KidRail(
      axis: axis,
      children: [
        _buildCloseButton(),
        _buildUndoButton(),
        _buildRedoButton(),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildCloseButton() {
    return KidRailButton(
      onTap: () async {
        await SoundService.playClick();
        await onClose?.call();
      },
      child: Image.asset(ImageAssets.close, fit: BoxFit.contain),
    );
  }

  Widget _buildUndoButton() {
    return KidRailButton(
      onTap: () async {
        await SoundService.playClick();
        onUndo();
      },
      child: Image.asset(ImageAssets.redo, fit: BoxFit.contain),
    );
  }

  Widget _buildRedoButton() {
    return KidRailButton(
      onTap: () async {
        await SoundService.playClick();
        redo();
      },
      child: Transform.flip(
        flipX: true,
        child: Image.asset(ImageAssets.redo, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildSaveButton() {
    return KidRailButton(
      onTap: () async {
        await SoundService.playClick();
        onSave();
      },
      child: Image.asset(ImageAssets.camera, fit: BoxFit.contain),
    );
  }
}

// ----- old version (kept for reference) -----
// The previous implementation sized everything as a percentage of the screen
// height and floated on top of the drawing.
//
// import 'package:flutter/material.dart';
//
// import '../../common/resources/assets_manager.dart';
// import '../../common/resources/values_manager.dart';
//
// import 'package:audioplayers/audioplayers.dart';
//
// class SoundService { ... unchanged, see above ... }
//
// class VerticalActionToolsWidget extends StatelessWidget {
//   final VoidCallback onUndo;
//   final VoidCallback onSave;
//   final VoidCallback redo;
//   final Animation<double> animation;
//   final Future<void> Function()? onClose;
//
//   const VerticalActionToolsWidget({
//     super.key,
//     required this.onUndo,
//     required this.onSave,
//     required this.redo,
//     required this.animation,
//     this.onClose,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: animation,
//       child: Container(
//         margin: EdgeInsets.symmetric(
//           vertical: AppSizeHeight.s1,
//           horizontal: AppSizeWidth.s1,
//         ),
//         height: AppSizeHeight.s56,
//         width: AppSizeWidth.s8,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             GestureDetector(
//               onTap: () async {
//                 await SoundService.playClick();
//                 await onClose?.call();
//               },
//               child: SizedBox(
//                 width: AppSizeWidth.s7,
//                 height: AppSizeHeight.s14,
//                 child: Image.asset(ImageAssets.close, fit: BoxFit.contain),
//               ),
//             ),
//             GestureDetector(
//               onTap: () async {
//                 await SoundService.playClick();
//                 onUndo();
//               },
//               child: SizedBox(
//                 width: AppSizeWidth.s7,
//                 height: AppSizeHeight.s14,
//                 child: Image.asset(ImageAssets.redo, fit: BoxFit.contain),
//               ),
//             ),
//             GestureDetector(
//               onTap: () async {
//                 await SoundService.playClick();
//                 redo();
//               },
//               child: SizedBox(
//                 width: AppSizeWidth.s7,
//                 height: AppSizeHeight.s14,
//                 child: Transform.flip(
//                   flipX: true,
//                   child: Image.asset(ImageAssets.redo, fit: BoxFit.contain),
//                 ),
//               ),
//             ),
//             GestureDetector(
//               onTap: () async {
//                 await SoundService.playClick();
//                 onSave();
//               },
//               child: SizedBox(
//                 width: AppSizeWidth.s7,
//                 height: AppSizeHeight.s14,
//                 child: Image.asset(ImageAssets.camera, fit: BoxFit.contain),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
