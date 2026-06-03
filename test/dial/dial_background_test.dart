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

  Color idleLayerColor(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.byKey(const Key('dial-background-idle-layer')),
    );
    final decoration = box.decoration as BoxDecoration;
    return decoration.color!;
  }

  double runningLayerOpacity(WidgetTester tester) {
    final opacity = tester.widget<Opacity>(
      find.byKey(const Key('dial-background-running-layer')),
    );
    return opacity.opacity;
  }

  testWidgets('start transition fades running overlay through visible states', (
    tester,
  ) async {
    await pumpBackground(tester, isRunning: false);
    expect(idleLayerColor(tester), idleColor);
    expect(runningLayerOpacity(tester), 0);

    await pumpBackground(tester, isRunning: true);
    await tester.pump(const Duration(milliseconds: 325));
    expect(runningLayerOpacity(tester), greaterThan(0));
    expect(runningLayerOpacity(tester), lessThan(1));

    await tester.pump(const Duration(milliseconds: 325));
    expect(runningLayerOpacity(tester), greaterThan(0));
    expect(runningLayerOpacity(tester), lessThan(1));

    await tester.pump(const Duration(milliseconds: 325));
    expect(runningLayerOpacity(tester), greaterThan(0));
    expect(runningLayerOpacity(tester), lessThan(1));

    await tester.pumpAndSettle();
    expect(runningLayerOpacity(tester), 1);
  });

  testWidgets('stop transition fades running overlay out through visible states', (
    tester,
  ) async {
    await pumpBackground(tester, isRunning: true);
    expect(runningLayerOpacity(tester), 1);

    await pumpBackground(tester, isRunning: false);
    await tester.pump(const Duration(milliseconds: 375));
    expect(runningLayerOpacity(tester), greaterThan(0));
    expect(runningLayerOpacity(tester), lessThan(1));

    await tester.pump(const Duration(milliseconds: 375));
    expect(runningLayerOpacity(tester), greaterThan(0));
    expect(runningLayerOpacity(tester), lessThan(1));

    await tester.pump(const Duration(milliseconds: 375));
    expect(runningLayerOpacity(tester), greaterThan(0));
    expect(runningLayerOpacity(tester), lessThan(1));

    await tester.pumpAndSettle();
    expect(runningLayerOpacity(tester), 0);
  });

  testWidgets('state reversal continues from the current overlay opacity', (
    tester,
  ) async {
    await pumpBackground(tester, isRunning: false);

    await pumpBackground(tester, isRunning: true);
    await tester.pump(const Duration(milliseconds: 650));
    final beforeReverse = runningLayerOpacity(tester);
    expect(beforeReverse, greaterThan(0));
    expect(beforeReverse, lessThan(1));

    await pumpBackground(tester, isRunning: false);
    await tester.pump();
    final afterReverse = runningLayerOpacity(tester);
    expect(afterReverse, closeTo(beforeReverse, 0.08));

    await tester.pumpAndSettle();
    expect(runningLayerOpacity(tester), 0);
  });

  testWidgets('preserves transition when platform disables animations', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await pumpBackground(tester, isRunning: false);
    expect(runningLayerOpacity(tester), 0);

    await pumpBackground(tester, isRunning: true);
    await tester.pump(const Duration(milliseconds: 100));

    expect(runningLayerOpacity(tester), greaterThan(0));
    expect(runningLayerOpacity(tester), lessThan(1));
  });

  testWidgets('uses distinct start and completion durations', (tester) async {
    await pumpBackground(tester, isRunning: false);
    final widget = tester.widget<DialBackground>(find.byType(DialBackground));

    expect(widget.startDuration, const Duration(milliseconds: 1300));
    expect(widget.completionDuration, const Duration(milliseconds: 1500));
  });
}
