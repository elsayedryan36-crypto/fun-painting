import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import 'package:fun_painting/presentation/painting/widgets/painting_tutorial.dart';

void main() {
  // The layout uses sizer units, so the test app needs a realistic screen.
  Future<void> pumpTutorial(
    WidgetTester tester, {
    required List<TutorialStep> steps,
    required VoidCallback onFinished,
    required List<GlobalKey> targets,
  }) async {
    tester.view.physicalSize = const Size(740 * 3, 360 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, deviceType) => MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 60,
                  top: 80,
                  child: SizedBox(key: targets[0], width: 80, height: 60),
                ),
                Positioned(
                  left: 560,
                  top: 240,
                  child: SizedBox(key: targets[1], width: 80, height: 60),
                ),
                Positioned.fill(
                  child: PaintingTutorial(steps: steps, onFinished: onFinished),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // First pump builds, second pump runs the post-frame measurement.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('walks through the steps and finishes on the last one', (
    tester,
  ) async {
    final first = GlobalKey();
    final second = GlobalKey();
    var finished = 0;

    await pumpTutorial(
      tester,
      targets: [first, second],
      onFinished: () => finished++,
      steps: [
        TutorialStep(
          target: first,
          titleKey: 'tut_colour_title',
          bodyKey: 'tut_colour_body',
          icon: Icons.palette_rounded,
        ),
        TutorialStep(
          target: second,
          titleKey: 'tut_save_title',
          bodyKey: 'tut_save_body',
        ),
      ],
    );

    expect(find.text('Pick a colour'), findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Save your art'), findsOneWidget);
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text("Let's paint!"), findsOneWidget);
    expect(finished, 0);

    await tester.tap(find.text("Let's paint!"));
    await tester.pump();
    expect(finished, 1);
  });

  testWidgets('Skip ends the tutorial straight away', (tester) async {
    final key = GlobalKey();
    var finished = 0;

    await pumpTutorial(
      tester,
      targets: [key, GlobalKey()],
      onFinished: () => finished++,
      steps: [
        TutorialStep(
          target: key,
          titleKey: 'tut_zoom_in_title',
          bodyKey: 'tut_zoom_in_body',
        ),
      ],
    );

    expect(find.text('Zoom in'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(finished, 1);
  });
}
