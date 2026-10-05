import 'package:flutter/material.dart';

import '../resources/color_manager.dart';
import '../resources/font_manager.dart';
import '../resources/styles_manager.dart';
import '../resources/values_manager.dart';

// ignore: must_be_immutable
class DefaultButton extends StatelessWidget {
  DefaultButton({
    super.key,
    this.width = .3,
    // this.backGroundColor = Colors.white,
    required this.textColor,
    this.fontSize = .02,
    this.elevation = 0,
    this.borderRadius,
    this.fontFamily = 'SourceSansPro',
    this.fontWeight = FontWeight.bold,
    this.isUpperCase = true,
    required this.function,
    required this.text,
  });

  final double width;
  // final Color backGroundColor;
  final Color textColor;
  final double fontSize;
  final double elevation;
  double? borderRadius = AppSizeHeight.s60;
  final String fontFamily;
  final FontWeight fontWeight;
  final bool isUpperCase;
  final VoidCallback? function;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizeHeight.s0),
        // color: backGroundColor,
      ),
      child: ElevatedButton(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            EdgeInsets.all(
              AppSizeHeight.s1_5,
            ),
          ),
        ),
        onPressed: function,
        child: Text(isUpperCase ? text.toUpperCase() : text,
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(color: textColor)),
      ),
    );
  }
}

///////////////////////////////////////////////////////////

class DefaultFormFiled extends StatelessWidget {
  const DefaultFormFiled({
    super.key,
    required this.textType,
    required this.prefixIcon,
    required this.onSaved,
    required this.hintText,
    required this.labelText,
    required this.validator,
    required this.inputType,
    required this.suffixIcon,
    required this.textController,
    this.isPassword = false,
    required this.suffixPressed,
    // this.errorTextBelow,
    required this.onTap,
    this.errorText,
  });
  final TextEditingController? textController;
  final TextInputType textType;
  final Function? onSaved;
  final Function? validator;
  final String? labelText;
  final String? errorText;
  // final String? errorTextBelow;

  final String? hintText;
  final TextInputType inputType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final Function? suffixPressed;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppPaddingHeight.p2),
      child: Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizeHeight.s1),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black26,
          //     blurRadius: AppSizeHeight.s1,
          //     offset: Offset(0, 0),
          //   )
          // ],
        ),
        child: Column(
          children: [
            TextFormField(
              cursorColor: ColorManager.primary,
              onTap: onTap(),
              controller: textController,
              // style: TextStyle(fontSize: FontSize.s2),
              keyboardType: inputType,
              decoration: InputDecoration(
                filled: true,
                fillColor: ColorManager.white,
                labelText: labelText,
                labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                contentPadding: EdgeInsets.only(top: AppSizeHeight.s2),
                errorText: errorText,
                hintText: hintText,
                hintStyle: const TextStyle(
                    // color: Colors.black38,
                    ),
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon != null
                    ? IconButton(
                        onPressed: () => suffixPressed!(),
                        icon: suffixIcon as Widget,
                      )
                    : null,
                border: InputBorder.none,
              ),
              key: key,
              validator: (value) => validator!(value).toString(),
              onSaved: (newValue) => onSaved!(newValue),
              obscureText: isPassword,
            ),
            // Text(
            //   errorTextBelow!,
            //   style: Theme.of(context).textTheme.bodySmall,
            // )
          ],
        ),
      ),
    );
  }
}

///////////////////////////////////////////////////////////

class DefaultSeparator extends StatelessWidget {
  const DefaultSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 0.0,
      ),
      child: Container(
        width: double.infinity,
        height: 1.0,
        color: Colors.grey[300],
      ),
    );
  }
}

////////////////////////////
class DefaultIcon extends StatelessWidget {
  final IconData icons;
  final Color color;
  final String text;
  final Function onTap;

  const DefaultIcon({
    super.key,
    required this.icons,
    required this.color,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(
              icons,
              // semanticLabel: "Help",
              size: 29,
              color: Colors.white,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              // fontWeight: FontWeight.w100,
            ),
          )
        ],
      ),
    );
  }
}

/////////////////////////////////////////
// class DefaultMenuItem extends StatelessWidget {
//   DefaultMenuItem({Key? key}) : super(key: key);
//   final AuthController userAuth = Get.put(AuthController());
//
//   final UserData userData = Get.put(UserData());
//
//   @override
//   Widget build(BuildContext context) {
//     return PopupMenuButton<MenuItem>(
//       onSelected: (item) => onSelected(item),
//       itemBuilder: (context) => [
//         ...MenuItems.itemsFirst.map(buildItem).toList(),
//         const PopupMenuItem(
//           height: 1,
//           onTap: null,
//           enabled: false,
//           child: PopupMenuDivider(
//             height: 5,
//           ),
//         ),
//         ...MenuItems.itemsSecond.map(buildItem).toList(),
//       ],
//     );
//   }
//
//   PopupMenuItem<MenuItem> buildItem(MenuItem item) => PopupMenuItem<MenuItem>(
//     value: item,
//     child: Row(
//       children: [
//         Icon(item.icon),
//         const SizedBox(
//           width: 5,
//         ),
//         Text(item.text),
//       ],
//     ),
//   );
//   void onSelected(MenuItem item) {
//     switch (item) {
//       case MenuItems.itemSetting:
//         break;
//       case MenuItems.itemTheme:
//         break;
//       case MenuItems.itemSignOut:
//         getDialog();
//         break;
//     }
//   }
// }

/////////////////////////
class DefaultLAlertDialog extends StatelessWidget {
  const DefaultLAlertDialog(
      {super.key,
      required this.title,
      required this.content,
      required this.widgets,
      required this.bordersShape,
      required this.backGroundColor});
  final String title;
  final String content;
  final List<Widget> widgets;
  final ShapeBorder bordersShape;
  final Color backGroundColor;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: widgets,
      shape: bordersShape,
      backgroundColor: backGroundColor,
    );
  }
}

////////////////////////////////////////////////
// Future<void> getDialog() async {
//   final AuthController userAuth = Get.put(AuthController());
//   final UserData userData = Get.put(UserData());
//
//   Get.defaultDialog(
//       title: 'Log out?',
//       content: const Text('Are you sure you want to log out?'),
//       backgroundColor: const Color(0xff731573),
//       actions: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             TextButton(
//               style: TextButton.styleFrom(
//                 primary: Colors.white,
//               ),
//               onPressed: () {
//                 Get.back();
//               },
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               style: TextButton.styleFrom(
//                 primary: Colors.red,
//               ),
//               onPressed: () {
//                 userAuth.signOut();
//                 userData.isLoading(false);
//               },
//               child: const Text('Log out'),
//             )
//           ],
//         )
//       ]);
// }
//////////////////////////////////////////////
//
// class DefaultReadMoreText extends StatelessWidget {
//   const DefaultReadMoreText(
//       {Key? key, required this.text, required this.isReadMore})
//       : super(key: key);
//   // bool datatype to give toggle effect to button and
//   // depending on this bool value will show full text or
//   // limit the number of line to be viewed in text.
//   final bool isReadMore;
//   final String text;
//   @override
//   Widget build(BuildContext context) {
//     return TextSpan(
//       children: ,
//       style: const TextStyle(fontSize: 25),
//       maxLines: isReadMore ? null : 3,
//       // overflow properties is used to show 3 dot in text widget
//       // so that user can understand there are few more line to read.
//       overflow: isReadMore ? TextOverflow.visible : TextOverflow.ellipsis,
//     );
//   }
// }

class DefaultTextButton extends StatelessWidget {
  DefaultTextButton(
      {super.key,
      this.style,
      required this.function,
      required this.text,
      this.textAlign});

  final Color? textColor = ColorManager.white;
  final VoidCallback function;
  final String text;
  final TextAlign? textAlign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: function,
      child: Text(
        text,
        textAlign: textAlign,
        style: style ??
            Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: ColorManager.white, fontSize: FontSize.s12),
      ),
    );
  }
}

class ButtonWidget extends StatelessWidget {
  ButtonWidget(
    this.textHeight, {
    super.key,
    required this.function,
    required this.height,
    required this.width,
    required this.text,
    required this.color,
  });

  final Future<void> Function() function;
  final double height;
  final double width;
  final String text;
  final Color color;
  final double textHeight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        function();
      },
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSizeHeight.s1),
        ),
        child: Center(
          child: Text(
            text,
            style: getBoldStyle(
              fontSize: textHeight,
              color: ColorManager.darkPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
