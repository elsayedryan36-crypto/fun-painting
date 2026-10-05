import 'package:flutter/services.dart';

import '../../../data/local data/painting_repository.dart';
import '../../common/resources/color_manager.dart';
import '../services/gallery_thumbnail_loader.dart';
import '../services/svg_cache.dart';
import '../services/svg_modifier.dart';

class GalleryPreloader {
  GalleryPreloader._();

  static Future<void> preload({
    required List<String> imagePaths,
    required PaintingRepository repository,
  }) async {
    await Future.wait(
      imagePaths.map((imageId) async {
        // Thumbnail
        final thumb = await GalleryThumbnailLoader.load(imageId);

        GalleryCache.thumbnails[imageId] = thumb;

        // No thumbnail -> preload svg
        if (thumb == null) {
          final raw = await rootBundle.loadString(imageId);

          final save = repository.box.get(imageId);

          final svg = SvgModifier.modify(
            svg: raw,
            save: save,
            fillColor: ColorManager.white,
            strokeWidth: 5,
          );

          GalleryCache.svgs[imageId] = svg;
        }
      }),
    );
  }
}
