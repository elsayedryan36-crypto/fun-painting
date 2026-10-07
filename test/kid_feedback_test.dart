// Tests for the safety + feedback part of the kid-ui round (commit 3).
//
// Two claims:
//   * "clear everything" cannot happen by accident any more — it needs a
//     deliberate tap on a big red button, and anything else means "no";
//   * the celebration reacts to what the child did: a filled shape gets a
//     bigger burst than a dot, and a locked shape gets the small "no" ring
//     instead of confetti (the old code used one confetti size for every
//     touch, including touches that changed nothing).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_painting/presentation/painting/coloring_canvas.dart';
import 'package:fun_painting/presentation/painting/widgets/kid_dialogs.dart';

/// A screen with one button that opens the dialog and remembers the answer.
Widget _dialogHarness(void Function(bool) onAnswer) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              onAnswer(await showClearAllDialog(context));
            },
            child: const Text('Clear'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('clear-all confirmation', () {
    testWidgets('asks before erasing and reports "no" for Keep painting', (
      tester,
    ) async {
      bool? answer;
      await tester.pumpWidget(_dialogHarness((a) => answer = a));

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Erase everything?'), findsOneWidget);
      expect(find.text('Keep painting'), findsOneWidget);
      expect(find.text('Erase all'), findsOneWidget);

      await tester.tap(find.text('Keep painting'));
      await tester.pumpAndSettle();

      expect(answer, isFalse);
      expect(find.text('Erase everything?'), findsNothing);
    });

    testWidgets('reports "yes" only when Erase all is tapped', (tester) async {
      bool? answer;
      await tester.pumpWidget(_dialogHarness((a) => answer = a));

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Erase all'));
      await tester.pumpAndSettle();

      expect(answer, isTrue);
    });

    testWidgets('tapping outside the question counts as "no"', (tester) async {
      bool? answer;
      await tester.pumpWidget(_dialogHarness((a) => answer = a));

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Top of the screen = outside the dialog.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(answer, isFalse);
    });

    testWidgets('both answers are big enough for small fingers', (
      tester,
    ) async {
      await tester.pumpWidget(_dialogHarness((_) {}));
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      for (final label in ['Keep painting', 'Erase all']) {
        final size = tester.getSize(
          find
              .ancestor(of: find.text(label), matching: find.byType(InkWell))
              .first,
        );
        expect(
          size.height,
          greaterThanOrEqualTo(64),
          reason: '"$label" is only ${size.height} dp tall',
        );
      }
    });
  });

  group('tap feedback', () {
    test('a filled shape is celebrated more than a dot', () {
      expect(
        sparkleSizeFor(TapFeedback.fill),
        greaterThan(sparkleSizeFor(TapFeedback.dot)),
      );
      expect(
        sparkleSizeFor(TapFeedback.magic),
        greaterThan(sparkleSizeFor(TapFeedback.dot)),
      );
      expect(
        sparkleSizeFor(TapFeedback.stamp),
        greaterThan(sparkleSizeFor(TapFeedback.dot)),
      );
    });

    test('a locked shape says no with the small ring', () {
      final locked = sparkleSizeFor(TapFeedback.locked);
      expect(locked, greaterThan(0), reason: 'it must be seen');
      expect(locked, lessThan(sparkleSizeFor(TapFeedback.dot)));
    });

    test('a tap that did nothing shows nothing', () {
      expect(sparkleSizeFor(TapFeedback.none), 0);
    });
  });
}
