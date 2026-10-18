import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_icon_class/font_awesome_icon_class.dart';
import 'package:fun_painting/presentation/common/localization/app_language.dart';
import 'package:fun_painting/presentation/common/resources/color_manager.dart';
import 'package:fun_painting/presentation/common/resources/routs_manager.dart';
import 'package:fun_painting/presentation/common/resources/values_manager.dart';
import 'package:url_launcher/url_launcher.dart';

import '../resources/font_manager.dart';
import '../resources/styles_manager.dart';
import 'info_widget.dart';

// (old) imports before round 25:
// import 'package:flutter/material.dart';
// import 'package:fun_painting/presentation/common/localization/app_language.dart';
// import 'package:fun_painting/presentation/common/resources/routs_manager.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:font_awesome_icon_class/font_awesome_icon_class.dart';
// import 'package:fun_painting/presentation/common/resources/color_manager.dart';
// import 'package:fun_painting/presentation/common/resources/values_manager.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// import '../resources/font_manager.dart';
// import '../resources/styles_manager.dart';
// import 'info_widget.dart';

/// Round 26 layout, side menu (option B): a list of the three sections on the
/// left, the chosen one on the right. Short enough for a landscape phone.
enum _SettingsTab { language, contact, rate }

class InfoSettingsDialog extends StatefulWidget {
  const InfoSettingsDialog({super.key});

  @override
  State<InfoSettingsDialog> createState() => _InfoSettingsDialogState();
}

class _InfoSettingsDialogState extends State<InfoSettingsDialog> {
  _SettingsTab _selected = _SettingsTab.language;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    // The body fills the screen height left after the header and margins.
    final bodyHeight = math.min(260.0, screen.height - 140);
    final menuWidth = math.min(190.0, screen.width * 0.34);
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
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- HEADER: title and close ----
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr('settings'),
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
              // ---- BODY: menu on the left, one section on the right ----
              SizedBox(
                height: bodyHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: menuWidth, child: _menu()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(child: _panel(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The three sections, as a list. The chosen one is gold.
  Widget _menu() {
    return Column(
      children: [
        _menuItem(
          _SettingsTab.language,
          Icons.language_rounded,
          tr('language'),
        ),
        const SizedBox(height: 8),
        _menuItem(_SettingsTab.contact, Icons.email_rounded, tr('contact_us')),
        const SizedBox(height: 8),
        _menuItem(_SettingsTab.rate, Icons.star_rounded, tr('rate_app')),
      ],
    );
  }

  Widget _menuItem(_SettingsTab tab, IconData icon, String label) {
    final on = _selected == tab;
    return Material(
      color: on ? ColorManager.gold : Colors.white.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _selected = tab),
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(icon, color: ColorManager.darkPrimary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: FontSize.s16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The chosen section, in a white card.
  Widget _panel(BuildContext context) {
    switch (_selected) {
      case _SettingsTab.language:
        return _SettingsSection(
          title: tr('language'),
          child: _languageChips(context),
        );
      case _SettingsTab.contact:
        return _SettingsSection(
          title: tr('contact_us'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ContactButton(
                icon: Icons.email_rounded,
                label: 'Email',
                onTap: () => _launchEmail(context, 'elsayedryan36@gmail.com'),
              ),
              const SizedBox(height: 8),
              _ContactButton(
                faIcon: FontAwesomeIcons.whatsapp,
                label: 'WhatsApp',
                onTap: () => _launchWhatsApp(context, '201028103777', ''),
              ),
            ],
          ),
        );
      case _SettingsTab.rate:
        return _SettingsSection(
          title: tr('rate_app'),
          child: Center(
            // Scales the rate row down on narrow screens instead of overflowing.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: const RateAppWidget(),
            ),
          ),
        );
    }
  }

  /// A wrapping set of language chips, each shown in its own language.
  Widget _languageChips(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.current,
      builder: (context, selected, _) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in AppLanguage.options)
              ChoiceChip(
                key: ValueKey('language_${option.code}'),
                label: Text(option.nativeName),
                selected: option.code == selected,
                selectedColor: ColorManager.gold,
                onSelected: (_) => _pickLanguage(context, option.code),
              ),
          ],
        );
      },
    );
  }

  /// Switch language, then restart from home so every screen uses it.
  Future<void> _pickLanguage(BuildContext context, String code) async {
    if (code == AppLanguage.current.value) return;
    await AppLanguage.select(code);
    if (!context.mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(Routes.homeRoute, (_) => false);
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
      ).showSnackBar(SnackBar(content: Text(tr('cannot_open_email'))));
    }
  }

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
      ).showSnackBar(SnackBar(content: Text(tr('cannot_open_whatsapp'))));
    }
  }
}

// (old) round-25 layout (stacked sections), before round 26:
// /// NEW layout (round 25): the volume slider moved to the Sound levels popup.
// /// Header (title + close), then three sections in a scrollable body:
// /// Language, Contact us, Rate the app.
// class InfoSettingsDialog extends StatelessWidget {
//   const InfoSettingsDialog({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       insetPadding: EdgeInsets.symmetric(
//         horizontal: AppSizeWidth.s5,
//         vertical: AppSizeHeight.s5,
//       ),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(AppSizeHeight.s10),
//       ),
//       backgroundColor: ColorManager.lightPrimary,
//       child: ConstrainedBox(
//         constraints: const BoxConstraints(maxWidth: 480),
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ---- HEADER: title and close, on one line ----
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       tr('settings'),
//                       style: TextStyle(
//                         fontSize: FontSize.s18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     tooltip: tr('close'),
//                     icon: Icon(Icons.close, color: ColorManager.darkPrimary),
//                     onPressed: () => Navigator.of(context).pop(),
//                   ),
//                 ],
//               ),
//
//               // ---- BODY: scrolls when the screen is short ----
//               Flexible(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _SettingsSection(
//                         title: tr('language'),
//                         child: _languageChips(context),
//                       ),
//                       const SizedBox(height: 12),
//                       _SettingsSection(
//                         title: tr('contact_us'),
//                         child: _contactButtons(context),
//                       ),
//                       const SizedBox(height: 12),
//                       // Scales the rate row down on narrow phones instead of overflowing.
//                       FittedBox(
//                         fit: BoxFit.scaleDown,
//                         child: const RateAppWidget(),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// A wrapping set of language chips, each shown in its own language.
//   Widget _languageChips(BuildContext context) {
//     return ValueListenableBuilder<String>(
//       valueListenable: AppLanguage.current,
//       builder: (context, selected, _) {
//         return Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           children: [
//             for (final option in AppLanguage.options)
//               ChoiceChip(
//                 key: ValueKey('language_${option.code}'),
//                 label: Text(option.nativeName),
//                 selected: option.code == selected,
//                 selectedColor: ColorManager.gold,
//                 onSelected: (_) => _pickLanguage(context, option.code),
//               ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Switch language, then restart from home so every screen uses it.
//   Future<void> _pickLanguage(BuildContext context, String code) async {
//     if (code == AppLanguage.current.value) return;
//     await AppLanguage.select(code);
//     if (!context.mounted) return;
//     Navigator.of(
//       context,
//       rootNavigator: true,
//     ).pushNamedAndRemoveUntil(Routes.homeRoute, (_) => false);
//   }
//
//   /// Email and WhatsApp, side by side, each a large tap target.
//   Widget _contactButtons(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: _ContactButton(
//             icon: Icons.email_rounded,
//             label: 'Email',
//             onTap: () => _launchEmail(context, 'elsayedryan36@gmail.com'),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _ContactButton(
//             faIcon: FontAwesomeIcons.whatsapp,
//             label: 'WhatsApp',
//             onTap: () => _launchWhatsApp(context, '201028103777', ''),
//           ),
//         ),
//       ],
//     );
//   }
//
//   /// Launch Email with Subject & Body with enhanced error handling
//   static Future<void> _launchEmail(BuildContext context, String email) async {
//     final Uri emailUri = Uri(
//       scheme: 'mailto',
//       path: email,
//       queryParameters: {'subject': 'Fun Painting App Inquiry'},
//     );
//
//     try {
//       await launchUrl(emailUri, mode: LaunchMode.externalApplication);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(tr('cannot_open_email'))));
//     }
//   }
//
//   /// Launch WhatsApp Message with international number support
//   static Future<void> _launchWhatsApp(
//     BuildContext context,
//     String phoneNumber,
//     String message,
//   ) async {
//     final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
//
//     final uri = Uri.parse(
//       "https://wa.me/$cleanedNumber?text=${Uri.encodeComponent(message)}",
//     );
//
//     try {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(tr('cannot_open_whatsapp'))));
//     }
//   }
// }

/// NEW: a titled white card that groups one section of the Settings popup.
class _SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: FontSize.s16,
              fontWeight: FontWeight.bold,
              color: ColorManager.darkPrimary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// NEW: one large contact button with an icon and a label.
class _ContactButton extends StatelessWidget {
  final IconData? icon;
  final IconData? faIcon;
  final String label;
  final VoidCallback onTap;

  const _ContactButton({
    this.icon,
    this.faIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget glyph = icon != null
        ? Icon(icon, color: ColorManager.gold, size: AppSizeHeight.s8)
        : FaIcon(faIcon, color: ColorManager.gold, size: AppSizeHeight.s8);
    return Material(
      color: ColorManager.lightPrimary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                glyph,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: FontSize.s16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// (old) InfoSettingsDialog with the volume slider, before round 25:
// class InfoSettingsDialog extends StatefulWidget {
//   final AudioPlayer player;
//   final double initialVolume;
//   final ValueChanged<double> onVolumeChanged;
//
//   const InfoSettingsDialog({
//     super.key,
//     required this.player,
//     required this.initialVolume,
//     required this.onVolumeChanged,
//   });
//
//   @override
//   State<InfoSettingsDialog> createState() => _InfoSettingsDialogState();
// }
//
// class _InfoSettingsDialogState extends State<InfoSettingsDialog> {
//   late double _volume;
//
//   @override
//   void initState() {
//     super.initState();
//     _volume = widget.initialVolume;
//   }
//
//   /// NEW: a row of language chips, each shown in its own language.
//   Widget _languageSection(BuildContext context) {
//     return ValueListenableBuilder<String>(
//       valueListenable: AppLanguage.current,
//       builder: (context, selected, _) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               tr('language'),
//               style: TextStyle(
//                 fontSize: FontSize.s18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 6),
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   for (final option in AppLanguage.options)
//                     Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: ChoiceChip(
//                         key: ValueKey('language_${option.code}'),
//                         label: Text(option.nativeName),
//                         selected: option.code == selected,
//                         selectedColor: ColorManager.gold,
//                         onSelected: (_) => _pickLanguage(context, option.code),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// NEW: switch language, then restart the screens from home in the new language.
//   Future<void> _pickLanguage(BuildContext context, String code) async {
//     if (code == AppLanguage.current.value) return;
//     await AppLanguage.select(code);
//     if (!context.mounted) return;
//     Navigator.of(
//       context,
//       rootNavigator: true,
//     ).pushNamedAndRemoveUntil(Routes.homeRoute, (_) => false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(AppSizeHeight.s10),
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(AppSizeHeight.s10),
//           color: ColorManager.lightPrimary,
//         ),
//         child: Padding(
//           padding: EdgeInsets.symmetric(
//             vertical: AppSizeHeight.s5,
//             horizontal: AppSizeWidth.s3,
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   // SizedBox(child: Expanded(child: Container())),
//                   Text(
//                     tr('sound'),
//                     // 'Sound',
//                     style: TextStyle(
//                       fontSize: FontSize.s18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.close, color: ColorManager.darkPrimary),
//                     onPressed: () => Navigator.of(context).pop(),
//                   ),
//                 ],
//               ),
//               // const SizedBox(height: 40),
//
//               // ---------------- VOLUME CONTROL ----------------
//               Expanded(
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     SizedBox(
//                       // height: AppSizeHeight.s15,
//                       child: Icon(
//                         size: AppSizeHeight.s12,
//                         _volume == 0 ? Icons.volume_off : Icons.volume_up,
//                         color: ColorManager.darkBluPrimary,
//                       ),
//                     ),
//                     // const Text('Music Volume'),
//                     Padding(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: AppSizeWidth.s5,
//                       ),
//                       child: SizedBox(
//                         width: AppSizeWidth.s62,
//                         child: Slider(
//                           activeColor: ColorManager.gold,
//                           inactiveColor: Colors.grey,
//                           value: _volume,
//                           min: 0,
//                           max: 1,
//                           divisions: 10,
//                           label: '${(_volume * 100).round()}%',
//                           onChanged: (value) {
//                             setState(() => _volume = value);
//                             widget.player.setVolume(value);
//                             widget.onVolumeChanged(value);
//                           },
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // ---------------- LANGUAGE ----------------
//               // NEW: pick the app language; the choice is remembered.
//               _languageSection(context),
//               SizedBox(height: AppSizeHeight.s2),
//
//               Center(
//                 child: SizedBox(
//                   height: AppSizeHeight.s10,
//                   width: double.infinity,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Text(
//                         tr('contact_us'),
//                         // 'Contact us',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       SizedBox(width: AppSizeWidth.s5),
//                       IconButton(
//                         onPressed: () =>
//                             _launchEmail(context, 'elsayedryan36@gmail.com'),
//                         icon: Icon(
//                           Icons.email_rounded,
//                           color: ColorManager.gold,
//                           size: AppSizeHeight.s10,
//                         ),
//                       ),
//                       SizedBox(width: AppSizeWidth.s8),
//                       IconButton(
//                         onPressed: () =>
//                             _launchWhatsApp(context, '201028103777', ''),
//                         icon: FaIcon(
//                           FontAwesomeIcons.whatsapp,
//                           color: ColorManager.gold,
//                           size: AppSizeHeight.s10,
//                         ),
//                       ),
//                       SizedBox(width: AppSizeWidth.s15),
//                     ],
//                   ),
//                 ),
//               ),
//
//               Padding(
//                 padding: EdgeInsets.symmetric(vertical: AppSizeHeight.s5),
//                 child: const RateAppWidget(),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// Launch Email with Subject & Body with enhanced error handling
//   static Future<void> _launchEmail(BuildContext context, String email) async {
//     final Uri emailUri = Uri(
//       scheme: 'mailto',
//       path: email,
//       queryParameters: {'subject': 'Fun Painting App Inquiry'},
//     );
//
//     try {
//       await launchUrl(emailUri, mode: LaunchMode.externalApplication);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(tr('cannot_open_email'))));
//       // ).showSnackBar(const SnackBar(content: Text('Cannot open email app')));
//     }
//   }
//
//   /// Show dialog when no email client is available
//
//   /// Launch WhatsApp Message with international number support
//   static Future<void> _launchWhatsApp(
//     BuildContext context,
//     String phoneNumber,
//     String message,
//   ) async {
//     final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
//
//     final uri = Uri.parse(
//       "https://wa.me/$cleanedNumber?text=${Uri.encodeComponent(message)}",
//     );
//
//     try {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(tr('cannot_open_whatsapp'))));
//       // ).showSnackBar(const SnackBar(content: Text('Cannot open WhatsApp')));
//     }
//   }
// }

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
