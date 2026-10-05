import 'dart:io';

import '../../../data/services/thumbnail_service.dart';

class GalleryThumbnailLoader {
  static Future<File?> load(String imageId) async {
    return ThumbnailService().getThumbnail(imageId);
  }
}
