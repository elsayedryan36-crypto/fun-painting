import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../presentation/common/localization/app_language.dart';
import '../presentation/common/resources/routs_manager.dart';
import '../presentation/common/resources/theme_manager.dart';

class MyApp extends StatefulWidget {
  const MyApp._internal();
  static const MyApp _instance = MyApp._internal();
  factory MyApp() => _instance;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int appState = 0;
  @override
  Widget build(BuildContext context) {
    // NEW: the whole app follows the chosen language (RTL for Arabic included).
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.current,
      builder: (context, languageCode, _) {
        return MaterialApp(
          locale: Locale(languageCode),
          supportedLocales: AppLanguage.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          initialRoute: Routes.splashRoute,
          debugShowCheckedModeBanner: false,
          theme: getApplicationTheme(),
          onGenerateRoute: RouteGenerator.getRoute,
        );
      },
    );
  }
}

// OLD (before the language picker — kept commented per the rule):
// import 'package:flutter/material.dart';
//
// import '../presentation/common/resources/routs_manager.dart';
// import '../presentation/common/resources/theme_manager.dart';
//
// class MyApp extends StatefulWidget {
//   const MyApp._internal();
//   static const MyApp _instance = MyApp._internal();
//   factory MyApp() => _instance;
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   int appState = 0;
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       // localizationsDelegates: context.localizationDelegates,
//       // supportedLocales: context.supportedLocales,
//       // locale: context.locale,
//       initialRoute: Routes.splashRoute,
//       debugShowCheckedModeBanner: false,
//       theme: getApplicationTheme(),
//       onGenerateRoute: RouteGenerator.getRoute,
//     );
//   }
// }
