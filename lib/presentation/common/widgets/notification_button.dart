import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/common/resources/values_manager.dart';
import 'package:fun_painting/presentation/common/resources/color_manager.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({
    required this.onPressed,
    required this.text,
    super.key,
  });

  final VoidCallback onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppPx.p30_0,
        right: AppPx.p30_0,
        top: AppPx.p10,
        bottom: AppPx.p10,
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: AppPx.p50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shadowColor: Theme.of(context).shadowColor,
            backgroundColor: Theme.of(context).primaryColor,
          ),
          onPressed: onPressed,
          child: Text(text, style: const TextStyle(color: ColorManager.white)),
        ),
      ),
    );
  }
}
