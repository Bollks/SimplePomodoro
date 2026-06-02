import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pomodoro/src/dial/dial_geometry.dart';

void main() {
  const geometry = DialGeometry();

  test('clampMinutes limits values to 0 through 60', () {
    expect(geometry.clampMinutes(-1), 0);
    expect(geometry.clampMinutes(0), 0);
    expect(geometry.clampMinutes(60), 60);
    expect(geometry.clampMinutes(61), 60);
  });

  test('snapMinutes rounds to the nearest whole minute after clamping', () {
    expect(geometry.snapMinutes(0.2), 0);
    expect(geometry.snapMinutes(0.6), 1);
    expect(geometry.snapMinutes(59.6), 60);
  });

  test('angleForMinutes maps one lap from 12 o clock clockwise', () {
    expect(geometry.angleForMinutes(0), closeTo(0, 0.0001));
    expect(geometry.angleForMinutes(5), closeTo(math.pi / 6, 0.0001));
    expect(geometry.angleForMinutes(15), closeTo(math.pi / 2, 0.0001));
    expect(geometry.angleForMinutes(30), closeTo(math.pi, 0.0001));
    expect(geometry.angleForMinutes(45), closeTo(math.pi * 1.5, 0.0001));
    expect(geometry.angleForMinutes(60), closeTo(0, 0.0001));
  });

  test('minutesForAngle maps dial angles to a single lap', () {
    expect(geometry.minutesForAngle(0), 0);
    expect(geometry.minutesForAngle(math.pi / 6), 5);
    expect(geometry.minutesForAngle(math.pi / 2), 15);
    expect(geometry.minutesForAngle(math.pi), 30);
    expect(geometry.minutesForAngle(math.pi * 1.5), 45);
    expect(geometry.minutesForAngle(math.pi * 2 - 0.02), 60);
  });

  test('shortestClockwiseDelta handles crossing 12 o clock', () {
    final previous = math.pi * 2 - 0.05;
    final current = 0.05;
    expect(
      geometry.shortestClockwiseDelta(previous, current),
      closeTo(0.10, 0.0001),
    );

    final reversePrevious = 0.05;
    final reverseCurrent = math.pi * 2 - 0.05;
    expect(
      geometry.shortestClockwiseDelta(reversePrevious, reverseCurrent),
      closeTo(-0.10, 0.0001),
    );
  });

  test('isOnMinuteHand accepts points near the hand only', () {
    const size = Size(300, 300);
    final onHand = geometry.pointForMinutes(size, 15, radiusFactor: 0.30);
    final awayFromHand = geometry.pointForMinutes(size, 45, radiusFactor: 0.30);

    expect(
      geometry.isOnMinuteHand(size: size, position: onHand, minutes: 15),
      isTrue,
    );
    expect(
      geometry.isOnMinuteHand(size: size, position: awayFromHand, minutes: 15),
      isFalse,
    );
  });

  test('isOnMinuteHand accepts the hub as part of the draggable hand', () {
    const size = Size(300, 300);

    expect(
      geometry.isOnMinuteHand(
        size: size,
        position: geometry.centerOf(size),
        minutes: 0,
      ),
      isTrue,
    );
  });
}
