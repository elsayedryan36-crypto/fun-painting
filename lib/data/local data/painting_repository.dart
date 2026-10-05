import 'package:flutter/material.dart';

import 'package:hive/hive.dart';

import '../../presentation/painting/region.dart';
import 'painting_save_model.dart';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class PaintingRepository {
  final Box<PaintingSave> box;
  final Map<String, ui.Image> _wallpaperCache = {};

  PaintingRepository(this.box);

  SavedStroke _strokeToSaved(Stroke stroke) {
    final points = <double>[];

    for (final p in stroke.points) {
      points.add(p.dx);
      points.add(p.dy);
    }

    return SavedStroke(
      points: points,
      color: stroke.color.value,
      style: stroke.style.index,
      wallpaperAsset: stroke.wallpaperAsset,
      stampAsset: stroke.stampAsset,
      stampSize: stroke.stampSize,
    );
  }

  Stroke _savedToStroke(SavedStroke saved) {
    final pts = <Offset>[];

    for (int i = 0; i < saved.points.length; i += 2) {
      pts.add(Offset(saved.points[i], saved.points[i + 1]));
    }

    return Stroke(
      points: pts,
      color: Color(saved.color),
      style: StrokeStyle.values[saved.style],
      wallpaperAsset: saved.wallpaperAsset,
      stampAsset: saved.stampAsset,
      stampSize: saved.stampSize,
    );
  }

  SavedRegion _regionToSaved(Region region) {
    return SavedRegion(
      fillColor: region.currentFillColor.value,
      fillStyle: region.currentFillStyle.index,
      strokes: region.strokes.map(_strokeToSaved).toList(),
    );
  }

  Future<void> _restoreRegion(Region region, SavedRegion saved) async {
    region.currentFillColor = Color(saved.fillColor);

    region.currentFillStyle = StrokeStyle.values[saved.fillStyle];

    region.strokes.clear();

    for (final savedStroke in saved.strokes) {
      final stroke = _savedToStroke(savedStroke);

      //
      // Restore wallpaper image
      //
      if (stroke.wallpaperAsset != null) {
        stroke.wallpaperImage = await _loadWallpaper(stroke.wallpaperAsset!);

        debugPrint("Wallpaper restored: ${stroke.wallpaperAsset}");
      }

      //
      // Restore SVG stamp
      // if (stroke.stampAsset != null) {
      //   final pictureInfo = await vg.loadPicture(
      //     vg.SvgAssetLoader(stroke.stampAsset!),
      //     null,
      //   );

      //   stroke.svgPicture = pictureInfo.picture;
      //   stroke.svgSize = pictureInfo.size;

      //   debugPrint("SVG restored ${stroke.stampAsset}");
      // }

      if (stroke.stampAsset != null) {
        // Just restore the asset path.
        // The picture will be loaded by the canvas when needed.
        debugPrint("SVG restored ${stroke.stampAsset}");
      }

      region.strokes.add(stroke);
    }
  }

  Future<ui.Image> _loadWallpaper(String asset) async {
    if (_wallpaperCache.containsKey(asset)) {
      return _wallpaperCache[asset]!;
    }

    final data = await rootBundle.load(asset);

    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());

    final frame = await codec.getNextFrame();

    _wallpaperCache[asset] = frame.image;

    return frame.image;
  }

  Future<void> savePainting({
    required String imageId,
    required List<Region> regions,
  }) async {
    final save = PaintingSave(regions.map(_regionToSaved).toList());

    await box.put(imageId, save);
  }

  Future<bool> loadPainting({
    required String imageId,
    required List<Region> regions,
  }) async {
    final save = box.get(imageId);

    if (save == null) {
      return false;
    }

    final count = regions.length < save.regions.length
        ? regions.length
        : save.regions.length;

    for (int i = 0; i < count; i++) {
      await _restoreRegion(regions[i], save.regions[i]);
    }

    return true;
  }

  Future<void> deletePainting(String imageId) async {
    await box.delete(imageId);
  }
}
