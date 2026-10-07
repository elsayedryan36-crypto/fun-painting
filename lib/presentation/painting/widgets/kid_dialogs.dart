import 'package:flutter/material.dart';

import '../../common/resources/color_manager.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🧽', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 6),
              Text(
                'Erase everything?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: ColorManager.darkPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'All the colours and drawings on this page will be gone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, height: 1.3),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _KidDialogButton(
                      label: 'Keep painting',
                      icon: Icons.brush_rounded,
                      onTap: () => Navigator.of(dialogContext).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KidDialogButton(
                      label: 'Erase all',
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
    final background = danger ? const Color(0xFFE53935) : ColorManager.gold;
    final foreground = danger ? Colors.white : ColorManager.darkPrimary;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 68,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 22),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
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
