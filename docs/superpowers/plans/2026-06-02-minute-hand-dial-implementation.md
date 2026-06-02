# Minute Hand Dial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the center-button and green-sector timer with a watch-style minute hand that is dragged to select `0-60min` and starts on release when the selected value is greater than zero.

**Architecture:** Keep the existing Flutter single-page app. Move time rules into `DialConstants`, keep state transitions in `DialTimerController`, keep angle and hit-testing math in `DialGeometry`, keep drag accumulation in `DialDragSession`, and introduce a focused `MinuteHand` widget for SVG asset rendering and rotation. `DialTimerPage` coordinates gesture flow and timer lifecycle.

**Tech Stack:** Flutter, Dart, `flutter_test`, `flutter_svg`, existing Android feedback bridge.

---

## File Structure

- Modify `lib/src/dial/dial_constants.dart`: set timer bounds to `0-60`, remove the old `5-120` model, and add minute-hand geometry factors.
- Modify `lib/src/dial/dial_timer_controller.dart`: default to `0min`, ignore starts at `0min`, and reset completion/stop to `0min`.
- Modify `lib/src/dial/dial_geometry.dart`: provide one-lap minute and angle mapping plus minute-hand hit testing.
- Modify `lib/src/dial/dial_drag_session.dart`: clamp accumulated drag to one lap instead of allowing a second lap.
- Create `lib/src/dial/minute_hand.dart`: render the SVG hand and rotate it around the dial center.
- Modify `lib/src/dial/dial_painter.dart`: remove green sector, edge shadow, and center button drawing; keep optional shell and five-minute markers.
- Modify `lib/src/dial/dial_timer_page.dart`: remove tap-to-start/reset, use hand dragging, and start on drag release when `selectedMinutes > 0`.
- Create `assets/hands/minute_hand_placeholder.svg`: replaceable minute-hand placeholder asset.
- Modify `pubspec.yaml` and `pubspec.lock`: add `flutter_svg` and declare the hand asset.
- Modify tests under `test/dial/`: update existing behavior tests and add focused hand rendering coverage.
- Modify `README.md`: reflect the minute-hand interaction after implementation.

## Task 1: Update Timer Rules and Controller

**Files:**
- Modify: `test/dial/dial_timer_controller_test.dart`
- Modify: `lib/src/dial/dial_constants.dart`
- Modify: `lib/src/dial/dial_timer_controller.dart`

- [ ] **Step 1: Write failing controller tests**

Replace `test/dial/dial_timer_controller_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pomodoro/src/dial/dial_constants.dart';
import 'package:simple_pomodoro/src/dial/dial_timer_controller.dart';

void main() {
  test('starts at the zero minute idle state', () {
    final controller = DialTimerController();

    expect(controller.phase, DialTimerPhase.idle);
    expect(controller.selectedMinutes, 0);
    expect(controller.remaining, Duration.zero);
    expect(controller.visualMinutes, 0);
  });

  test('setSelectedMinutes clamps and updates remaining while idle', () {
    final controller = DialTimerController();

    controller.setSelectedMinutes(-1);
    expect(controller.selectedMinutes, 0);
    expect(controller.remaining, Duration.zero);

    controller.setSelectedMinutes(45);
    expect(controller.selectedMinutes, 45);
    expect(controller.remaining, const Duration(minutes: 45));

    controller.setSelectedMinutes(61);
    expect(controller.selectedMinutes, 60);
    expect(controller.remaining, const Duration(minutes: 60));
  });

  test('start ignores zero minutes', () {
    final controller = DialTimerController();

    controller.start(DateTime(2026, 6, 2, 12));

    expect(controller.phase, DialTimerPhase.idle);
    expect(controller.remaining, Duration.zero);
  });

  test('start records running phase and end time for positive minutes', () {
    final controller = DialTimerController()..setSelectedMinutes(25);
    final now = DateTime(2026, 6, 2, 12);

    controller.start(now);

    expect(controller.phase, DialTimerPhase.running);
    expect(controller.remaining, const Duration(minutes: 25));
  });

  test('syncWithClock calculates remaining time from real time', () {
    final controller = DialTimerController()..setSelectedMinutes(25);
    final now = DateTime(2026, 6, 2, 12);

    controller.start(now);
    final completed = controller.syncWithClock(
      now.add(const Duration(minutes: 4, seconds: 30)),
    );

    expect(completed, isFalse);
    expect(controller.remaining, const Duration(minutes: 20, seconds: 30));
    expect(controller.visualMinutes, closeTo(20.5, 0.001));
  });

  test('running timer continues below one minute and then completes', () {
    final controller = DialTimerController()..setSelectedMinutes(1);
    final now = DateTime(2026, 6, 2, 12);

    controller.start(now);
    final stillRunning = controller.syncWithClock(
      now.add(const Duration(seconds: 30)),
    );

    expect(stillRunning, isFalse);
    expect(controller.phase, DialTimerPhase.running);
    expect(controller.remaining, const Duration(seconds: 30));
    expect(controller.visualMinutes, closeTo(0.5, 0.001));

    final completed = controller.syncWithClock(
      now.add(const Duration(minutes: 1)),
    );

    expect(completed, isTrue);
    expect(controller.phase, DialTimerPhase.idle);
    expect(controller.remaining, Duration.zero);
  });

  test('completion resets to zero minutes', () {
    final controller = DialTimerController()..setSelectedMinutes(6);
    final now = DateTime(2026, 6, 2, 12);

    controller.start(now);
    final completed = controller.syncWithClock(
      now.add(const Duration(minutes: 6, seconds: 1)),
    );

    expect(completed, isTrue);
    expect(controller.phase, DialTimerPhase.idle);
    expect(controller.selectedMinutes, 0);
    expect(controller.remaining, Duration.zero);
  });

  test('stopAndReset resets a running timer to zero minutes', () {
    final controller = DialTimerController()..setSelectedMinutes(40);

    controller.start(DateTime(2026, 6, 2, 12));
    controller.stopAndReset();

    expect(controller.phase, DialTimerPhase.idle);
    expect(controller.selectedMinutes, 0);
    expect(controller.remaining, Duration.zero);
  });
}
```

- [ ] **Step 2: Run controller tests and verify they fail**

Run:

```powershell
flutter test test/dial/dial_timer_controller_test.dart
```

Expected: failures show the existing controller still defaults to `5min`, clamps to `5-120`, and starts at zero when it should remain idle.

- [ ] **Step 3: Implement timer constants**

Replace `lib/src/dial/dial_constants.dart` with:

```dart
enum DialTimerPhase {
  idle,
  running,
}

class DialConstants {
  const DialConstants._();

  static const int defaultMinutes = 0;
  static const int minMinutes = 0;
  static const int maxMinutes = 60;
  static const int minutesPerLap = 60;

  static const double dialOuterRadiusFactor = 0.48;
  static const double dialInnerRadiusFactor = 0.18;
  static const double minuteHandTipRadiusFactor = 0.38;
  static const double minuteHandTailRadiusFactor = 0.05;
  static const double minuteHandTouchWidthFactor = 0.055;
  static const double minuteHandHubRadiusFactor = 0.11;
}
```

- [ ] **Step 4: Implement controller rules**

Replace `lib/src/dial/dial_timer_controller.dart` with:

```dart
import 'package:flutter/foundation.dart';

import 'dial_constants.dart';
import 'dial_geometry.dart';

class DialTimerController extends ChangeNotifier {
  DialTimerController({DialGeometry? geometry})
    : _geometry = geometry ?? const DialGeometry();

  final DialGeometry _geometry;

  DialTimerPhase _phase = DialTimerPhase.idle;
  int _selectedMinutes = DialConstants.defaultMinutes;
  Duration _remaining = Duration.zero;
  DateTime? _endsAt;

  DialTimerPhase get phase => _phase;
  int get selectedMinutes => _selectedMinutes;
  Duration get remaining => _remaining;
  bool get isRunning => _phase == DialTimerPhase.running;

  double get visualMinutes {
    if (_phase == DialTimerPhase.idle) {
      return _selectedMinutes.toDouble();
    }
    return _remaining.inMilliseconds / Duration.millisecondsPerMinute;
  }

  void setSelectedMinutes(int minutes) {
    if (_phase == DialTimerPhase.running) {
      return;
    }

    final next = _geometry.clampMinutes(minutes);
    final nextRemaining = Duration(minutes: next);
    if (next == _selectedMinutes && _remaining == nextRemaining) {
      return;
    }

    _selectedMinutes = next;
    _remaining = nextRemaining;
    notifyListeners();
  }

  void start(DateTime now) {
    if (_phase == DialTimerPhase.running || _selectedMinutes <= 0) {
      return;
    }

    _phase = DialTimerPhase.running;
    _remaining = Duration(minutes: _selectedMinutes);
    _endsAt = now.add(_remaining);
    notifyListeners();
  }

  bool syncWithClock(DateTime now) {
    if (_phase != DialTimerPhase.running || _endsAt == null) {
      return false;
    }

    final nextRemaining = _endsAt!.difference(now);
    if (!nextRemaining.isNegative && nextRemaining > Duration.zero) {
      _remaining = nextRemaining;
      notifyListeners();
      return false;
    }

    _resetToDefault();
    notifyListeners();
    return true;
  }

  void stopAndReset() {
    if (_phase == DialTimerPhase.idle &&
        _selectedMinutes == DialConstants.defaultMinutes &&
        _remaining == Duration.zero) {
      return;
    }

    _resetToDefault();
    notifyListeners();
  }

  void _resetToDefault() {
    _phase = DialTimerPhase.idle;
    _selectedMinutes = DialConstants.defaultMinutes;
    _remaining = Duration.zero;
    _endsAt = null;
  }
}
```

- [ ] **Step 5: Run controller tests and verify they pass**

Run:

```powershell
flutter test test/dial/dial_timer_controller_test.dart
```

Expected: all controller tests pass.

- [ ] **Step 6: Commit timer rules**

Run:

```powershell
git add lib/src/dial/dial_constants.dart lib/src/dial/dial_timer_controller.dart test/dial/dial_timer_controller_test.dart
git commit -m "feat: set dial timer range to zero through sixty"
```

## Task 2: Update Dial Geometry for One-Lap Minute Hand Interaction

**Files:**
- Modify: `test/dial/dial_geometry_test.dart`
- Modify: `lib/src/dial/dial_geometry.dart`

- [ ] **Step 1: Write failing geometry tests**

Replace `test/dial/dial_geometry_test.dart` with:

```dart
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
```

- [ ] **Step 2: Run geometry tests and verify they fail**

Run:

```powershell
flutter test test/dial/dial_geometry_test.dart
```

Expected: failures show the old `5-120` clamp, no `minutesForAngle`, and no `isOnMinuteHand`.

- [ ] **Step 3: Implement one-lap geometry and hand hit testing**

Replace `lib/src/dial/dial_geometry.dart` with:

```dart
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'dial_constants.dart';

class DialGeometry {
  const DialGeometry();

  static const double twoPi = math.pi * 2;

  int clampMinutes(num minutes) {
    return minutes
        .round()
        .clamp(DialConstants.minMinutes, DialConstants.maxMinutes)
        .toInt();
  }

  int snapMinutes(num minutes) {
    return clampMinutes(minutes.round());
  }

  double angleForMinutes(num minutes) {
    final clamped = _clampVisualMinutes(minutes);
    final minuteOnDial = clamped % DialConstants.minutesPerLap;
    return minuteOnDial == 0
        ? 0
        : minuteOnDial / DialConstants.minutesPerLap * twoPi;
  }

  int minutesForAngle(double angle) {
    final normalized = normalizeAngle(angle);
    final rawMinutes = normalized / twoPi * DialConstants.minutesPerLap;
    return clampMinutes(rawMinutes);
  }

  double displaySweepForMinutes(num minutes) {
    final clamped = _clampVisualMinutes(minutes);
    return clamped / DialConstants.minutesPerLap * twoPi;
  }

  double _clampVisualMinutes(num minutes) {
    return minutes
        .toDouble()
        .clamp(
          DialConstants.minMinutes.toDouble(),
          DialConstants.maxMinutes.toDouble(),
        )
        .toDouble();
  }

  double angleFromCenter(Size size, Offset position) {
    final center = Offset(size.width / 2, size.height / 2);
    final vector = position - center;
    final raw = math.atan2(vector.dy, vector.dx) + math.pi / 2;
    return normalizeAngle(raw);
  }

  double normalizeAngle(double angle) {
    var normalized = angle % twoPi;
    if (normalized < 0) {
      normalized += twoPi;
    }
    return normalized;
  }

  double shortestClockwiseDelta(double previousAngle, double currentAngle) {
    var delta = currentAngle - previousAngle;
    if (delta > math.pi) {
      delta -= twoPi;
    }
    if (delta < -math.pi) {
      delta += twoPi;
    }
    return delta;
  }

  Offset centerOf(Size size) {
    return Offset(size.width / 2, size.height / 2);
  }

  double outerRadiusFor(Size size) {
    return math.min(size.width, size.height) *
        DialConstants.dialOuterRadiusFactor;
  }

  double innerRadiusFor(Size size) {
    return math.min(size.width, size.height) *
        DialConstants.dialInnerRadiusFactor;
  }

  Offset pointForMinutes(Size size, num minutes, {double radiusFactor = 0.42}) {
    final center = centerOf(size);
    final radius = math.min(size.width, size.height) * radiusFactor;
    final angle = angleForMinutes(minutes);
    return Offset(
      center.dx + math.sin(angle) * radius,
      center.dy - math.cos(angle) * radius,
    );
  }

  bool isOnMinuteHand({
    required Size size,
    required Offset position,
    required num minutes,
  }) {
    final shortestSide = math.min(size.width, size.height);
    final center = centerOf(size);
    final hubRadius = shortestSide * DialConstants.minuteHandHubRadiusFactor;
    if ((position - center).distance <= hubRadius) {
      return true;
    }

    final angle = angleForMinutes(minutes);
    final direction = Offset(math.sin(angle), -math.cos(angle));
    final start =
        center - direction * shortestSide * DialConstants.minuteHandTailRadiusFactor;
    final end =
        center + direction * shortestSide * DialConstants.minuteHandTipRadiusFactor;
    final touchWidth = shortestSide * DialConstants.minuteHandTouchWidthFactor;

    return _distanceToSegment(position, start, end) <= touchWidth;
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
    if (lengthSquared == 0) {
      return (point - start).distance;
    }

    final relative = point - start;
    final projection =
        (relative.dx * segment.dx + relative.dy * segment.dy) / lengthSquared;
    final clampedProjection = projection.clamp(0.0, 1.0).toDouble();
    final closest = start + segment * clampedProjection;
    return (point - closest).distance;
  }
}
```

- [ ] **Step 4: Run geometry tests and verify they pass**

Run:

```powershell
flutter test test/dial/dial_geometry_test.dart
```

Expected: all geometry tests pass.

- [ ] **Step 5: Commit geometry changes**

Run:

```powershell
git add lib/src/dial/dial_geometry.dart test/dial/dial_geometry_test.dart
git commit -m "feat: add minute hand geometry"
```

## Task 3: Restrict Drag Tracking to One Lap

**Files:**
- Modify: `test/dial/dial_drag_session_test.dart`
- Modify: `lib/src/dial/dial_drag_session.dart`

- [ ] **Step 1: Write failing drag session tests**

Replace `test/dial/dial_drag_session_test.dart` with:

```dart
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
      initialMinutes: 55,
      initialAngle: geometry.angleForMinutes(55),
    );

    expect(session.update(6.20), 59);
    expect(session.update(0.02), 60);
    expect(session.update(0.20), 60);
  });

  test('dragging above maximum clamps to 60 minutes', () {
    final session = DialDragSession(
      geometry: geometry,
      initialMinutes: 59,
      initialAngle: geometry.angleForMinutes(59),
    );

    expect(session.update(0.02), 60);
    expect(session.update(0.40), 60);
  });
}
```

- [ ] **Step 2: Run drag tests and verify they fail**

Run:

```powershell
flutter test test/dial/dial_drag_session_test.dart
```

Expected: failures show the old session still assumes minimum `5min` and permits values above one lap.

- [ ] **Step 3: Implement one-lap drag tracking**

Replace `lib/src/dial/dial_drag_session.dart` with:

```dart
import 'dart:math' as math;

import 'dial_geometry.dart';

class DialDragSession {
  DialDragSession({
    required this.geometry,
    required int initialMinutes,
    required double initialAngle,
  }) : _baseMinutes = geometry.clampMinutes(initialMinutes),
       _lastAngle = geometry.normalizeAngle(initialAngle);

  final DialGeometry geometry;
  final int _baseMinutes;

  double _lastAngle;
  double _accumulatedRadians = 0;

  int update(double currentAngle) {
    final normalized = geometry.normalizeAngle(currentAngle);
    _accumulatedRadians += geometry.shortestClockwiseDelta(
      _lastAngle,
      normalized,
    );
    _lastAngle = normalized;

    final maxRadians = DialGeometry.twoPi;
    _accumulatedRadians = math.max(
      -_baseMinutes / 60 * maxRadians,
      math.min((60 - _baseMinutes) / 60 * maxRadians, _accumulatedRadians),
    );

    final rawMinutes =
        _baseMinutes + _accumulatedRadians / DialGeometry.twoPi * 60;
    return geometry.snapMinutes(rawMinutes);
  }
}
```

- [ ] **Step 4: Run drag tests and verify they pass**

Run:

```powershell
flutter test test/dial/dial_drag_session_test.dart
```

Expected: all drag session tests pass.

- [ ] **Step 5: Commit drag tracking changes**

Run:

```powershell
git add lib/src/dial/dial_drag_session.dart test/dial/dial_drag_session_test.dart
git commit -m "feat: limit dial drag to one lap"
```

## Task 4: Add Minute Hand Asset and Widget

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Create: `assets/hands/minute_hand_placeholder.svg`
- Create: `lib/src/dial/minute_hand.dart`
- Create: `test/dial/minute_hand_test.dart`

- [ ] **Step 1: Add the SVG dependency**

Run:

```powershell
flutter pub add flutter_svg
```

Expected: `pubspec.yaml` includes `flutter_svg`, and `pubspec.lock` is updated.

- [ ] **Step 2: Write failing MinuteHand widget tests**

Create `test/dial/minute_hand_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pomodoro/src/dial/dial_geometry.dart';
import 'package:simple_pomodoro/src/dial/minute_hand.dart';

void main() {
  testWidgets('renders the configured hand asset inside a rotation transform', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.square(
          dimension: 240,
          child: MinuteHand(
            assetName: 'assets/hands/minute_hand_placeholder.svg',
            minutes: 15,
            geometry: DialGeometry(),
          ),
        ),
      ),
    );

    final hand = tester.widget<MinuteHand>(find.byType(MinuteHand));
    expect(hand.assetName, 'assets/hands/minute_hand_placeholder.svg');
    expect(hand.minutes, 15);
    expect(find.byKey(const Key('minute-hand-rotation')), findsOneWidget);
    expect(find.byKey(const Key('minute-hand-artwork')), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run MinuteHand test and verify it fails**

Run:

```powershell
flutter test test/dial/minute_hand_test.dart
```

Expected: failure because `lib/src/dial/minute_hand.dart` does not exist yet.

- [ ] **Step 4: Create the placeholder SVG asset**

Create `assets/hands/minute_hand_placeholder.svg`:

```xml
<svg width="1024" height="1024" viewBox="0 0 1024 1024" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="handShadow" x="430" y="110" width="170" height="470" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">
      <feDropShadow dx="8" dy="12" stdDeviation="10" flood-color="#1E2428" flood-opacity="0.28"/>
    </filter>
    <linearGradient id="handMetal" x1="482" y1="126" x2="546" y2="552" gradientUnits="userSpaceOnUse">
      <stop stop-color="#59646A"/>
      <stop offset="0.5" stop-color="#20282D"/>
      <stop offset="1" stop-color="#4F5A5F"/>
    </linearGradient>
    <radialGradient id="hubMetal" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(512 512) rotate(90) scale(72)">
      <stop stop-color="#D9DDD7"/>
      <stop offset="0.62" stop-color="#AEB5AE"/>
      <stop offset="1" stop-color="#7D867E"/>
    </radialGradient>
  </defs>
  <g filter="url(#handShadow)">
    <path d="M512 126L548 512H476L512 126Z" fill="url(#handMetal)"/>
    <path d="M512 126L526 512H498L512 126Z" fill="#E7EBE8" fill-opacity="0.30"/>
    <path d="M512 512L536 568H488L512 512Z" fill="#2A3338"/>
  </g>
  <circle cx="512" cy="512" r="76" fill="url(#hubMetal)"/>
  <circle cx="512" cy="512" r="76" stroke="#7D867E" stroke-width="10"/>
  <circle cx="512" cy="512" r="20" fill="#646E67"/>
</svg>
```

- [ ] **Step 5: Declare the hand asset**

Ensure the `flutter.assets` block in `pubspec.yaml` includes:

```yaml
  assets:
    - assets/cases/case_01.webp
    - assets/dials/fritillaria.webp
    - assets/hands/minute_hand_placeholder.svg
```

- [ ] **Step 6: Implement the MinuteHand widget**

Create `lib/src/dial/minute_hand.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'dial_geometry.dart';

class MinuteHand extends StatelessWidget {
  const MinuteHand({
    required this.assetName,
    required this.minutes,
    required this.geometry,
    super.key,
  });

  final String assetName;
  final double minutes;
  final DialGeometry geometry;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      key: const Key('minute-hand-rotation'),
      angle: geometry.angleForMinutes(minutes),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        assetName,
        key: const Key('minute-hand-artwork'),
        fit: BoxFit.contain,
      ),
    );
  }
}
```

- [ ] **Step 7: Run MinuteHand test and verify it passes**

Run:

```powershell
flutter test test/dial/minute_hand_test.dart
```

Expected: all MinuteHand tests pass.

- [ ] **Step 8: Commit hand asset and widget**

Run:

```powershell
git add pubspec.yaml pubspec.lock assets/hands/minute_hand_placeholder.svg lib/src/dial/minute_hand.dart test/dial/minute_hand_test.dart
git commit -m "feat: add rotating minute hand asset"
```

## Task 5: Replace Center Button and Sector Interaction on the Page

**Files:**
- Modify: `test/dial/dial_timer_page_test.dart`
- Modify: `lib/src/dial/dial_painter.dart`
- Modify: `lib/src/dial/dial_timer_page.dart`
- Modify: `README.md`

- [ ] **Step 1: Write failing page tests**

Replace `test/dial/dial_timer_page_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pomodoro/src/dial/dial_geometry.dart';
import 'package:simple_pomodoro/src/dial/dial_painter.dart';
import 'package:simple_pomodoro/src/dial/dial_timer_page.dart';
import 'package:simple_pomodoro/src/dial/minute_hand.dart';
import 'package:simple_pomodoro/src/feedback/feedback_service.dart';

class FakeFeedbackService extends FeedbackService {
  int selections = 0;
  int completions = 0;

  @override
  Future<void> selectionChanged() async {
    selections += 1;
  }

  @override
  Future<void> completed() async {
    completions += 1;
  }
}

void main() {
  Finder findDialPaint() {
    return find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is DialPainter,
    );
  }

  AnimatedContainer backgroundContainer(WidgetTester tester) {
    return tester.widget<AnimatedContainer>(
      find.byKey(const Key('dial-timer-background')),
    );
  }

  Color? backgroundColorOf(AnimatedContainer container) {
    final decoration = container.decoration;
    return decoration is BoxDecoration ? decoration.color : null;
  }

  testWidgets('uses dial face, minute hand, and case artwork', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: FakeFeedbackService())),
    );

    expect(find.byKey(const Key('dial-face-artwork')), findsOneWidget);
    expect(find.byType(MinuteHand), findsOneWidget);
    expect(find.byKey(const Key('dial-case-artwork')), findsOneWidget);

    final face = tester.widget<Image>(
      find.byKey(const Key('dial-face-artwork')),
    );
    final hand = tester.widget<MinuteHand>(find.byType(MinuteHand));
    final shell = tester.widget<Image>(
      find.byKey(const Key('dial-case-artwork')),
    );

    expect(
      (face.image as AssetImage).assetName,
      'assets/dials/fritillaria.webp',
    );
    expect(hand.assetName, 'assets/hands/minute_hand_placeholder.svg');
    expect((shell.image as AssetImage).assetName, 'assets/cases/case_01.webp');
  });

  testWidgets('renders without visible text controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: FakeFeedbackService())),
    );

    expect(findDialPaint(), findsOneWidget);
    expect(find.text('Start'), findsNothing);
    expect(find.text('End'), findsNothing);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('center tap no longer starts the timer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: FakeFeedbackService())),
    );

    expect(
      backgroundColorOf(backgroundContainer(tester)),
      const Color(0xFFF5F1E8),
    );

    await tester.tapAt(tester.getCenter(findDialPaint()));
    await tester.pump();

    expect(
      backgroundColorOf(backgroundContainer(tester)),
      const Color(0xFFF5F1E8),
    );
  });

  testWidgets('dragging the minute hand starts on release', (tester) async {
    final feedbackService = FakeFeedbackService();
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: feedbackService)),
    );

    const geometry = DialGeometry();
    final dialFinder = findDialPaint();
    final dialTopLeft = tester.getTopLeft(dialFinder);
    final dialSize = tester.getSize(dialFinder);
    final start =
        dialTopLeft + geometry.pointForMinutes(dialSize, 0, radiusFactor: 0.30);
    final end =
        dialTopLeft + geometry.pointForMinutes(dialSize, 15, radiusFactor: 0.30);

    await tester.dragFrom(start, end - start);
    await tester.pump();

    expect(backgroundContainer(tester).duration, const Duration(milliseconds: 200));
    expect(backgroundColorOf(backgroundContainer(tester)), Colors.black);
    expect(feedbackService.selections, greaterThan(0));
  });

  testWidgets('dragging away from the minute hand does not start', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: FakeFeedbackService())),
    );

    const geometry = DialGeometry();
    final dialFinder = findDialPaint();
    final dialTopLeft = tester.getTopLeft(dialFinder);
    final dialSize = tester.getSize(dialFinder);
    final start =
        dialTopLeft + geometry.pointForMinutes(dialSize, 30, radiusFactor: 0.30);
    final end =
        dialTopLeft + geometry.pointForMinutes(dialSize, 45, radiusFactor: 0.30);

    await tester.dragFrom(start, end - start);
    await tester.pump();

    expect(
      backgroundColorOf(backgroundContainer(tester)),
      const Color(0xFFF5F1E8),
    );
  });
}
```

- [ ] **Step 2: Run page tests and verify they fail**

Run:

```powershell
flutter test test/dial/dial_timer_page_test.dart
```

Expected: failures show there is no `MinuteHand`, center tap still starts, and dragging still depends on the sector edge.

- [ ] **Step 3: Replace the painter with marker-only drawing**

Replace `lib/src/dial/dial_painter.dart` with:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dial_geometry.dart';

class DialPainter extends CustomPainter {
  DialPainter({
    this.geometry = const DialGeometry(),
    this.drawShell = true,
  });

  final DialGeometry geometry;
  final bool drawShell;

  @override
  void paint(Canvas canvas, Size size) {
    final center = geometry.centerOf(size);
    final radius = geometry.outerRadiusFor(size);

    if (drawShell) {
      _drawShell(canvas, center, radius);
    }
    _drawMarkers(canvas, center, radius);
  }

  void _drawShell(Canvas canvas, Offset center, double radius) {
    final shellPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFF8F6EF), Color(0xFFD9DAD6), Color(0xFFB9BDB8)],
        stops: const [0.72, 0.88, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, shellPaint);

    final facePaint = Paint()..color = const Color(0xFFFBF8F0);
    canvas.drawCircle(center, radius * 0.91, facePaint);

    final rimPaint = Paint()
      ..color = const Color(0xFF9EA49D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.012;
    canvas.drawCircle(center, radius * 0.91, rimPaint);
  }

  void _drawMarkers(Canvas canvas, Offset center, double radius) {
    final markerPaint = Paint()
      ..color = const Color(0xFF485158)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.017;

    for (var index = 0; index < 12; index += 1) {
      final angle = index / 12 * math.pi * 2;
      final outer = Offset(
        center.dx + math.sin(angle) * radius * 0.78,
        center.dy - math.cos(angle) * radius * 0.78,
      );
      final inner = Offset(
        center.dx + math.sin(angle) * radius * 0.63,
        center.dy - math.cos(angle) * radius * 0.63,
      );
      canvas.drawLine(inner, outer, markerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant DialPainter oldDelegate) {
    return oldDelegate.drawShell != drawShell ||
        oldDelegate.geometry != geometry;
  }
}
```

- [ ] **Step 4: Implement hand-driven page gestures**

Replace `lib/src/dial/dial_timer_page.dart` with:

```dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../feedback/feedback_service.dart';
import 'dial_drag_session.dart';
import 'dial_geometry.dart';
import 'dial_painter.dart';
import 'dial_timer_controller.dart';
import 'minute_hand.dart';

class DialTimerPage extends StatefulWidget {
  const DialTimerPage({required this.feedbackService, super.key});

  final FeedbackService feedbackService;

  @override
  State<DialTimerPage> createState() => _DialTimerPageState();
}

class _DialTimerPageState extends State<DialTimerPage>
    with WidgetsBindingObserver {
  static const Color _idleBackgroundColor = Color(0xFFF5F1E8);
  static const Color _runningBackgroundColor = Colors.black;
  static const Duration _backgroundTransitionDuration = Duration(
    milliseconds: 200,
  );
  static const String _dialFaceAsset = 'assets/dials/fritillaria.webp';
  static const String _dialCaseAsset = 'assets/cases/case_01.webp';
  static const String _minuteHandAsset =
      'assets/hands/minute_hand_placeholder.svg';

  final DialGeometry _geometry = const DialGeometry();
  late final DialTimerController _controller;

  Timer? _ticker;
  DialDragSession? _dragSession;
  Size _dialSize = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = DialTimerController(geometry: _geometry);
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncTimer();
    }
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _syncTimer();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _syncTimer() async {
    final completed = _controller.syncWithClock(DateTime.now());
    if (completed) {
      _stopTicker();
      await widget.feedbackService.completed();
    }
  }

  void _handlePanStart(DragStartDetails details) {
    if (_controller.isRunning) {
      return;
    }

    final position = details.localPosition;
    if (!_geometry.isOnMinuteHand(
      size: _dialSize,
      position: position,
      minutes: _controller.selectedMinutes,
    )) {
      return;
    }

    _dragSession = DialDragSession(
      geometry: _geometry,
      initialMinutes: _controller.selectedMinutes,
      initialAngle: _geometry.angleFromCenter(_dialSize, position),
    );
  }

  Future<void> _handlePanUpdate(DragUpdateDetails details) async {
    final session = _dragSession;
    if (session == null || _controller.isRunning) {
      return;
    }

    final angle = _geometry.angleFromCenter(_dialSize, details.localPosition);
    final nextMinutes = session.update(angle);
    final previousMinutes = _controller.selectedMinutes;
    _controller.setSelectedMinutes(nextMinutes);

    if (nextMinutes != previousMinutes) {
      await widget.feedbackService.selectionChanged();
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    final shouldStart =
        _dragSession != null &&
        !_controller.isRunning &&
        _controller.selectedMinutes > 0;
    _dragSession = null;

    if (!shouldStart) {
      return;
    }

    _controller.start(DateTime.now());
    _startTicker();
  }

  void _handlePanCancel() {
    _dragSession = null;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _controller.isRunning
        ? _runningBackgroundColor
        : _idleBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnimatedContainer(
        key: const Key('dial-timer-background'),
        duration: _backgroundTransitionDuration,
        decoration: BoxDecoration(color: backgroundColor),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final shortest = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final dialSide = shortest.clamp(260.0, 460.0).toDouble() * 0.9;
                _dialSize = Size.square(dialSide);

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _handlePanStart,
                  onPanUpdate: _handlePanUpdate,
                  onPanEnd: _handlePanEnd,
                  onPanCancel: _handlePanCancel,
                  child: SizedBox.square(
                    dimension: dialSide,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _dialFaceAsset,
                          key: const Key('dial-face-artwork'),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                        CustomPaint(
                          painter: DialPainter(
                            geometry: _geometry,
                            drawShell: false,
                          ),
                        ),
                        MinuteHand(
                          assetName: _minuteHandAsset,
                          minutes: _controller.visualMinutes,
                          geometry: _geometry,
                        ),
                        Image.asset(
                          _dialCaseAsset,
                          key: const Key('dial-case-artwork'),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Update README behavior text**

Replace the feature list in `README.md` with:

```markdown
## Features

- Drag the minute hand to choose 1 to 60 minutes.
- Release the hand to start the timer.
- Keep 12 o'clock as the zero-minute idle position.
- Show the countdown through the returning minute hand.
- Play completion feedback with sound and vibration.
```

- [ ] **Step 6: Run page tests and verify they pass**

Run:

```powershell
flutter test test/dial/dial_timer_page_test.dart
```

Expected: all page widget tests pass.

- [ ] **Step 7: Run all dial tests**

Run:

```powershell
flutter test test/dial
```

Expected: all dial tests pass.

- [ ] **Step 8: Commit page interaction changes**

Run:

```powershell
git add README.md lib/src/dial/dial_painter.dart lib/src/dial/dial_timer_page.dart test/dial/dial_timer_page_test.dart
git commit -m "feat: start timer from minute hand drag"
```

## Task 6: Final Verification

**Files:**
- No planned source changes.

- [ ] **Step 1: Run analyzer**

Run:

```powershell
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 2: Run full test suite**

Run:

```powershell
flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Build Android debug APK**

Run:

```powershell
flutter build apk --debug
```

Expected: debug APK exists at `build/app/outputs/flutter-apk/app-debug.apk`. Do not commit anything under `build/`.

- [ ] **Step 4: Review final git status**

Run:

```powershell
git status -sb
git diff --stat
```

Expected: no uncommitted source changes. `build/` remains ignored.

- [ ] **Step 5: Commit verification-only fixes if needed**

If the analyzer, tests, or debug build required source/config changes, commit only those files:

```powershell
git add README.md lib pubspec.yaml pubspec.lock test assets/hands
git commit -m "chore: verify minute hand dial build"
```

Expected: skip this commit if Step 1 through Step 4 required no file changes.

## Self-Review

- Spec coverage: Tasks cover `0-60min`, `0min` idle, start-on-release, no second lap, no center button, no green range, hand asset, hand hit testing, running countdown hand movement, completion reset to zero, tests, and verification.
- Placeholder scan: plan contains no unresolved work markers. The word `placeholder` appears only in the explicit replaceable asset filename `minute_hand_placeholder.svg`.
- Type consistency: `MinuteHand`, `DialGeometry.minutesForAngle`, `DialGeometry.isOnMinuteHand`, and the revised `DialPainter` constructor are used consistently across tests and implementation steps.
