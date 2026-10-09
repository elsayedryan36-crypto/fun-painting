import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:fun_painting/data/services/review_service.dart';
import 'package:fun_painting/presentation/common/widgets/rate_wedgit_home.dart';
// OLD-build imports (the commented build below still mentions them):
// import 'package:lottie/lottie.dart';
import 'package:upgrader/upgrader.dart';

import 'package:fun_painting/presentation/home/Widgets/jungle.dart';
import 'package:fun_painting/presentation/home/Widgets/kid_home_shelf.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../app/app_pref.dart';
import '../../data/services/ad_unit_ids.dart';
import '../common/local_data/collection_list.dart';
// OLD-build imports (the commented build below still mentions them):
// import '../common/resources/assets_manager.dart' show JsonAssets;
import '../common/resources/color_manager.dart' show ColorManager;
import '../common/resources/values_manager.dart';
import '../common/widgets/setting_Widget.dart';
import '../common/widgets/banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final AudioPlayer _player = AudioPlayer();
  int _currentPage = 0;
  AppPreferences appPreferences = AppPreferences();
  // double _currentVolume = 0.2; // matches your current default
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playBackgroundMusic();
    _registerOpenAndMaybeShowRating();
  }

  Future<void> _registerOpenAndMaybeShowRating() async {
    await ReviewService.instance.registerAppOpen();
    final count = ReviewService.instance.getOpenCount();

    debugPrint('Open count after increment: $count');

    if (count > 0 && count % 10 == 0 && mounted) {
      // OLD (interrupted the shelf too early):
      // if (count > 0 && count % 5 == 0 && mounted) {
      // Small delay so it doesn't pop over an unfinished loading UI
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: ColorManager.lightPrimary,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: AppSizeWidth.s55,
            height: AppSizeHeight.s70,
            // OLD:
            // width: AppSizeWidth.s65,
            // height: AppSizeHeight.s80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    IconButton(
                      icon: Icon(Icons.close, color: ColorManager.darkPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                Padding(
                  padding: EdgeInsets.only(
                    top: AppPaddingHeight.p2,
                    left: AppPaddingWidth.p2_5,
                    right: AppPaddingWidth.p2_5,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          height: AppSizeHeight.s33,
                        ),
                      ),
                      const RateAppWidgetHome(),
                      SizedBox(height: AppSizeHeight.s5),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

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

  Future<void> _playBackgroundMusic() async {
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
    await _player.setVolume(appPreferences.getKSoundVolum());
    await _player.play(AssetSource('sounds/main.mp3'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NEW (fantastic home): the "pick your world" storybook shelf —
    // sticker cards with names and emoji, Free Draw as the hero card,
    // chunky hand arrows, crayon dots, and the ad on a wood shelf.
    final galaryItems = buildGalleryItems(context);
    final pages = chunkShelf(buildShelfSlots(galaryItems), _cardsPerPage);

    return UpgradeAlert(
      upgrader: Upgrader(debugLogging: true),
      showIgnore: false,
      showLater: true,
      showReleaseNotes: true,
      child: Scaffold(
        backgroundColor: ColorManager.lightPrimary,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildMascotBanner(),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildShelfArrow(
                          backward: true,
                          pageCount: pages.length,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(child: _buildShelfPages(pages)),
                              _buildCrayonDots(pages.length),
                            ],
                          ),
                        ),
                        _buildShelfArrow(
                          backward: false,
                          pageCount: pages.length,
                        ),
                      ],
                    ),
                  ),
                  _buildWoodShelfAd(),
                ],
              ),
              SettingWidget(
                player: _player,
                initialVolume: appPreferences.getKSoundVolum(),
                onVolumeChanged: (value) {
                  appPreferences.setKSoundVolum(value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Shelf pieces (fantastic home)
  // ============================================================

  static const int _cardsPerPage = 3;

  Widget _buildMascotBanner() {
    return Container(
      height: math.max(56, AppSizeHeight.s14),
      margin: EdgeInsets.symmetric(
        horizontal: AppPaddingWidth.p2,
        vertical: AppPaddingHeight.p1,
      ),
      decoration: BoxDecoration(
        color: ColorManager.white,
        borderRadius: BorderRadius.circular(math.max(14, AppSizeHeight.s4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2B142846),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/app_icon.png',
            height: math.max(40, AppSizeHeight.s11),
          ),
          SizedBox(width: AppPaddingWidth.p2),
          Text(
            'pick your world!',
            style: TextStyle(
              color: ColorManager.darkPrimary,
              fontWeight: FontWeight.w900,
              fontSize: math.max(15, AppSizeHeight.s4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShelfArrow({required bool backward, required int pageCount}) {
    final atEnd = backward ? _currentPage == 0 : _currentPage >= pageCount - 1;
    return SizedBox(
      width: math.max(56, AppSizeWidth.s10),
      child: Center(
        child: Opacity(
          opacity: atEnd ? 0.35 : 1,
          child: GestureDetector(
            onTap: atEnd
                ? null
                : () {
                    if (backward) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    }
                  },
            child: Container(
              width: math.max(48, AppSizeWidth.s9),
              height: math.max(48, AppSizeHeight.s12),
              decoration: BoxDecoration(
                color: ColorManager.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33142846),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  backward ? '👈' : '👉',
                  style: TextStyle(fontSize: math.max(22, AppSizeHeight.s6)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShelfPages(List<List<ShelfSlot>> pages) {
    return PageView.builder(
      controller: _pageController,
      itemCount: pages.length,
      onPageChanged: (index) {
        if (!mounted) return;
        setState(() {
          _currentPage = index;
        });
      },
      itemBuilder: (context, pageIndex) {
        final page = pages[pageIndex];
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppPaddingWidth.p1,
            vertical: AppPaddingHeight.p1,
          ),
          child: Row(
            children: [
              for (final slot in page)
                Expanded(
                  flex: slot.isHero ? 5 : 4,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppPaddingWidth.p1,
                    ),
                    child: WorldCard(
                      slot: slot,
                      thumb: AnimatedWorldThumb(
                        artPath: slot.isHero ? kFreeDrawArt : slot.meta!.art,
                        emoji: slot.isHero ? '🖍️' : slot.meta!.emoji,
                        fallback: CollectionWidget(
                          videoPath: slot.item.imagePath,
                        ),
                      ),
                      // OLD (the looping video was the only thumb):
                      // thumb: CollectionWidget(videoPath: slot.item.imagePath),
                      onTap: slot.item.onTap,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCrayonDots(int count) {
    return SizedBox(
      height: math.max(20, AppSizeHeight.s6),
      child: SmoothPageIndicator(
        controller: _pageController,
        count: count,
        effect: CustomizableEffect(
          spacing: math.max(8, AppSizeWidth.s1_5),
          activeDotDecoration: DotDecoration(
            width: math.max(26, AppSizeWidth.s4),
            height: math.max(10, AppSizeHeight.s3),
            color: ColorManager.gold,
            borderRadius: BorderRadius.circular(6),
            dotBorder: const DotBorder(
              color: Color(0xFF2E3A8C),
              width: 2,
              padding: 2,
            ),
          ),
          dotDecoration: DotDecoration(
            width: math.max(14, AppSizeWidth.s2),
            height: math.max(14, AppSizeHeight.s4),
            borderRadius: BorderRadius.circular(14),
          ),
          inActiveColorOverride: (index) {
            const palette = [
              Color(0xFF4CAF50),
              Color(0xFF69F0AE),
              Color(0xFFFFCA28),
              Color(0xFF42A5F5),
              Color(0xFFFFC107),
            ];
            return palette[index % palette.length];
          },
        ),
      ),
    );
  }

  Widget _buildWoodShelfAd() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFA06A44), Color(0xFF8A5A38)],
        ),
      ),
      padding: EdgeInsets.all(math.max(4, AppSizeHeight.s1)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(math.max(8, AppSizeHeight.s2)),
        child: BannerAdWidget(adUnitId: AdUnitIds.galleryBanner),
      ),
    );
  }

  // OLD (one world at a time, no names — replaced by the shelf above):
  // @override
  // Widget build(BuildContext context) {
  //   final galaryItems = buildGalleryItems(context);
  //
  //   return UpgradeAlert(
  //     upgrader: Upgrader(debugLogging: true),
  //     showIgnore: false,
  //     showLater: true,
  //     showReleaseNotes: true,
  //     child: Scaffold(
  //       backgroundColor: ColorManager.lightPrimary,
  //       body: SafeArea(
  //         child: Stack(
  //           children: [
  //             Column(
  //               children: [
  //                 Expanded(
  //                   child: Row(
  //                     crossAxisAlignment: CrossAxisAlignment.center,
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: [
  //                       SizedBox(
  //                         width: AppSizeWidth.s12,
  //                         child: Center(
  //                           child: IconButton(
  //                             icon: Transform.rotate(
  //                               angle: math.pi,
  //                               child: Lottie.asset(
  //                                 JsonAssets.start,
  //                                 width: AppSizeWidth.s30,
  //                                 height: AppSizeHeight.s30,
  //                               ),
  //                             ),
  //                             onPressed: _currentPage == 0
  //                                 ? null
  //                                 : () {
  //                                     _pageController.previousPage(
  //                                       duration: const Duration(
  //                                         milliseconds: 300,
  //                                       ),
  //                                       curve: Curves.ease,
  //                                     );
  //                                   },
  //                           ),
  //                         ),
  //                       ),
  //
  //                       // ============================================================
  //                       // MAIN GALLERY
  //                       // ============================================================
  //                       Expanded(
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.center,
  //                           mainAxisAlignment: MainAxisAlignment.center,
  //                           children: [
  //                             // ========================================================
  //                             // PAGE VIEW
  //                             // ========================================================
  //                             SizedBox(
  //                               width: AppSizeWidth.s80,
  //                               height: AppSizeHeight.s70,
  //                               child: PageView.builder(
  //                                 controller: _pageController,
  //                                 itemCount: galaryItems.length,
  //
  //                                 onPageChanged: (index) {
  //                                   if (!mounted) return;
  //
  //                                   setState(() {
  //                                     _currentPage = index;
  //                                   });
  //                                 },
  //
  //                                 itemBuilder: (context, index) {
  //                                   final item = galaryItems[index];
  //
  //                                   return GestureDetector(
  //                                     onTap: item.onTap,
  //                                     child: CollectionWidget(
  //                                       videoPath: item.imagePath,
  //                                     ),
  //                                   );
  //                                 },
  //                               ),
  //                             ),
  //
  //                             // ========================================================
  //                             // SPACE ABOVE DOTS
  //                             // ========================================================
  //                             const SizedBox(height: 16),
  //
  //                             SmoothPageIndicator(
  //                               controller: _pageController,
  //                               count: galaryItems.length,
  //                               effect: CustomizableEffect(
  //                                 spacing: 10.0,
  //                                 activeDotDecoration: DotDecoration(
  //                                   width: 22,
  //                                   height: AppSizeHeight.s4,
  //                                   color: ColorManager
  //                                       .gold, // or your brand active color
  //                                   borderRadius: BorderRadius.circular(6),
  //                                   dotBorder: const DotBorder(
  //                                     color: Color(0xFF2E3A8C),
  //                                     width: 2,
  //                                     padding: 2,
  //                                   ),
  //                                 ),
  //                                 dotDecoration: DotDecoration(
  //                                   width: 14,
  //                                   height: 14,
  //                                   borderRadius: BorderRadius.circular(14),
  //                                 ),
  //                                 inActiveColorOverride: (index) {
  //                                   const palette = [
  //                                     Color(0xFF4CAF50),
  //                                     Color(0xFF69F0AE),
  //                                     Color(0xFFFFCA28),
  //                                     Color(0xFF42A5F5),
  //                                     Color(0xFFFFC107),
  //                                   ];
  //                                   return palette[index % palette.length];
  //                                 },
  //                               ),
  //                             ),
  //                             //   }),
  //                             // ),
  //
  //                             // ========================================================
  //                             // SPACE BELOW DOTS
  //                             // ========================================================
  //                             // const SizedBox(height: 24),
  //                           ],
  //                         ),
  //                       ),
  //
  //                       // ============================================================
  //                       // NEXT BUTTON
  //                       // ============================================================
  //                       SizedBox(
  //                         width: AppSizeWidth.s12,
  //                         child: Center(
  //                           child: IconButton(
  //                             icon: Lottie.asset(
  //                               JsonAssets.start,
  //                               width: AppSizeWidth.s30,
  //                               height: AppSizeHeight.s30,
  //                             ),
  //
  //                             onPressed: _currentPage >= galaryItems.length - 1
  //                                 ? null
  //                                 : () {
  //                                     _pageController.nextPage(
  //                                       duration: const Duration(
  //                                         milliseconds: 300,
  //                                       ),
  //                                       curve: Curves.ease,
  //                                     );
  //                                   },
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 BannerAdWidget(adUnitId: AdUnitIds.galleryBanner),
  //               ],
  //             ),
  //             SettingWidget(
  //               player: _player,
  //               initialVolume: appPreferences.getKSoundVolum(),
  //               onVolumeChanged: (value) {
  //                 appPreferences.setKSoundVolum(value);
  //               },
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
