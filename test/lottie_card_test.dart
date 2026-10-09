import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';

// The generated card Lotties must load and play in the app's own
// lottie package: embedded base64 art + vector sparkles + bubbles.
const _cardLotties = [
  'zoo',
  'sea',
  'dragons',
  'fairy',
  'space',
  'cars',
  'circus',
  'food',
  'flowers',
  'letters',
];

void main() {
  // Every generated card scene must load and play in the app's own
  // lottie package: fixed base64 background + vector animals on top.
  for (final world in _cardLotties) {
    testWidgets('the $world card Lottie loads and plays', (tester) async {
      final bytes = await rootBundle.load('assets/json/cards/$world.json');
      final comp = await LottieComposition.fromByteData(bytes);
      expect(comp.duration, const Duration(seconds: 6));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 300,
                child: Lottie(composition: comp),
              ),
            ),
          ),
        ),
      );
      // play two seconds of the loop; must not throw
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(find.byType(Lottie), findsOneWidget);
    });
  }
}
