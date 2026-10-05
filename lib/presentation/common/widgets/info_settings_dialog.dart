import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:font_awesome_icon_class/font_awesome_icon_class.dart';
import 'package:fun_painting/presentation/common/resources/color_manager.dart';
import 'package:fun_painting/presentation/common/resources/values_manager.dart';
import 'package:url_launcher/url_launcher.dart';

import '../resources/font_manager.dart';
import '../resources/styles_manager.dart';
import 'info_widget.dart';

class InfoSettingsDialog extends StatefulWidget {
  final AudioPlayer player;
  final double initialVolume;
  final ValueChanged<double> onVolumeChanged;

  const InfoSettingsDialog({
    super.key,
    required this.player,
    required this.initialVolume,
    required this.onVolumeChanged,
  });

  @override
  State<InfoSettingsDialog> createState() => _InfoSettingsDialogState();
}

class _InfoSettingsDialogState extends State<InfoSettingsDialog> {
  late double _volume;

  @override
  void initState() {
    super.initState();
    _volume = widget.initialVolume;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizeHeight.s10),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizeHeight.s10),
          color: ColorManager.lightPrimary,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppSizeHeight.s5,
            horizontal: AppSizeWidth.s3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // SizedBox(child: Expanded(child: Container())),
                  Text(
                    'Sound',
                    style: TextStyle(
                      fontSize: FontSize.s18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: ColorManager.darkPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              // const SizedBox(height: 40),

              // ---------------- VOLUME CONTROL ----------------
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      // height: AppSizeHeight.s15,
                      child: Icon(
                        size: AppSizeHeight.s12,
                        _volume == 0 ? Icons.volume_off : Icons.volume_up,
                        color: ColorManager.darkBluPrimary,
                      ),
                    ),
                    // const Text('Music Volume'),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizeWidth.s5,
                      ),
                      child: SizedBox(
                        width: AppSizeWidth.s62,
                        child: Slider(
                          activeColor: ColorManager.gold,
                          inactiveColor: Colors.grey,
                          value: _volume,
                          min: 0,
                          max: 1,
                          divisions: 10,
                          label: '${(_volume * 100).round()}%',
                          onChanged: (value) {
                            setState(() => _volume = value);
                            widget.player.setVolume(value);
                            widget.onVolumeChanged(value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Center(
                child: SizedBox(
                  height: AppSizeHeight.s10,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Contact us',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: AppSizeWidth.s5),
                      IconButton(
                        onPressed: () =>
                            _launchEmail(context, 'elsayedryan36@gmail.com'),
                        icon: Icon(
                          Icons.email_rounded,
                          color: ColorManager.gold,
                          size: AppSizeHeight.s10,
                        ),
                      ),
                      SizedBox(width: AppSizeWidth.s8),
                      IconButton(
                        onPressed: () =>
                            _launchWhatsApp(context, '201028103777', ''),
                        icon: FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: ColorManager.gold,
                          size: AppSizeHeight.s10,
                        ),
                      ),
                      SizedBox(width: AppSizeWidth.s15),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizeHeight.s5),
                child: const RateAppWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Launch Email with Subject & Body with enhanced error handling
  static Future<void> _launchEmail(BuildContext context, String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Fun Painting App Inquiry'},
    );

    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot open email app')));
    }
  }

  /// Show dialog when no email client is available

  /// Launch WhatsApp Message with international number support
  static Future<void> _launchWhatsApp(
    BuildContext context,
    String phoneNumber,
    String message,
  ) async {
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    final uri = Uri.parse(
      "https://wa.me/$cleanedNumber?text=${Uri.encodeComponent(message)}",
    );

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot open WhatsApp')));
    }
  }
}

// Your existing TextSection and AzzanSetting classes remain the same
class TextSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;

  const TextSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: AppSizeHeight.s1_5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: AppSizeWidth.s100,
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: getBoldStyle(fontSize: FontSize.s16, color: titleColor),
            ),
          ),
          SizedBox(
            width: AppSizeWidth.s100,
            child: Text(
              subtitle,
              textAlign: TextAlign.right,
              style: getRegularStyle(
                fontSize: FontSize.s16,
                color: subtitleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
