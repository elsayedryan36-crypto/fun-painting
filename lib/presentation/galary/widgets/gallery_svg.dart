import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../data/local data/painting_repository.dart';

import '../services/gallery_thumbnail_loader.dart' show GalleryThumbnailLoader;
import '../services/svg_cache.dart';

class GallerySvg extends StatefulWidget {
  final String assetName;
  final Color fillColor;

  /// null = keep original stroke width
  final double? strokeWidth;

  final BoxFit fit;
  final Alignment alignment;
  final PaintingRepository repository;
  final String imageId;

  const GallerySvg({
    super.key,
    required this.assetName,
    required this.repository,
    required this.imageId,
    required this.fillColor,
    this.strokeWidth,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  @override
  State<GallerySvg> createState() => _GallerySvgState();
}

class _GallerySvgState extends State<GallerySvg> {
  String? _svgString;
  File? _thumbnail;

  // bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final thumb = await GalleryThumbnailLoader.load(widget.imageId);

    GalleryCache.thumbnails[widget.imageId] = thumb;

    _thumbnail = thumb;

    if (_thumbnail == null) {
      _svgString = GalleryCache.svgs[widget.imageId];
    }

    if (!mounted) return;

    setState(() {});
  }

  @override
  void didUpdateWidget(covariant GallerySvg oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.assetName != widget.assetName ||
        oldWidget.imageId != widget.imageId ||
        oldWidget.fillColor != widget.fillColor ||
        oldWidget.strokeWidth != widget.strokeWidth) {
      _initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (_loading) {
    //   return Center(
    //     child: Lottie.asset(
    //       JsonAssets.loader,

    //       width: double.infinity,
    //       height: double.infinity,
    //     ),
    //   );
    // }

    if (_thumbnail != null) {
      return Image.file(
        _thumbnail!,
        fit: BoxFit.cover,
        alignment: widget.alignment,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      );
    }

    if (_svgString == null) {
      return const SizedBox.shrink();
    }

    return SvgPicture.string(
      _svgString!,
      fit: BoxFit.cover,
      alignment: widget.alignment,
    );
  }
}
