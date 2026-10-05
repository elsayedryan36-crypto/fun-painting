import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:fun_painting/app/app_pref.dart';
import 'package:fun_painting/data/local%20data/coloring_save_model.dart';
import 'package:fun_painting/data/local%20data/hive.dart';
import 'package:fun_painting/data/local%20data/painting_save_model.dart'
    show
        SavedStrokeAdapter,
        SavedRegionAdapter,
        PaintingSaveAdapter,
        PaintingSave;
import 'package:fun_painting/data/services/ad_request_config.dart';
import 'package:fun_painting/presentation/common/services/sound_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../bloc_observer.dart';

Future<void>? appInitialization;

bool _adaptersRegistered = false;

void startAppInitialization() {
  appInitialization ??= _initializeApp();
}

Future<void> _initializeApp() async {
  try {
    debugPrint('==============================');
    debugPrint('APP INITIALIZATION STARTED');
    debugPrint('==============================');

    // ---------------------------------------
    // 1. App Preferences
    // ---------------------------------------
    await AppPreferences().init();

    debugPrint('AppPreferences initialized');

    // ---------------------------------------
    // 2. Hive
    // ---------------------------------------
    await Hive.initFlutter();

    debugPrint('Hive initialized');

    // Register adapters only once
    if (!_adaptersRegistered) {
      Hive.registerAdapter(DrawingModelAdapter());
      Hive.registerAdapter(ColoringSaveModelAdapter());
      Hive.registerAdapter(RegionSaveModelAdapter());
      Hive.registerAdapter(StrokeSaveModelAdapter());
      Hive.registerAdapter(SavedStrokeAdapter());
      Hive.registerAdapter(SavedRegionAdapter());
      Hive.registerAdapter(PaintingSaveAdapter());

      _adaptersRegistered = true;

      debugPrint('Hive adapters registered');
    }

    // ---------------------------------------
    // 3. Open Hive boxes
    // ---------------------------------------
    if (!Hive.isBoxOpen("drawings")) {
      await Hive.openBox<DrawingModel>("drawings");
    }

    if (!Hive.isBoxOpen("painting_save")) {
      await Hive.openBox<ColoringSaveModel>("painting_save");
    }

    if (!Hive.isBoxOpen("paintings")) {
      await Hive.openBox<PaintingSave>("paintings");
    }

    debugPrint('Hive boxes opened');

    // ---------------------------------------
    // 4. Bloc observer
    // ---------------------------------------
    Bloc.observer = AppBlocObserver();

    debugPrint('Bloc observer initialized');

    // ---------------------------------------
    // 5. Sound service
    // ---------------------------------------
    await BrushSoundService.instance.initialize();

    debugPrint('Sound service initialized');

    // ---------------------------------------
    // 6. Google Mobile Ads
    // ---------------------------------------
    try {
      await MobileAds.instance.initialize();

      await AdRequestConfig.applyGlobalChildDirectedSettings();

      debugPrint('Google Mobile Ads initialized');
    } catch (e, stackTrace) {
      // Ads should NOT prevent the app from opening.
      debugPrint('Google Mobile Ads initialization failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    debugPrint('==============================');
    debugPrint('APP INITIALIZATION COMPLETED');
    debugPrint('==============================');
  } catch (e, stackTrace) {
    debugPrint('==============================');
    debugPrint('APP INITIALIZATION FAILED');
    debugPrint('Error: $e');
    debugPrint('==============================');

    debugPrintStack(stackTrace: stackTrace);

    // Re-throw because Hive / Preferences are essential.
    rethrow;
  }
}
