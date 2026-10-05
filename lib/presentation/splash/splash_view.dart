// import 'dart:async';

// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
// import 'package:rive/rive.dart' hide Image;

// import '../common/resources/assets_manager.dart';
// import '../common/resources/color_manager.dart';
// import '../common/resources/routs_manager.dart';
// import '../common/resources/values_manager.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   // ignore: library_private_types_in_public_api
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin, WidgetsBindingObserver {
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;

//   Timer? _timer;
//   final AudioPlayer _player = AudioPlayer();
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused ||
//         state == AppLifecycleState.inactive ||
//         state == AppLifecycleState.detached) {
//       _player.pause();
//     } else if (state == AppLifecycleState.resumed) {
//       _player.resume();
//     }
//   }

//   Future<void> _playBackgroundMusic() async {
//     await _player.setAudioContext(
//       AudioContext(
//         android: AudioContextAndroid(
//           isSpeakerphoneOn: false,
//           stayAwake: false,
//           contentType: AndroidContentType.music,
//           usageType: AndroidUsageType.media,
//           audioFocus: AndroidAudioFocus.none,
//         ),
//       ),
//     );
//     await _player.setReleaseMode(ReleaseMode.loop);
//     await _player.setVolume(0.08);
//     await _player.play(AssetSource('sounds/main.mp3'));
//   }

//   void _startDelay() {
//     _timer = Timer(const Duration(seconds: 2), _goNext);
//   }

//   Future<void> _goNext() async {
//     // Navigator.pushReplacementNamed(context, Routes.homeRoute);homeRoute
//     // _appPreferences.getkIsFirstTime()
//     //     ? {Navigator.pushReplacementNamed(context, Routes.onBoardingRoute)}
//     //     : {Navigator.pushReplacementNamed(context, Routes.homeRoute)};
//   }
//   final List<RiveAnimationController> _controllers = [];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _playBackgroundMusic();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 1), // total animation time
//     );

//     // Fade from 0 (invisible) to 1 (fully visible)
//     _fadeAnimation = Tween<double>(
//       begin: 0,
//       end: 1,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

//     // Scale from 0.5 (half size) to 1.0 (normal size)
//     _scaleAnimation = Tween<double>(
//       begin: 0.5,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

//     _controller.forward(); // Start animation automatically
//     _startDelay();
//     _controllers.add(SimpleAnimation('hand', autoplay: true));
//     _controllers.add(SimpleAnimation('dragon', autoplay: true));
//     _controllers.add(SimpleAnimation('body', autoplay: true));
//     _controllers.add(SimpleAnimation('brush', autoplay: true));
//     _controllers.add(SimpleAnimation('hair', autoplay: true));
//     _controllers.add(SimpleAnimation('wing', autoplay: true));
//     _controllers.add(SimpleAnimation('eye', autoplay: true));
//     _controllers.add(SimpleAnimation('tail', autoplay: true));
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     WidgetsBinding.instance.removeObserver(this);

//     _controller.dispose();
//     _player.stop();
//     _player.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: ColorManager.primary,
//       body: Center(
//         child: Stack(
//           children: [
//             Image.asset(
//               ImageAssets.background,
//               width: double.infinity,
//               height: double.infinity,
//               fit: BoxFit.cover,
//             ),
//             Container(
//               child: Lottie.asset(
//                 JsonAssets.leaves,
//                 width: AppSizeWidth.s100,
//                 height: AppSizeHeight.s100,
//               ),
//             ),
//             Center(
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   FadeTransition(
//                     opacity: _fadeAnimation,
//                     child: ScaleTransition(
//                       scale: _scaleAnimation,
//                       child: SizedBox(
//                         width: AppSizeWidth.s60,
//                         height: AppSizeHeight.s100,
//                         child: Transform(
//                           alignment: Alignment.center,
//                           transform: Matrix4.identity()
//                             ..scale(-1.0, 1.0), // horizontal + vertical flip
//                           child: RiveAnimation.asset(
//                             ImageAssets.dragon,
//                             artboard: 'dragon',
//                             controllers: _controllers,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.pushReplacementNamed(context, Routes.homeRoute);
//                     },
//                     child: Container(
//                       child: Lottie.asset(
//                         JsonAssets.start,
//                         width: AppSizeWidth.s30,
//                         height: AppSizeHeight.s100,
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: AppPaddingWidth.p8),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:rive/rive.dart' hide Image;

import 'package:fun_painting/app/lib/app/app_initializer.dart';
import '../common/resources/assets_manager.dart';
import '../common/resources/color_manager.dart';
import '../common/resources/routs_manager.dart';
import '../common/resources/values_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final AudioPlayer _player = AudioPlayer();

  final List<RiveAnimationController> _controllers = [];

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // Start splash music.
    _playBackgroundMusic();

    // ---------------------------------------
    // Main splash animation
    // ---------------------------------------
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();

    // ---------------------------------------
    // Rive animations
    // ---------------------------------------
    _controllers.add(SimpleAnimation('hand', autoplay: true));

    _controllers.add(SimpleAnimation('dragon', autoplay: true));

    _controllers.add(SimpleAnimation('body', autoplay: true));

    _controllers.add(SimpleAnimation('brush', autoplay: true));

    _controllers.add(SimpleAnimation('hair', autoplay: true));

    _controllers.add(SimpleAnimation('wing', autoplay: true));

    _controllers.add(SimpleAnimation('eye', autoplay: true));

    _controllers.add(SimpleAnimation('tail', autoplay: true));

    // ---------------------------------------
    // Wait for app initialization
    // ---------------------------------------
    _waitForAppInitialization();
  }

  // ============================================================
  // Background music
  // ============================================================

  Future<void> _playBackgroundMusic() async {
    try {
      await _player.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );

      await _player.setReleaseMode(ReleaseMode.loop);

      await _player.setVolume(0.08);

      await _player.play(AssetSource('sounds/main.mp3'));
    } catch (e) {
      debugPrint('Splash music error: $e');
    }
  }

  // ============================================================
  // Wait for application initialization
  // ============================================================

  Future<void> _waitForAppInitialization() async {
    try {
      final initialization = appInitialization;

      if (initialization != null) {
        await initialization;
      }

      if (!mounted) return;

      // Small delay so the splash animation doesn't disappear
      // immediately on very fast devices.
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      await _goNext();
    } catch (e, stackTrace) {
      debugPrint('Application initialization failed: $e');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      // We don't navigate to Home if essential initialization failed.
      // Keep the splash visible instead of opening a broken Home screen.
    }
  }

  // ============================================================
  // Navigate to Home
  // ============================================================

  Future<void> _goNext() async {
    // Prevent multiple navigation calls.
    if (!mounted || _isNavigating) {
      return;
    }

    _isNavigating = true;

    Navigator.pushReplacementNamed(context, Routes.homeRoute);
  }

  // ============================================================
  // App lifecycle
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _player.pause();
    } else if (state == AppLifecycleState.resumed) {
      _player.resume();
    }
  }

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _controller.dispose();

    _player.stop();
    _player.dispose();

    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.primary,
      body: Center(
        child: Stack(
          children: [
            // ---------------------------------------
            // Background
            // ---------------------------------------
            Image.asset(
              ImageAssets.background,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),

            // ---------------------------------------
            // Leaves animation
            // ---------------------------------------
            Lottie.asset(
              JsonAssets.leaves,
              width: AppSizeWidth.s100,
              height: AppSizeHeight.s100,
            ),

            // ---------------------------------------
            // Dragon + Start animation
            // ---------------------------------------
            Center(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // -----------------------------------
                  // Dragon
                  // -----------------------------------
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SizedBox(
                        width: AppSizeWidth.s60,
                        height: AppSizeHeight.s100,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..scale(-1.0, 1.0),
                          child: RiveAnimation.asset(
                            ImageAssets.dragon,
                            artboard: 'dragon',
                            controllers: _controllers,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // -----------------------------------
                  // Start animation
                  //
                  // NOT clickable.
                  // Navigation happens automatically
                  // after app initialization.
                  // -----------------------------------
                  // IgnorePointer(
                  //   ignoring: true,
                  //   child: Lottie.asset(
                  //     JsonAssets.start,
                  //     width: AppSizeWidth.s30,
                  //     height: AppSizeHeight.s100,
                  //   ),
                  // ),
                  SizedBox(width: AppPaddingWidth.p8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
