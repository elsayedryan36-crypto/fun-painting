import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/common/localization/app_language.dart';
import 'package:fun_painting/presentation/common/resources/color_manager.dart';
import 'package:lottie/lottie.dart';
import '../resources/assets_manager.dart';
import '../resources/values_manager.dart';
import 'info_settings_dialog.dart';
import 'sound_levels_dialog.dart';

/// Gear button: opens the Settings popup (language, contact, rate).
class SettingWidget extends StatelessWidget {
  const SettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: tr('settings'),
      icon: Lottie.asset(JsonAssets.setting, height: AppSizeHeight.s10),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => const InfoSettingsDialog(),
        );
      },
    );
  }
}

/// Sound button: opens the Sound levels popup (background music and brush
/// sounds). Works on the home, gallery and painting pages.
/// (Round 26: no player is passed in any more; the music level is shared
/// through MusicLevel, so the button works on every page.)
class SoundLevelButton extends StatelessWidget {
  /// Width and height of the round button. Defaults to the gear's size.
  final double? size;

  const SoundLevelButton({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final double side = size ?? AppSizeHeight.s10;
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      tooltip: tr('sound_levels'),
      icon: Container(
        width: side,
        height: side,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.volume_up_rounded,
          color: ColorManager.darkPrimary,
          size: side * 0.55,
        ),
      ),
      onPressed: () => showSoundLevels(context),
    );
  }
}

// (old) SoundLevelButton before round 26, with its own player:
// /// NEW: Sound button: opens the Sound levels popup (background music and
// /// brush sounds). Both levels are saved and used across the whole app.
// class SoundLevelButton extends StatelessWidget {
//   /// The home screen's background music player.
//   final AudioPlayer player;
//
//   const SoundLevelButton({super.key, required this.player});
//
//   @override
//   Widget build(BuildContext context) {
//     return IconButton(
//       padding: EdgeInsets.zero,
//       constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
//       tooltip: tr('sound_levels'),
//       icon: Container(
//         width: AppSizeHeight.s10,
//         height: AppSizeHeight.s10,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: Colors.white,
//           boxShadow: const [
//             BoxShadow(
//               color: Colors.black26,
//               blurRadius: 4,
//               offset: Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Icon(Icons.volume_up_rounded, color: ColorManager.darkPrimary),
//       ),
//       onPressed: () {
//         showDialog(
//           context: context,
//           builder: (_) => SoundLevelsDialog(
//             initialMusic: AppPreferences().getKMusicVolume(),
//             initialBrush: AppPreferences().getKBrushVolume(),
//             onMusicChanged: (value) {
//               AppPreferences().setKMusicVolume(value);
//               player.setVolume(value);
//             },
//             onBrushChanged: (value) {
//               AppPreferences().setKBrushVolume(value);
//               BrushSoundService.instance.setLevel(value);
//             },
//           ),
//         );
//       },
//     );
//   }
// }

// (old) the gear button with the volume slider, before round 25:
// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
// import '../resources/assets_manager.dart';
// import '../resources/values_manager.dart';
// import 'info_settings_dialog.dart';
//
// class SettingWidget extends StatefulWidget {
//   final AudioPlayer player;
//   final double initialVolume;
//   final ValueChanged<double>? onVolumeChanged;
//   const SettingWidget({
//     super.key,
//     required this.player,
//     this.initialVolume = 0.2,
//     this.onVolumeChanged,
//   });
//   @override
//   State<SettingWidget> createState() => _SettingWidgetState();
// }
//
// class _SettingWidgetState extends State<SettingWidget> {
//   late double _currentVolume;
//   @override
//   void initState() {
//     super.initState();
//     _currentVolume = widget.initialVolume;
//     widget.player.setVolume(_currentVolume);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return IconButton(
//       padding: EdgeInsets.zero,
//       constraints: const BoxConstraints(),
//       icon: Lottie.asset(JsonAssets.setting, height: AppSizeHeight.s10),
//       onPressed: () {
//         showDialog(
//           context: context,
//           builder: (dialogContext) {
//             return InfoSettingsDialog(
//               player: widget.player,
//               initialVolume: _currentVolume,
//               onVolumeChanged: (value) {
//                 setState(() {
//                   _currentVolume = value;
//                 });
//                 widget.player.setVolume(value);
//                 widget.onVolumeChanged?.call(value);
//               },
//             );
//           },
//         );
//       },
//     );
//   }
// }
