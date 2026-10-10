import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/common/resources/color_manager.dart';
import 'package:fun_painting/presentation/galary/helpers/gallery_collection_helper.dart';
import 'package:fun_painting/presentation/galary/widgets/gallery_card.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import '../../data/local data/painting_repository.dart';
import '../../data/local data/painting_save_model.dart';
import '../../data/services/ad_unit_ids.dart';
import '../common/resources/assets_manager.dart' show JsonAssets;
import '../common/resources/values_manager.dart';
import '../common/widgets/banner_ad_widget.dart' show BannerAdWidget;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../home/Widgets/kid_home_shelf.dart';
import 'widgets/gallery_preloader.dart';
import 'widgets/kid_gallery_widgets.dart';

class GalleryPage extends StatefulWidget {
  final int listName;
  const GalleryPage({super.key, required this.listName});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> with RouteAware {
  int _refreshId = 0;
  late final PaintingRepository repository;
  late final PageController _pageController;

  // OLD (kept commented per the release rule): page index was tracked here
  // and used by the old arrows/dots. SmoothPageIndicator tracks it now.
  // int _currentPage = 0;

  static const int _itemsPerPage = 4; // OLD: 6;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    repository = PaintingRepository(Hive.box<PaintingSave>("paintings"));

    _pageController = PageController();

    _initializeGallery();
  }

  Future<void> _initializeGallery() async {
    // ✅ FIX: the loader was only cleared on the happy path, so any error
    // (missing artwork, unreadable thumbnail) left the page spinning forever.
    try {
      final items = GalleryCollectionHelper.getItems(context, widget.listName);

      await GalleryPreloader.preload(
        imagePaths: items.map((e) => e.imagePath).toList(),
        repository: repository,
      );

      await Future.delayed(const Duration(seconds: 1));
    } catch (e, st) {
      debugPrint('Gallery initialisation error: $e\n$st');
    } finally {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: ColorManager.lightPrimary,
        body: Center(
          child: Lottie.asset(JsonAssets.loader, width: 250, height: 250),
        ),
      );
    }
    final items = GalleryCollectionHelper.getItems(context, widget.listName);
    final totalPages = (items.length / _itemsPerPage).ceil();
    final meta = widget.listName < kWorldMeta.length
        ? kWorldMeta[widget.listName]
        : null;

    // NEW (sticker book): the page lives inside its own world's calm
    // colour; polaroid cards; present-not-grey locking; gold stars.
    return Scaffold(
      backgroundColor: ColorManager.lightPrimary,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (meta?.art != null)
              Image.asset(
                meta!.art!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            else
              Container(
                color: (meta?.color ?? ColorManager.lightPrimary).withValues(
                  alpha: 0.35,
                ),
              ),
            Column(
              children: [
                WorldBanner(
                  emoji: meta?.emoji ?? '🎨',
                  name: meta?.name ?? 'Pictures',
                  count: items.length,
                  color: meta?.color ?? ColorManager.darkPrimary,
                  onHome: () => Navigator.pop(context),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: totalPages,
                    // OLD: setState(() => _currentPage = index);
                    onPageChanged: (_) {},
                    itemBuilder: (_, pageIndex) {
                      final start = pageIndex * _itemsPerPage;
                      final end = (start + _itemsPerPage > items.length)
                          ? items.length
                          : start + _itemsPerPage;
                      final pageItems = items.sublist(start, end);
                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: AppPaddingWidth.p3,
                          vertical: AppPaddingHeight.p1,
                        ),
                        itemCount: pageItems.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.95,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemBuilder: (_, index) {
                          final globalIndex = start + index;
                          final isFree = globalIndex < 6;
                          return GalleryCard(
                            item: pageItems[index],
                            repository: repository,
                            refreshId: _refreshId,
                            onReturn: () {
                              if (!mounted) return;
                              setState(() {
                                _refreshId++;
                              });
                            },
                            isFree: isFree,
                            ribbonColor:
                                meta?.color ?? ColorManager.darkPrimary,
                            tilt: _tilts[index % _tilts.length],
                          );
                        },
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: math.max(20, AppSizeHeight.s6),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: totalPages,
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
                ),
                _buildWoodShelfAd(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const List<double> _tilts = [-0.02, 0.016, 0.012, -0.014];

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
        child: BannerAdWidget(adUnitId: AdUnitIds.selectImageBanner),
      ),
    );
  }
}

// OLD gallery build (plain blue page, 6 small cards, grey locked veil,
// tiny corner home Lottie, side arrows) — kept beneath per the rule:
//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return Scaffold(
//         backgroundColor: ColorManager.lightPrimary,
//         body: Center(
//           child: Lottie.asset(JsonAssets.loader, width: 250, height: 250),
//         ),
//       );
//     }
//     final items = GalleryCollectionHelper.getItems(context, widget.listName);
//     final totalPages = (items.length / _itemsPerPage).ceil();
//
//     return Scaffold(
//       backgroundColor: ColorManager.lightPrimary,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: Stack(
//                 children: [
//                   Padding(
//                     padding: EdgeInsets.symmetric(),
//                     child: Center(
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           SizedBox(
//                             width: AppSizeWidth.s12,
//                             child: Center(
//                               child: IconButton(
//                                 icon: Transform.rotate(
//                                   angle: math.pi,
//                                   child: Lottie.asset(
//                                     JsonAssets.start,
//                                     width: AppSizeWidth.s30,
//                                     height: AppSizeHeight.s30,
//                                   ),
//                                 ),
//                                 onPressed: _currentPage == 0
//                                     ? null
//                                     : () {
//                                         _pageController.previousPage(
//                                           duration: const Duration(
//                                             milliseconds: 300,
//                                           ),
//                                           curve: Curves.ease,
//                                         );
//                                       },
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             child: SizedBox(
//                               height: AppSizeHeight.s70,
//                               width: AppSizeWidth.s60,
//                               child: Center(
//                                 child: PageView.builder(
//                                   controller: _pageController,
//                                   itemCount: totalPages,
//                                   onPageChanged: (index) {
//                                     setState(() {
//                                       _currentPage = index;
//                                     });
//                                   },
//                                   itemBuilder: (_, pageIndex) {
//                                     final start = pageIndex * _itemsPerPage;
//                                     final end =
//                                         (start + _itemsPerPage > items.length)
//                                         ? items.length
//                                         : start + _itemsPerPage;
//                                     final pageItems = items.sublist(start, end);
//                                     return GridView.builder(
//                                       physics:
//                                           const NeverScrollableScrollPhysics(),
//                                       itemCount: pageItems.length,
//                                       gridDelegate:
//                                           const SliverGridDelegateWithMaxCrossAxisExtent(
//                                             maxCrossAxisExtent: 200,
//                                             childAspectRatio: 13 / 8,
//                                             crossAxisSpacing: 7,
//                                             mainAxisSpacing: 7,
//                                           ),
//                                       itemBuilder: (_, index) {
//                                         final globalIndex = start + index;
//                                         final isFree = globalIndex < 6;
//                                         return GalleryCard(
//                                           item: pageItems[index],
//                                           repository: repository,
//                                           refreshId: _refreshId,
//                                           onReturn: () {
//                                             if (!mounted) return;
//                                             setState(() {
//                                               _refreshId++;
//                                             });
//                                           },
//                                           isFree: isFree,
//                                         );
//                                       },
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ),
//                           ),
//                           SizedBox(
//                             width: AppSizeWidth.s12,
//                             child: Center(
//                               child: IconButton(
//                                 icon: Lottie.asset(
//                                   JsonAssets.start,
//                                   width: AppSizeWidth.s30,
//                                   height: AppSizeHeight.s30,
//                                 ),
//                                 onPressed: _currentPage == totalPages - 1
//                                     ? null
//                                     : () {
//                                         _pageController.nextPage(
//                                           duration: const Duration(
//                                             milliseconds: 300,
//                                           ),
//                                           curve: Curves.ease,
//                                         );
//                                       },
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     top: AppSizeHeight.s0,
//                     left: AppSizeWidth.s0,
//                     child: Row(
//                       children: [
//                         IconButton(
//                           icon: Lottie.asset(
//                             JsonAssets.home,
//                             width: AppSizeWidth.s10,
//                             height: AppSizeHeight.s14,
//                           ),
//                           onPressed: () => Navigator.pop(context),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             BannerAdWidget(adUnitId: AdUnitIds.selectImageBanner),
//           ],
//         ),
//       ),
//     );
//   }
