import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pomodoro/src/dial/dial_geometry.dart';

void main() {
  const geometry = DialGeometry();

  test('clampMinutes limits values to 5 through 120', () {
    expect(geometry.clampMinutes(0), 5);
    expect(geometry.clampMinutes(4), 5);
    expect(geometry.clampMinutes(5), 5);
    expect(geometry.clampMinutes(121), 120);
  });

  test('snapMinutes rounds to the nearest whole minute after clamping', () {
    expect(geometry.snapMinutes(5.2), 5);
    expect(geometry.snapMinutes(5.6), 6);
    expect(geometry.snapMinutes(119.6), 120);
  });

  test('angleForMinutes maps clock positions from 12 o clock clockwise', () {
    expect(geometry.angleForMinutes(5), closeTo(math.pi / 6, 0.0001));
    expect(geometry.angleForMinutes(15), closeTo(math.pi / 2, 0.0001));
    expect(geometry.angleForMinutes(30), closeTo(math.pi, 0.0001));
    expect(geometry.angleForMinutes(45), closeTo(math.pi * 1.5, 0.0001));
    expect(geometry.angleForMinutes(60), closeTo(0, 0.0001));
    expect(geometry.angleForMinutes(65), closeTo(math.pi / 6, 0.0001));
    expect(geometry.angleForMinutes(120), closeTo(0, 0.0001));
  });

  test('displaySweepForMinutes fills the whole dial after 60 minutes', () {
    expect(geometry.displaySweepForMinutes(5), closeTo(math.pi / 6, 0.0001));
    expect(geometry.displaySweepForMinutes(60), closeTo(math.pi * 2, 0.0001));
    expect(geometry.displaySweepForMinutes(65), closeTo(math.pi * 2, 0.0001));
    expect(geometry.displaySweepForMinutes(120), closeTo(math.pi * 2, 0.0001));
  });

  test('shortestClockwiseDelta handles crossing 12 o clock', () {
    final previous = math.pi * 2 - 0.05;
    final current = 0.05;
    expect(geometry.shortestClockwiseDelta(previous, current), closeTo(0.10, 0.0001));

    final reversePrevious = 0.05;
    final reverseCurrent = math.pi * 2 - 0.05;
    expect(geometry.shortestClockwiseDelta(reversePrevious, reverseCurrent), closeTo(-0.10, 0.0001));
  });

  test('isOnEdge accepts points near the active sector edge only', () {
    const size = Size(300, 300);
    final edge = geometry.pointForMinutes(size, 15);
    final opposite = geometry.pointForMinutes(size, 45);

    expect(geometry.isOnEdge(size: size, position: edge, minutes: 15), isTrue);
    expect(geometry.isOnEdge(size: size, position: opposite, minutes: 15), isFalse);
  });
}
