import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pomodoro/src/dial/dial_drag_session.dart';
import 'package:simple_pomodoro/src/dial/dial_geometry.dart';

void main() {
  const geometry = DialGeometry();

  test('clockwise movement increases selected minutes from zero', () {
    final session = DialDragSession(
      geometry: geometry,
      initialMinutes: 0,
      initialAngle: 0,
    );

    final updated = session.update(math.pi / 3);

    expect(updated, 10);
  });

  test('counterclockwise movement from zero stays at zero', () {
    final session = DialDragSession(
      geometry: geometry,
      initialMinutes: 0,
      initialAngle: 0,
    );

    final updated = session.update(math.pi * 2 - 0.1);

    expect(updated, 0);
  });

  test('counterclockwise movement can reduce selected minutes', () {
    final session = DialDragSession(
      geometry: geometry,
      initialMinutes: 30,
      initialAngle: math.pi,
    );

    final updated = session.update(math.pi / 2);

    expect(updated, 15);
  });

  test('crossing 12 o clock clockwise reaches sixty but not a second lap', () {
    final session = DialDragSession(
      geometry: geometry,
      initialMinutes: 59,
      initialAngle: geometry.angleForMinutes(59),
    );

    expect(session.update(0.02), 60);
    expect(session.update(0.12), 60);
  });

  test('values above maximum clamp to 60 minutes', () {
    final session = DialDragSession(
      geometry: geometry,
      initialMinutes: 60,
      initialAngle: geometry.angleForMinutes(60),
    );

    expect(session.update(math.pi / 2), 60);
  });

  test('counterclockwise movement after max overshoot reduces immediately', () {
    final session = DialDragSession(
      geometry: geometry,
      initialMinutes: 60,
      initialAngle: geometry.angleForMinutes(60),
    );

    expect(session.update(math.pi), 60);
    expect(session.update(0.1), 31);
  });
}
