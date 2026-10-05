import 'package:hive/hive.dart';

import 'hive.dart';

class DrawingRepository {
  static final Box<DrawingModel> _box =
      Hive.box<DrawingModel>('drawings');

  /// Load all saved colors for one image.
  static Map<String, int> loadDrawing(String imageId) {
    final drawing = _box.get(imageId);

    if (drawing == null) {
      return {};
    }

    return Map<String, int>.from(drawing.colors);
  }

  /// Save or update a single path color.
  static Future<void> savePath({
    required String imageId,
    required String pathId,
    required int color,
  }) async {
    final drawing = _box.get(imageId);

    if (drawing == null) {
      final model = DrawingModel(
        imageId: imageId,
        colors: {
          pathId: color,
        },
      );

      await _box.put(imageId, model);
      return;
    }

    drawing.colors[pathId] = color;

    await drawing.save();
  }

  /// Remove one path (restore to white).
  static Future<void> removePath({
    required String imageId,
    required String pathId,
  }) async {
    final drawing = _box.get(imageId);

    if (drawing == null) return;

    drawing.colors.remove(pathId);

    await drawing.save();
  }

  /// Delete the entire drawing.
  static Future<void> clearDrawing(
    String imageId,
  ) async {
    await _box.delete(imageId);
  }
}