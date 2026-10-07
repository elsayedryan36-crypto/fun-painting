import 'package:flutter/material.dart';

import '../../common/resources/assets_manager.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
/// ✅ CHANGED (kid-ui round 3): five buttons — Close, Undo, Redo, Save and the
/// protected Clear (it moved here from the tool rail, away from the eraser and
/// next to Undo). Each one has a short word under its icon, a bright face
/// colour, and is sized as a percentage of the screen by [KidRail].
///
/// ✅ CHANGED (kid-ui): this used to be a floating column sized as a percentage
/// of the screen height (`height: AppSizeHeight.s56`, buttons `s14` tall) and
/// it was *positioned on top of* the canvas. It is now a docked rail.
class VerticalActionToolsWidget extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onSave;
  final VoidCallback redo;
  final Animation<double> animation;
  final Future<void> Function()? onClose;

  /// ✅ NEW (kid-ui round 3): the protected "erase everything?" action, moved
  /// here so it is not next to the eraser any more.
  final VoidCallback? onClear;

  /// ✅ NEW: Axis.vertical = side rail, Axis.horizontal = bottom bar.
  final Axis axis;

  const VerticalActionToolsWidget({
    super.key,
    required this.onUndo,
    required this.onSave,
    required this.redo,
    required this.animation,
    this.onClose,
    this.onClear,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return KidRail(
      axis: axis,
      // A soft cream rail so it is obviously "the other" rail.
      background: const Color(0xFFFFFDF5),
      children: [
        _buildCloseButton(),
        _buildUndoButton(),
        _buildRedoButton(),
        _buildSaveButton(),
        _buildClearButton(),
      ],
    );
  }

  Widget _buildCloseButton() {
    return KidRailButton(
      onTap: () async {
        await SoundService.playClick();
        await onClose?.call();
      },
      label: 'Close',
      faceColor: const Color(0xFFB0BEC5),
      child: Image.asset(ImageAssets.close, fit: BoxFit.contain),
    );
  }

  Widget _buildUndoButton() {
    return KidRailButton(
      onTap: () async {
        await SoundService.playClick();
        onUndo();
      },
      label: 'Undo',
      child: Image.asset(ImageAssets.redo, fit: BoxFit.contain),
    );
  }

  Widget _buildRedoButton() {
    return KidRailButton(
      onTap: () async {
        await SoundService.playClick();
        redo();
      },
      label: 'Redo',
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
      label: 'Save',
      faceColor: const Color(0xFFC8E6C9),
      child: Image.asset(ImageAssets.camera, fit: BoxFit.contain),
    );
  }

  /// ✅ NEW (kid-ui round 3): erase everything, from the rail — the page asks
  /// "Erase everything?" first (see kid_dialogs.dart). Red face = a grown-up
  /// button, and it is the last one, next to Undo.
  Widget _buildClearButton() {
    return KidRailButton(
      onTap: () async {
        await SoundService.playClick();
        onClear?.call();
      },
      label: 'Clear',
      faceColor: const Color(0xFFFFCDD2),
      child: SvgPicture.asset(ImageAssets.delete, fit: BoxFit.contain),
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
