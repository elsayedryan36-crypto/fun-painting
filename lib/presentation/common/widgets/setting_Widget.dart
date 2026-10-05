import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../resources/assets_manager.dart';
import '../resources/values_manager.dart';
import 'info_settings_dialog.dart';

class SettingWidget extends StatefulWidget {
  final AudioPlayer player;
  final double initialVolume;
  final ValueChanged<double>? onVolumeChanged;
  const SettingWidget({
    super.key,
    required this.player,
    this.initialVolume = 0.2,
    this.onVolumeChanged,
  });
  @override
  State<SettingWidget> createState() => _SettingWidgetState();
}

class _SettingWidgetState extends State<SettingWidget> {
  late double _currentVolume;
  @override
  void initState() {
    super.initState();
    _currentVolume = widget.initialVolume;
    widget.player.setVolume(_currentVolume);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Lottie.asset(JsonAssets.setting, height: AppSizeHeight.s10),
      onPressed: () {
        showDialog(
          context: context,
          builder: (dialogContext) {
            return InfoSettingsDialog(
              player: widget.player,
              initialVolume: _currentVolume,
              onVolumeChanged: (value) {
                setState(() {
                  _currentVolume = value;
                });
                widget.player.setVolume(value);
                widget.onVolumeChanged?.call(value);
              },
            );
          },
        );
      },
    );
  }
}
