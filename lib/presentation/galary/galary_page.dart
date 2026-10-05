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
import 'widgets/gallery_preloader.dart';

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

  int _currentPage = 0;

  static const int _itemsPerPage = 6;
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

    return Scaffold(
      backgroundColor: ColorManager.lightPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      // horizontal: AppPaddingWidth.p1,
                      // vertical: AppPaddingHeight.p2,
                    ),
                    child: Center(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: AppSizeWidth.s12,
                            child: Center(
                              child: IconButton(
                                icon: Transform.rotate(
                                  angle: math.pi,
                                  child: Lottie.asset(
                                    JsonAssets.start,
                                    width: AppSizeWidth.s30,
                                    height: AppSizeHeight.s30,
                                  ),
                                ),
                                onPressed: _currentPage == 0
                                    ? null
                                    : () {
                                        _pageController.previousPage(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.ease,
                                        );
                                      },
                              ),
                            ),
                          ),

                          Expanded(
                            child: SizedBox(
                              height: AppSizeHeight.s70,
                              width: AppSizeWidth.s60, // your gallery height

                              child: Center(
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: totalPages,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPage = index;
                                    });
                                  },
                                  itemBuilder: (_, pageIndex) {
                                    final start = pageIndex * _itemsPerPage;

                                    final end =
                                        (start + _itemsPerPage > items.length)
                                        ? items.length
                                        : start + _itemsPerPage;

                                    final pageItems = items.sublist(start, end);

                                    return GridView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: pageItems.length,
                                      gridDelegate:
                                          const SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent: 200,
                                            childAspectRatio: 13 / 8,
                                            crossAxisSpacing: 7,
                                            mainAxisSpacing: 7,
                                          ),
                                      itemBuilder: (_, index) {
                                        final globalIndex =
                                            start +
                                            index; // absolute position across all pages
                                        final isFree =
                                            globalIndex <
                                            6; // first 6 images overall are free

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
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            width: AppSizeWidth.s12,
                            child: Center(
                              child: IconButton(
                                icon: Container(
                                  child: Lottie.asset(
                                    JsonAssets.start,
                                    width: AppSizeWidth.s30,
                                    height: AppSizeHeight.s30,
                                  ),
                                ),
                                onPressed: _currentPage == totalPages - 1
                                    ? null
                                    : () {
                                        _pageController.nextPage(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.ease,
                                        );
                                      },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Back button
                  Positioned(
                    top: AppSizeHeight.s0,
                    left: AppSizeWidth.s0,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Lottie.asset(
                            JsonAssets.home,
                            width: AppSizeWidth.s10,
                            height: AppSizeHeight.s14,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            BannerAdWidget(adUnitId: AdUnitIds.selectImageBanner),
          ],
        ),
      ),
    );
  }
}
