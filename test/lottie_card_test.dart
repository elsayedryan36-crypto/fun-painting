import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// The calm category backgrounds must exist in the bundle. The Lottie
// that plays on top of them is dropped in from a free Lottie site —
// see LOTTIE-SOURCES.md at the workspace root.
const _bgs = [
  'free',
  'zoo',
  'sea',
  'dragons',
  'fairy',
  'space',
  'cars',
  'circus',
  'food',
  'flowers',
  'letters', // NEW this round
  'numbers', // NEW this round
];
// OLD list ended at 'flowers' — Letters and Numbers got their calm
// backgrounds this round, so they join the asset check.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('every category has its calm background asset', () async {
    for (final w in _bgs) {
      final data = await rootBundle.load('assets/images/cards/${w}_bg.jpg');
      expect(
        data.lengthInBytes,
        greaterThan(1000),
        reason: '$w background is missing or empty',
      );
    }
  });
}
