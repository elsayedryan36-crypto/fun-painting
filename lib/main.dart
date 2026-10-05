// import 'package:bloc/bloc.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fun_painting/app/app_pref.dart';
// import 'package:fun_painting/data/local%20data/coloring_save_model.dart';
// import 'package:fun_painting/data/local%20data/hive.dart';
// import 'package:fun_painting/data/local%20data/painting_save_model.dart'
//     show
//         SavedStrokeAdapter,
//         SavedRegionAdapter,
//         PaintingSaveAdapter,
//         PaintingSave;
// import 'package:fun_painting/data/services/ad_request_config.dart';
// import 'package:fun_painting/presentation/common/resources/color_manager.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:sizer/sizer.dart';

// import 'app/app.dart';
// import 'app/bloc_observer.dart';
// import 'presentation/common/services/sound_service.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Lock orientation first
//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.landscapeLeft,
//     DeviceOrientation.landscapeRight,
//   ]);

//   // System UI
//   await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

//   SystemChrome.setSystemUIOverlayStyle(
//     SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.dark,
//       systemNavigationBarColor: Colors.transparent,
//       statusBarBrightness: Brightness.light,
//       systemNavigationBarDividerColor: ColorManager.lightYellow,
//       systemNavigationBarIconBrightness: Brightness.light,
//     ),
//   );

//   // Ads
//   await MobileAds.instance.initialize();
//   await AdRequestConfig.applyGlobalChildDirectedSettings();

//   // Preferences
//   await AppPreferences().init();

//   // Hive
//   await Hive.initFlutter();

//   Hive.registerAdapter(DrawingModelAdapter());
//   Hive.registerAdapter(ColoringSaveModelAdapter());
//   Hive.registerAdapter(RegionSaveModelAdapter());
//   Hive.registerAdapter(StrokeSaveModelAdapter());
//   Hive.registerAdapter(SavedStrokeAdapter());
//   Hive.registerAdapter(SavedRegionAdapter());
//   Hive.registerAdapter(PaintingSaveAdapter());

//   await Hive.openBox<DrawingModel>("drawings");
//   await Hive.openBox<ColoringSaveModel>("painting_save");
//   await Hive.openBox<PaintingSave>("paintings");

//   // Sound
//   await BrushSoundService.instance.initialize();

//   // Bloc
//   Bloc.observer = AppBlocObserver();

//   // Start app
//   runApp(
//     Sizer(
//       builder: (context, orientation, deviceType) {
//         return MyApp();
//       },
//     ),
//   );
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fun_painting/app/lib/app/app_initializer.dart';
import 'package:fun_painting/presentation/common/resources/color_manager.dart';
import 'package:sizer/sizer.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      systemNavigationBarDividerColor: ColorManager.lightYellow,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Start initialization in the background.
  // We do NOT await it here, so Flutter can show the SplashScreen immediately.
  startAppInitialization();

  runApp(
    Sizer(
      builder: (context, orientation, deviceType) {
        return MyApp();
      },
    ),
  );
}
