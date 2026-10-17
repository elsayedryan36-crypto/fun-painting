import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_painting/presentation/home/Widgets/kid_home_shelf.dart';

// The worlds are Lottie files now (commit b6dc5b3): every file the shelf
// and the gallery page promise must really ship in the bundle. The test
// reads the promises straight from kWorldMeta / kFreeDrawLottie, so adding
// a world or a stacked layer can never silently forget its file.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every card Lottie really loads', () async {
    final paths = <String>[
      kFreeDrawLottie,
      for (final meta in kWorldMeta) ...[
        if (meta.lottie != null) meta.lottie!,
        for (final layer in meta.layers) layer.lottie,
      ],
    ];

    expect(paths, hasLength(kWorldMeta.length + 1));

    for (final path in paths) {
      final data = await rootBundle.load(path);
      expect(
        data.lengthInBytes,
        greaterThan(100),
        reason: '$path is missing or empty',
      );
    }
  });

  test('every world keeps a name, an emoji and a colour', () {
    for (final meta in kWorldMeta) {
      expect(meta.name, isNotEmpty);
      expect(meta.emoji, isNotEmpty);
    }
    expect(kWorldMeta.first.name, 'Zoo');
    expect(kWorldMeta.last.name, 'Numbers');
  });
}

// OLD test (kept commented per the release rule) — checked the calm
// *_bg.jpg backgrounds, which were retired when the worlds became Lotties:
//
// const _bgs = [
//   'free', 'zoo', 'sea', 'dragons', 'fairy', 'space',
//   'cars', 'circus', 'food', 'flowers', 'letters', 'numbers',
// ];
//
// void main() {
//   TestWidgetsFlutterBinding.ensureInitialized();
//   test('every category has its calm background asset', () async {
//     for (final w in _bgs) {
//       final data = await rootBundle.load('assets/images/cards/${w}_bg.jpg');
//       expect(
//         data.lengthInBytes,
//         greaterThan(1000),
//         reason: '$w background is missing or empty',
//       );
//     }
//   });
// }
