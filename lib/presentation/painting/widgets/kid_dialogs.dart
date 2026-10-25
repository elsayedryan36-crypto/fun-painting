import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/common/localization/app_language.dart';

import '../../common/resources/color_manager.dart';
import 'package:fun_painting/presentation/common/resources/values_manager.dart';

/// ✅ NEW (kid-ui): the "erase everything?" confirmation.
///
/// The clear button used to wipe the whole page the moment it was touched —
/// it sat right next to the eraser, and there was nothing to undo it with. The
/// child now gets one big readable question with two big buttons, and the safe
/// answer ("Keep painting") is the emphasised one.
///
/// Returns `true` only when the child really picked "Erase all"; dismissing the
/// dialog by tapping outside counts as "no".
Future<bool> showClearAllDialog(BuildContext context) async {
  final answer = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPx.p28),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppPx.p20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🧽', style: TextStyle(fontSize: AppPx.p44)),
              SizedBox(height: AppPx.p6),
              Text(
                tr('erase_everything_q'),
                // 'Erase everything?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppPx.p26,
                  fontWeight: FontWeight.w800,
                  color: ColorManager.darkPrimary,
                ),
              ),
              SizedBox(height: AppPx.p8),
              Text(
                tr('erase_body'),
                // 'All the colours and drawings on this page will be gone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: AppPx.p18, height: 1.3),
              ),
              SizedBox(height: AppPx.p18),
              Row(
                children: [
                  Expanded(
                    child: _KidDialogButton(
                      label: tr('keep_painting'),
                      // label: 'Keep painting',
                      icon: Icons.brush_rounded,
                      onTap: () => Navigator.of(dialogContext).pop(false),
                    ),
                  ),
                  SizedBox(width: AppPx.p12),
                  Expanded(
                    child: _KidDialogButton(
                      label: tr('erase_all'),
                      // label: 'Erase all',
                      icon: Icons.delete_forever_rounded,
                      danger: true,
                      onTap: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  return answer ?? false;
}

/// One half of the dialog: a full-width, 68 dp tall, kid-sized button.
class _KidDialogButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool danger;
  final VoidCallback onTap;

  const _KidDialogButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = danger ? ColorManager.hexFFE53935 : ColorManager.gold;
    final foreground = danger ? ColorManager.white : ColorManager.darkPrimary;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppPx.p20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppPx.p20),
          child: Container(
            height: AppPx.p68,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: AppPx.p8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: AppPx.p22),
                SizedBox(width: AppPx.p6),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppPx.p19,
                      fontWeight: FontWeight.w800,
                      color: foreground,
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
