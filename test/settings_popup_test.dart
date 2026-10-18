import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_painting/presentation/common/widgets/info_settings_dialog.dart';
import 'package:sizer/sizer.dart';

import 'package:fun_painting/presentation/common/widgets/info_widget.dart';

/// Pump in steps until the rating stars' delayed timers have all run.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

Widget host() {
  return Sizer(
    builder: (_, _, _) => MaterialApp(
      home: Scaffold(body: const Center(child: InfoSettingsDialog())),
    ),
  );
}

void main() {
  testWidgets('opens on Language with all 14 languages', (tester) async {
    tester.view.physicalSize = const Size(740, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(host());
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(ChoiceChip), findsNWidgets(14));
    expect(find.text('Email'), findsNothing);
  });

  testWidgets('Contact us shows Email and WhatsApp', (tester) async {
    tester.view.physicalSize = const Size(740, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(host());
    await tester.tap(find.text('Contact us'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('Rate the app shows the rating row', (tester) async {
    tester.view.physicalSize = const Size(740, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(host());
    await tester.tap(find.text('Rate the app'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(RateAppWidget), findsOneWidget);
    // Dispose the stars' repeating animations before the test ends.
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('every section fits a landscape phone and a small screen', (
    tester,
  ) async {
    for (final size in [
      const Size(740, 360),
      const Size(640, 360),
      const Size(844, 390),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(host());
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'language at $size');
      await tester.tap(find.text('Contact us'));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'contact at $size');
      await tester.tap(find.text('Rate the app'));
      // The rating stars start their animations with delayed timers; let them run.
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'rate at $size');
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
      await settle(tester);
    }
  });
}
