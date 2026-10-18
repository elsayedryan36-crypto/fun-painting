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

import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:fun_painting/app/app_pref.dart';
import 'package:fun_painting/presentation/common/localization/app_language.dart';
import 'package:lottie/lottie.dart';
import 'package:rive/rive.dart' hide Image, LinearGradient;

import 'package:fun_painting/app/lib/app/app_initializer.dart';
import '../common/resources/assets_manager.dart';
import '../common/resources/color_manager.dart';
import '../common/resources/routs_manager.dart';
import '../common/resources/values_manager.dart';

class SplashScreen extends StatefulWidget {
  /// Widget-test seam only: flutter_tester has no Rive native runtime, so
  /// tests pass a stand-in for the dragon. In production this is always
  /// null and the real .riv plays.
  final Widget? dragonOverride;

  const SplashScreen({super.key, this.dragonOverride});

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

      await _player.setVolume(
        AppPreferences().getKMusicVolume(),
      ); // NEW: music level from Sound levels
      // (old)       await _player.setVolume(0.08);

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

  // ============================================================
  // Mute sticker (parents, first screen)
  // ============================================================

  bool _muted = false;

  /// True while the confetti burst plays over the meadow.
  bool _confetti = false;

  Future<void> _toggleMute() async {
    setState(() => _muted = !_muted);
    await _player.setVolume(
      _muted ? 0 : AppPreferences().getKMusicVolume(),
    ); // NEW
    // (old)     await _player.setVolume(_muted ? 0 : 0.08);
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // NEW (the Paint Splash, option D): a clean white canvas with bright
    // paint splats, the mascot on a tilted white card at the left, and the
    // dragon above a bubbly pink PLAY drop at the right. Tapping PLAY bursts
    // confetti before home opens.
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF8),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // paint splats in the four corners
          Positioned(
            left: -40,
            top: -40,
            child: _splat(const Color(0xFFFFB020), 190, 170),
          ),
          Positioned(
            right: -30,
            top: -30,
            child: _splat(const Color(0xFF3EC6E0), 180, 160),
          ),
          Positioned(
            left: -30,
            bottom: -40,
            child: _splat(const Color(0xFF7ED957), 220, 170),
          ),
          Positioned(
            right: -20,
            bottom: -30,
            child: _splat(const Color(0xFFB983FF), 180, 150),
          ),

          // the mascot card, the dragon and the PLAY drop
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _mascotCard(),
                  ),
                ),
                const SizedBox(width: 48),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: math.max(140, AppSizeWidth.s26),
                      height: math.max(150, AppSizeHeight.s38),
                      child:
                          widget.dragonOverride ??
                          RiveAnimation.asset(
                            ImageAssets.dragon,
                            artboard: 'dragon',
                            controllers: _controllers,
                          ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _playAndGo,
                      child: _Bouncy(
                        child: Container(
                          width: math.max(200, AppSizeWidth.s26),
                          height: math.max(64, AppSizeHeight.s12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4F8B),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFC2295F),
                                offset: Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Text(
                            '▶  ${tr('play')}',
                            style: TextStyle(
                              color: ColorManager.white,
                              fontWeight: FontWeight.w900,
                              fontSize: math.max(22, AppSizeHeight.s5),
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // the confetti burst when PLAY is tapped
          if (_confetti)
            Positioned.fill(
              child: IgnorePointer(
                child: Lottie.asset(JsonAssets.confetti, fit: BoxFit.cover),
              ),
            ),

          // mute sticker, top-right
          Positioned(
            top: AppSizeHeight.s3,
            right: AppSizeWidth.s3,
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                width: math.max(48, AppSizeWidth.s9),
                height: math.max(48, AppSizeHeight.s12),
                decoration: BoxDecoration(
                  color: ColorManager.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _muted ? '🔇' : '🔊',
                    style: TextStyle(fontSize: math.max(18, AppSizeHeight.s5)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The mascot on a slightly tilted white card with a hard, paint-like shadow.
  Widget _mascotCard() {
    return Transform.rotate(
      angle: -0.035,
      child: Container(
        padding: const EdgeInsets.fromLTRB(26, 18, 26, 14),
        decoration: BoxDecoration(
          color: ColorManager.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: const [
            BoxShadow(color: Color(0xFFE9E2D2), offset: Offset(0, 10)),
            BoxShadow(
              color: Color(0x2E3C321E),
              blurRadius: 26,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/app_icon.png',
          height: math.max(170, AppSizeHeight.s38),
        ),
      ),
    );
  }

  /// One organic paint splat: a blob with uneven elliptical corners.
  Widget _splat(Color color, double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.elliptical(w * 0.45, h * 0.55),
          topRight: Radius.elliptical(w * 0.4, h * 0.45),
          bottomRight: Radius.elliptical(w * 0.5, h * 0.4),
          bottomLeft: Radius.elliptical(w * 0.45, h * 0.6),
        ),
      ),
    );
  }

  // Meadow (option B) — kept commented beneath the Paint Splash, per the rule:
  //     // NEW (the Meadow, option B): sky over grass with two soft hills,
  //     // the dragon standing on the grass at the left, and at the right the
  //     // wordmark + a promise chip + one fat PLAY pill. Tapping PLAY bursts
  //     // confetti before home opens.
  //     return Scaffold(
  //       backgroundColor: ColorManager.primary,
  //       body: Stack(
  //         fit: StackFit.expand,
  //         children: [
  //           // sky into grass, one calm two-tone gradient
  //           Container(
  //             decoration: const BoxDecoration(
  //               gradient: LinearGradient(
  //                 begin: Alignment.topCenter,
  //                 end: Alignment.bottomCenter,
  //                 stops: [0, 0.58, 0.58, 1],
  //                 colors: [
  //                   Color(0xFFEAF6FF),
  //                   Color(0xFFF6FBFF),
  //                   Color(0xFFBFE3B4),
  //                   Color(0xFFA8D795),
  //                 ],
  //               ),
  //             ),
  //           ),
  //
  //           // two soft hills on the horizon
  //           Positioned(
  //             left: -80,
  //             bottom: -90,
  //             child: _hill(const Color(0xFFB4DDA4), 420, 200),
  //           ),
  //           Positioned(
  //             right: -90,
  //             bottom: -110,
  //             child: _hill(const Color(0xFFCBE8BC), 460, 220),
  //           ),
  //
  //           // two quiet clouds
  //           Positioned(
  //             top: AppSizeHeight.s6,
  //             left: AppSizeWidth.s8,
  //             child: _cloud(90),
  //           ),
  //           Positioned(
  //             top: AppSizeHeight.s13,
  //             left: AppSizeWidth.s40,
  //             child: _cloud(120),
  //           ),
  //
  //           // the meadow row: dragon on the grass left, wordmark right
  //           Row(
  //             crossAxisAlignment: CrossAxisAlignment.end,
  //             children: [
  //               Expanded(
  //                 flex: 115,
  //                 child: Align(
  //                   alignment: Alignment.bottomCenter,
  //                   child: Padding(
  //                     padding: EdgeInsets.only(
  //                       bottom: math.max(20, AppSizeHeight.s6),
  //                     ),
  //                     child: FadeTransition(
  //                       opacity: _fadeAnimation,
  //                       child: ScaleTransition(
  //                         scale: _scaleAnimation,
  //                         child: SizedBox(
  //                           width: math.max(160, AppSizeWidth.s35),
  //                           height: math.max(150, AppSizeHeight.s60),
  //                           child:
  //                               widget.dragonOverride ??
  //                               RiveAnimation.asset(
  //                                 ImageAssets.dragon,
  //                                 artboard: 'dragon',
  //                                 controllers: _controllers,
  //                               ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //               Expanded(
  //                 flex: 100,
  //                 child: Center(
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Image.asset(
  //                         'assets/images/app_icon.png',
  //                         height: math.max(110, AppSizeHeight.s38),
  //                       ),
  //                       SizedBox(height: math.max(8, AppSizeHeight.s2)),
  //                       Container(
  //                         padding: EdgeInsets.symmetric(
  //                           horizontal: AppPaddingWidth.p3,
  //                           vertical: AppPaddingHeight.p_5,
  //                         ),
  //                         decoration: BoxDecoration(
  //                           color: ColorManager.white,
  //                           borderRadius: BorderRadius.circular(99),
  //                           boxShadow: const [
  //                             BoxShadow(
  //                               color: Color(0x1F000000),
  //                               blurRadius: 7,
  //                               offset: Offset(0, 3),
  //                             ),
  //                           ],
  //                         ),
  //                         child: Text(
  //                           'Pick a world & colour!',
  //                           style: TextStyle(
  //                             color: const Color(0xFF4E7A3C),
  //                             fontWeight: FontWeight.w900,
  //                             fontSize: math.max(13, AppSizeHeight.s4),
  //                           ),
  //                         ),
  //                       ),
  //                       SizedBox(height: math.max(12, AppSizeHeight.s3)),
  //                       GestureDetector(
  //                         onTap: _playAndGo,
  //                         child: _Bouncy(
  //                           child: Container(
  //                             width: math.max(180, AppSizeWidth.s26),
  //                             height: math.max(56, AppSizeHeight.s15),
  //                             decoration: BoxDecoration(
  //                               gradient: LinearGradient(
  //                                 begin: Alignment.topCenter,
  //                                 end: Alignment.bottomCenter,
  //                                 colors: [Color(0xFFFFD54F), Color(0xFFFF9800)],
  //                               ),
  //                               borderRadius: BorderRadius.circular(99),
  //                               boxShadow: [
  //                                 BoxShadow(
  //                                   color: Color(0x66C86E00),
  //                                   offset: Offset(0, 6),
  //                                 ),
  //                                 BoxShadow(
  //                                   color: Color(0x4D000000),
  //                                   blurRadius: 14,
  //                                   offset: Offset(0, 10),
  //                                 ),
  //                               ],
  //                             ),
  //                             child: Center(
  //                               child: Text(
  //                                 '▶  PLAY',
  //                                 style: TextStyle(
  //                                   color: const Color(0xFF7A3C00),
  //                                   fontWeight: FontWeight.w900,
  //                                   fontSize: math.max(18, AppSizeHeight.s5),
  //                                   letterSpacing: 2,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //
  //           // the confetti burst when PLAY is tapped
  //           if (_confetti)
  //             Positioned.fill(
  //               child: IgnorePointer(
  //                 child: Lottie.asset(JsonAssets.confetti, fit: BoxFit.cover),
  //               ),
  //             ),
  //
  //           // mute sticker, top-right
  //           Positioned(
  //             top: AppSizeHeight.s3,
  //             right: AppSizeWidth.s3,
  //             child: GestureDetector(
  //               onTap: _toggleMute,
  //               child: Container(
  //                 width: math.max(48, AppSizeWidth.s9),
  //                 height: math.max(48, AppSizeHeight.s12),
  //                 decoration: BoxDecoration(
  //                   color: ColorManager.white,
  //                   shape: BoxShape.circle,
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Color(0x33000000),
  //                       blurRadius: 8,
  //                       offset: Offset(0, 3),
  //                     ),
  //                   ],
  //                 ),
  //                 child: Center(
  //                   child: Text(
  //                     _muted ? '🔇' : '🔊',
  //                     style: TextStyle(fontSize: math.max(18, AppSizeHeight.s5)),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  //
  //   /// One soft hill on the horizon.
  //   Widget _hill(Color color, double w, double h) {
  //     return Container(
  //       width: w,
  //       height: h,
  //       decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  //     );
  //   }
  //
  //   /// One quiet cloud.
  //   Widget _cloud(double w) {
  //     return Container(
  //       width: w,
  //       height: w * 0.32,
  //       decoration: BoxDecoration(
  //         color: ColorManager.white.withValues(alpha: 0.8),
  //         borderRadius: BorderRadius.circular(99),
  //       ),
  //     );
  //   }

  /// PLAY: burst the confetti, then open home.
  Future<void> _playAndGo() async {
    if (_isNavigating) return;
    setState(() => _confetti = true);
    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    await _goNext();
  }

  // OLD (round-15 splash build: sky jpg + leaves + top wordmark + centred
  // dragon + start.json circle button — kept commented per the rule):
  //     // NEW (splash plan): calm sky, the wordmark, ONE big un-mirrored
  //     // dragon, a real bouncy PLAY button, and a mute sticker.
  //     return Scaffold(
  //       backgroundColor: ColorManager.primary,
  //       body: Stack(
  //         fit: StackFit.expand,
  //         children: [
  //           // calm sky in the same family as the card backgrounds
  //           Image.asset(
  //             'assets/images/splash_bg.jpg',
  //             width: double.infinity,
  //             height: double.infinity,
  //             fit: BoxFit.cover,
  //           ),
  //
  //           // leaves, light, over the sky
  //           Opacity(
  //             opacity: 0.55,
  //             child: Lottie.asset(
  //               JsonAssets.leaves,
  //               width: AppSizeWidth.s100,
  //               height: AppSizeHeight.s100,
  //             ),
  //           ),
  //
  //           // the wordmark, big, at the top
  //           Positioned(
  //             top: AppSizeHeight.s4,
  //             left: 0,
  //             right: 0,
  //             child: Center(
  //               child: Image.asset(
  //                 'assets/images/app_icon.png',
  //                 height: math.max(70, AppSizeHeight.s24),
  //               ),
  //             ),
  //           ),
  //
  //           // the dragon: big, centred, facing the child (no mirror)
  //           Center(
  //             child: FadeTransition(
  //               opacity: _fadeAnimation,
  //               child: ScaleTransition(
  //                 scale: _scaleAnimation,
  //                 child: SizedBox(
  //                   width: AppSizeWidth.s55,
  //                   height: AppSizeHeight.s56,
  //                   child:
  //                       widget.dragonOverride ??
  //                       RiveAnimation.asset(
  //                         ImageAssets.dragon,
  //                         artboard: 'dragon',
  //                         controllers: _controllers,
  //                       ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //
  //           // the PLAY sticker — the old start.json, reborn as a button
  //           Positioned(
  //             bottom: AppSizeHeight.s6,
  //             left: 0,
  //             right: 0,
  //             child: Center(
  //               child: GestureDetector(
  //                 onTap: _goNext,
  //                 child: _Bouncy(
  //                   child: Container(
  //                     width: math.max(72, AppSizeWidth.s13),
  //                     height: math.max(72, AppSizeHeight.s18),
  //                     decoration: BoxDecoration(
  //                       color: ColorManager.gold,
  //                       shape: BoxShape.circle,
  //                       border: Border.all(color: ColorManager.white, width: 4),
  //                       boxShadow: const [
  //                         BoxShadow(
  //                           color: Color(0x4D000000),
  //                           blurRadius: 12,
  //                           offset: Offset(0, 6),
  //                         ),
  //                       ],
  //                     ),
  //                     child: Center(
  //                       child: Lottie.asset(
  //                         JsonAssets.start,
  //                         width: math.max(44, AppSizeWidth.s9),
  //                         height: math.max(44, AppSizeHeight.s11),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //
  //           // mute sticker, top-right
  //           Positioned(
  //             top: AppSizeHeight.s3,
  //             right: AppSizeWidth.s3,
  //             child: GestureDetector(
  //               onTap: _toggleMute,
  //               child: Container(
  //                 width: math.max(48, AppSizeWidth.s9),
  //                 height: math.max(48, AppSizeHeight.s12),
  //                 decoration: BoxDecoration(
  //                   color: ColorManager.white,
  //                   shape: BoxShape.circle,
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Color(0x33000000),
  //                       blurRadius: 8,
  //                       offset: Offset(0, 3),
  //                     ),
  //                   ],
  //                 ),
  //                 child: Center(
  //                   child: Text(
  //                     _muted ? '🔇' : '🔊',
  //                     style: TextStyle(fontSize: math.max(18, AppSizeHeight.s5)),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
}

/// A gentle "breathing" scale so the PLAY button invites the tap.
class _Bouncy extends StatefulWidget {
  final Widget child;
  const _Bouncy({required this.child});

  @override
  State<_Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<_Bouncy> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.94,
    upperBound: 1.0,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _c, child: widget.child);
  }
}

// OLD splash build (busy rainbow background, mirrored dragon, no title,
// nothing to tap) — kept beneath per the standing rule:
// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     backgroundColor: ColorManager.primary,
//     body: Center(
//       child: Stack(
//         children: [
//           // ---------------------------------------
//           // Background
//           // ---------------------------------------
//           Image.asset(
//             ImageAssets.background,
//             width: double.infinity,
//             height: double.infinity,
//             fit: BoxFit.cover,
//           ),
//
//           // ---------------------------------------
//           // Leaves animation
//           // ---------------------------------------
//           Lottie.asset(
//             JsonAssets.leaves,
//             width: AppSizeWidth.s100,
//             height: AppSizeHeight.s100,
//           ),
//
//           // ---------------------------------------
//           // Dragon + Start animation
//           // ---------------------------------------
//           Center(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 // -----------------------------------
//                 // Dragon
//                 // -----------------------------------
//                 FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: ScaleTransition(
//                     scale: _scaleAnimation,
//                     child: SizedBox(
//                       width: AppSizeWidth.s60,
//                       height: AppSizeHeight.s100,
//                       child: Transform(
//                         alignment: Alignment.center,
//                         transform: Matrix4.identity()..scale(-1.0, 1.0),
//                         child: RiveAnimation.asset(
//                           ImageAssets.dragon,
//                           artboard: 'dragon',
//                           controllers: _controllers,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 // -----------------------------------
//                 // Start animation
//                 //
//                 // NOT clickable.
//                 // Navigation happens automatically
//                 // after app initialization.
//                 // -----------------------------------
//                 // IgnorePointer(
//                 //   ignoring: true,
//                 //   child: Lottie.asset(
//                 //     JsonAssets.start,
//                 //     width: AppSizeWidth.s30,
//                 //     height: AppSizeHeight.s100,
//                 //   ),
//                 // ),
//                 SizedBox(width: AppPaddingWidth.p8),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
