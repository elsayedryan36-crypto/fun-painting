import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/common/resources/values_manager.dart';
import 'package:fun_painting/presentation/common/resources/color_manager.dart';

class TopBar extends StatelessWidget {
  final String title;

  const TopBar({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: AppPx.p100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).shadowColor,
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppPx.p20, AppPx.p50, AppPx.p20, 0),
        child: Text(
          title,
          style: TextStyle(
            color: ColorManager.white,
            fontSize: AppPx.p26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
