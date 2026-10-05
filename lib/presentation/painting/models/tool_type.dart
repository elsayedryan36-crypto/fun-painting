import '../coloring_canvas.dart';
import '../region.dart';

/// The different kinds of drawing tools available on the painting page.
enum ToolType { fill, glitter, freehand, pencil, wallpaper, stamp, magic }

/// Represents the currently selected tool, bundling together the
/// [BrushMode], [StrokeStyle] and [ToolType] that define its behavior.
class SelectedTool {
  final BrushMode mode;
  final StrokeStyle style;
  final ToolType type;

  SelectedTool({required this.mode, required this.style, required this.type});
}
