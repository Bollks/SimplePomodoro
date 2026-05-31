import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pomodoro/src/dial/dial_drag_session.dart';
import 'package:simple_pomodoro/src/dial/dial_geometry.dart';

void main() {
  const geometry = DialGeometry();

  test('clockwise movement increases selected minutes', () {
    final session = DialDragSession(
      geometry: geometry,
      initialMinutes: 5,
      initialAngle: math.pi / 6,
    );

    final updated = session.update(math.pi / 3);

    expect(updated, 10);
  });

  test('crossing 12 o clock clockwise can enter the second lap', () {
    final session = DialDragSession(
      geometry: geometry,
      initialMinutes: 59,
      initialAngle: geometry.angleForMinutes(59),
    );

    expect(session.update(0.02), 60);
    expect(session.update(0.12), 61);
  });

  test('dragging below minimum clamps to 5 minutes', () {
    final session = DialDragSession(
      geometry: geometry,
      initialMinutes: 5,
      initialAngle: math.pi / 6,
    );

    final updated = session.update(0.01);

    expect(updated, 5);
  });

  test('dragging above maximum clamps to 120 minutes', () {
    final session = DialDragSession(
      geometry: geometry,
      initialMinutes: 119,
      initialAngle: geometry.angleForMinutes(119),
    );

    expect(session.update(0.02), 120);
    expect(session.update(0.20), 120);
  });
}
