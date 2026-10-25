import 'package:flutter/material.dart';
import 'package:fun_painting/app/app_pref.dart';
import 'package:fun_painting/presentation/common/localization/app_language.dart';
import 'package:fun_painting/presentation/common/resources/color_manager.dart';
import 'package:fun_painting/presentation/common/resources/values_manager.dart';
import 'package:fun_painting/presentation/common/services/music_level.dart';
import 'package:fun_painting/presentation/common/services/sound_service.dart';

import '../resources/font_manager.dart';

/// NEW: the Sound levels popup. Two sliders, background music and brush
/// sounds, each from 0% to 100%. Changes apply right away; releasing the
/// brush slider plays a short click so the user can hear the new level.
class SoundLevelsDialog extends StatefulWidget {
  final double initialMusic;
  final double initialBrush;
  final ValueChanged<double> onMusicChanged;
  final ValueChanged<double> onBrushChanged;

  const SoundLevelsDialog({
    super.key,
    required this.initialMusic,
    required this.initialBrush,
    required this.onMusicChanged,
    required this.onBrushChanged,
  });

  @override
  State<SoundLevelsDialog> createState() => _SoundLevelsDialogState();
}

class _SoundLevelsDialogState extends State<SoundLevelsDialog> {
  late double _music = widget.initialMusic;
  late double _brush = widget.initialBrush;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppSizeWidth.s5,
        vertical: AppSizeHeight.s5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizeHeight.s10),
      ),
      backgroundColor: ColorManager.lightPrimary,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppPx.p20,
            AppPx.p8,
            AppPx.p8,
            AppPx.p20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- HEADER: title + close ----
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr('sound_levels'),
                      style: TextStyle(
                        fontSize: FontSize.s18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: tr('close'),
                    icon: Icon(Icons.close, color: ColorManager.darkPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: AppPx.p8),

              // ---- BACKGROUND MUSIC ----
              _levelRow(
                icon: _music == 0
                    ? Icons.volume_off_rounded
                    : Icons.music_note_rounded,
                label: tr('background_music'),
                value: _music,
                onChanged: (value) {
                  setState(() => _music = value);
                  widget.onMusicChanged(value);
                },
              ),
              SizedBox(height: AppPx.p16),

              // ---- BRUSH SOUNDS (preview click on release) ----
              _levelRow(
                icon: Icons.brush_rounded,
                label: tr('brush_sounds'),
                value: _brush,
                onChanged: (value) {
                  setState(() => _brush = value);
                  widget.onBrushChanged(value);
                },
                onChangeEnd: (_) =>
                    BrushSoundService.instance.playOnce('sounds/fill.mp3'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelRow({
    required IconData icon,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    final percent = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: ColorManager.darkBluPrimary),
            SizedBox(width: AppPx.p8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: FontSize.s16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: FontSize.s16,
                fontWeight: FontWeight.bold,
                color: ColorManager.darkPrimary,
              ),
            ),
          ],
        ),
        Slider(
          activeColor: ColorManager.gold,
          inactiveColor: ColorManager.materialGreyShade300,
          value: value,
          min: 0,
          max: 1,
          divisions: 20,
          label: '$percent%',
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}

/// NEW (round 26): open the Sound levels popup from any page.
///
/// Background music is saved through [MusicLevel], so the home music follows
/// at once. Brush sounds are saved and applied to [BrushSoundService].
Future<void> showSoundLevels(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => SoundLevelsDialog(
      initialMusic: AppPreferences().getKMusicVolume(),
      initialBrush: AppPreferences().getKBrushVolume(),
      onMusicChanged: (value) => MusicLevel.set(value),
      onBrushChanged: (value) {
        AppPreferences().setKBrushVolume(value);
        BrushSoundService.instance.setLevel(value);
      },
    ),
  );
}
