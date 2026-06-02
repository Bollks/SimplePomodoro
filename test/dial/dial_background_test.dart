import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pomodoro/src/dial/dial_background.dart';

void main() {
  const idleColor = Color(0xFFF5F1E8);
  const runningColor = Colors.black;

  Future<void> pumpBackground(
    WidgetTester tester, {
    required bool isRunning,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: DialBackground(
          isRunning: isRunning,
          idleColor: idleColor,
          runningColor: runningColor,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Color backgroundColor(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.byKey(const Key('dial-background-color-layer')),
    );
    final decoration = box.decoration as BoxDecoration;
    return decoration.color!;
  }

  testWidgets('start transition uses an intermediate color before black', (
    tester,
  ) async {
    await pumpBackground(tester, isRunning: false);
    expect(backgroundColor(tester), idleColor);

    await pumpBackground(tester, isRunning: true);
    await tester.pump(const Duration(milliseconds: 450));

    final midway = backgroundColor(tester);
    expect(midway, isNot(idleColor));
    expect(midway, isNot(runningColor));

    await tester.pump(const Duration(milliseconds: 450));
    expect(backgroundColor(tester), runningColor);
  });

  testWidgets('completion transition uses an intermediate color before idle', (
    tester,
  ) async {
    await pumpBackground(tester, isRunning: true);
    await tester.pump(const Duration(milliseconds: 900));
    expect(backgroundColor(tester), runningColor);

    await pumpBackground(tester, isRunning: false);
    await tester.pump(const Duration(milliseconds: 550));

    final midway = backgroundColor(tester);
    expect(midway, isNot(runningColor));
    expect(midway, isNot(idleColor));

    await tester.pump(const Duration(milliseconds: 550));
    expect(backgroundColor(tester), idleColor);
  });

  testWidgets('uses distinct start and completion durations', (tester) async {
    await pumpBackground(tester, isRunning: false);
    final widget = tester.widget<DialBackground>(find.byType(DialBackground));

    expect(widget.startDuration, const Duration(milliseconds: 900));
    expect(widget.completionDuration, const Duration(milliseconds: 1100));
  });
}
