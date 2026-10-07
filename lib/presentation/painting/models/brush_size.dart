/// Kid-facing brush thickness presets.
///
/// The brush width used to be hard-coded in the painter (15.0 / 14.0 / 12.0 /
/// 8.0) so a child had no way to draw a thick line or a thin one. This enum
/// gives the three-button S / M / L control a value to hand to the painter:
/// each new stroke remembers the factor it was drawn with, so changing the
/// preset never re-sizes a line that is already on the page.
enum BrushSize {
  small(factor: 0.6, shortLabel: 'S', label: 'Thin brush', dotDiameter: 12),
  medium(factor: 1.0, shortLabel: 'M', label: 'Medium brush', dotDiameter: 20),
  large(factor: 1.8, shortLabel: 'L', label: 'Thick brush', dotDiameter: 30);

  const BrushSize({
    required this.factor,
    required this.shortLabel,
    required this.label,
    required this.dotDiameter,
  });

  /// Multiplier applied to the base stroke width of every drawn style.
  /// 1.0 is the old hard-coded look, so [medium] draws exactly like before.
  final double factor;

  /// Single-letter label shown inside the button (readers can use it).
  final String shortLabel;

  /// Plain-language name used by screen readers and tooltips.
  final String label;

  /// Diameter of the preview dot on the button. Shows the child the size
  /// without words.
  final double dotDiameter;
}
