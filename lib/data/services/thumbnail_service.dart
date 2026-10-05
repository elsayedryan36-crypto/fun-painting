import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ThumbnailService {
  Future<Directory> getThumbnailDirectory() async {
    final dir = await getApplicationDocumentsDirectory();

    final thumbDir = Directory("${dir.path}/thumbnails");

    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }

    return thumbDir;
  }

  Future<String> getThumbnailPath(String imageId) async {
    final dir = await getThumbnailDirectory();

    final safeName = imageId
        .replaceAll("/", "_")
        .replaceAll("\\", "_");

    return "${dir.path}/$safeName.png";
  }

Future<File?> getThumbnail(String imageId) async {
  debugPrint(">>>>>>>> getThumbnail called <<<<<<<<");

  final path = await getThumbnailPath(imageId);

  debugPrint(path);

  final file = File(path);

  final exists = await file.exists();

  debugPrint("exists = $exists");

  return exists ? file : null;
}

  Future<bool> thumbnailExists(String imageId) async {
    final path = await getThumbnailPath(imageId);

    return File(path).exists();
  }

Future<void> saveThumbnail(
  String imageId,
  Uint8List bytes, {
  bool overwrite = true,
}) async {
  final path = await getThumbnailPath(imageId);

  final file = File(path);

  if (!overwrite && await file.exists()) {
    return;
  }

  await file.writeAsBytes(
    bytes,
    flush: true,
  );

  PaintingBinding.instance.imageCache.evict(FileImage(file));
}

  Future<void> deleteThumbnail(String imageId) async {
    final path = await getThumbnailPath(imageId);

    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteAllThumbnails() async {
  final dir = await getThumbnailDirectory();

  if (!await dir.exists()) return;

  await for (final entity in dir.list()) {
    if (entity is File) {
      await entity.delete();
    }
  }
}

Future<DateTime?> lastModified(String imageId) async {
  final file = await getThumbnail(imageId);

  if (file == null) {
    return null;
  }

  return file.lastModified();
}

}