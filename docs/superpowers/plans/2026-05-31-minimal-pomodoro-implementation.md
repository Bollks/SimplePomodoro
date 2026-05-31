# Minimal Pomodoro Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first Android APK version of the minimalist Flutter pomodoro timer defined in `docs/superpowers/specs/2026-05-31-pomodoro-design.md`.

**Architecture:** Initialize a Flutter app, keep the timer as a single page, and isolate the hard parts into small units: geometry, drag tracking, timer state, drawing, and feedback. The dial renderer is code-drawn in the first version but structured so static art assets can replace the shell, face, markers, center button, and shadows without rewriting timer logic.

**Tech Stack:** Flutter, Dart, Android Kotlin `MethodChannel`, Flutter unit tests, Flutter widget tests.

---

## Execution Notes

- Current environment note from 2026-05-31: `flutter --version` failed because `flutter` is not on `PATH`.
- Install Flutter for Windows and Android development before executing implementation tasks. Use the official Flutter Android setup guide: <https://docs.flutter.dev/platform-integration/android/setup>.
- This plan uses Flutter `CustomPainter`, Flutter platform channels, and Flutter testing patterns. Reference docs:
  - <https://api.flutter.dev/flutter/rendering/CustomPainter-class.html>
  - <https://docs.flutter.dev/platform-integration/platform-channels>
  - <https://docs.flutter.dev/testing>
- Do not upload to GitHub unless the user explicitly asks. The user has already authorized pushing this planning work to `https://github.com/Bollks/SimplePomodoro.git`.

## File Structure

- Create `lib/main.dart`: app entry point.
- Create `lib/src/app/pomodoro_app.dart`: Material app shell.
- Create `lib/src/dial/dial_constants.dart`: timer constants and state enum.
- Create `lib/src/dial/dial_geometry.dart`: angle, minute, display sweep, hit testing, and drag delta math.
- Create `lib/src/dial/dial_drag_session.dart`: incremental two-lap drag tracking.
- Create `lib/src/dial/dial_timer_controller.dart`: idle/running timer state and real-time remaining calculation.
- Create `lib/src/dial/dial_painter.dart`: code-drawn dial renderer, prepared for future asset-backed rendering.
- Create `lib/src/dial/dial_timer_page.dart`: only screen, gesture handling, lifecycle sync, and timer ticker.
- Create `lib/src/feedback/feedback_service.dart`: haptic feedback and Android completion sound bridge.
- Modify `lib/src/app/pomodoro_app.dart`: wire the app shell to `DialTimerPage` after the page exists.
- Modify `android/app/src/main/kotlin/com/bollks/simple_pomodoro/MainActivity.kt`: Android default notification sound through `MethodChannel`.
- Modify `android/app/src/main/AndroidManifest.xml`: add normal vibration permission.
- Modify `.gitignore`: keep Flutter generated files and `.superpowers/` ignored.
- Create `test/dial/dial_geometry_test.dart`: geometry and hit-test unit tests.
- Create `test/dial/dial_drag_session_test.dart`: two-lap drag behavior tests.
- Create `test/dial/dial_timer_controller_test.dart`: timer state unit tests.
- Create `test/dial/dial_timer_page_test.dart`: page smoke tests.

## Task 1: Validate Flutter Toolchain

**Files:**
- No file changes.

- [ ] **Step 1: Check Flutter is available**

Run:

```powershell
flutter --version
```

Expected: prints a Flutter version. If PowerShell says `flutter` is not recognized, install Flutter for Windows and add Flutter to `PATH`.

- [ ] **Step 2: Check Android development readiness**

Run:

```powershell
flutter doctor
```

Expected: Flutter reports an Android toolchain. If Android licenses are missing, run:

```powershell
flutter doctor --android-licenses
```

- [ ] **Step 3: Confirm repository is clean before project generation**

Run:

```powershell
git status -sb
```

Expected: no uncommitted changes except the implementation plan if it has not been committed yet.

## Task 2: Initialize Flutter Project

**Files:**
- Create: `android/`
- Create: `lib/main.dart`
- Create: `pubspec.yaml`
- Create: `test/widget_test.dart`
- Modify: `.gitignore`

- [ ] **Step 1: Generate the Flutter app in the existing repository**

Run from the repository root:

```powershell
flutter create --org com.bollks --project-name simple_pomodoro --platforms android .
```

Expected: Flutter creates Android and Dart project files without deleting `docs/` or `开发路径.md`.

- [ ] **Step 2: Normalize `.gitignore`**

Ensure `.gitignore` contains these lines:

```gitignore
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
build/
.superpowers/

android/.gradle/
android/local.properties
```

- [ ] **Step 3: Remove the generated default widget test**

Delete only this explicit file path:

```powershell
Remove-Item "D:\Documents\Codex-Project\Pomodoro\test\widget_test.dart"
```

Expected: only `test/widget_test.dart` is removed. Do not delete directories or use recursive deletion.

- [ ] **Step 4: Run the generated app tests**

Run:

```powershell
flutter test
```

Expected: if `test/widget_test.dart` was removed and no tests exist yet, Flutter reports no tests or exits successfully after analysis setup.

- [ ] **Step 5: Commit the project scaffold**

Run:

```powershell
git add .gitignore pubspec.yaml lib/main.dart android test
git commit -m "chore: scaffold Flutter app"
```

Expected: one commit containing only the generated Flutter scaffold and `.gitignore` updates.

## Task 3: Add Dial Geometry Tests

**Files:**
- Create: `test/dial/dial_geometry_test.dart`
- Create: `lib/src/dial/dial_constants.dart`
- Create: `lib/src/dial/dial_geometry.dart`

- [ ] **Step 1: Write failing geometry tests**

Create `test/dial/dial_geometry_test.dart`:

```dart
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
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```powershell
flutter test test/dial/dial_geometry_test.dart
```

Expected: fails because `DialGeometry` does not exist.

- [ ] **Step 3: Add constants**

Create `lib/src/dial/dial_constants.dart`:

```dart
enum DialTimerPhase {
  idle,
  running,
}

class DialConstants {
  const DialConstants._();

  static const int defaultMinutes = 5;
  static const int minMinutes = 5;
  static const int maxMinutes = 120;
  static const int minutesPerLap = 60;

  static const double dialOuterRadiusFactor = 0.48;
  static const double dialInnerRadiusFactor = 0.18;
  static const double edgeTouchAngularTolerance = 0.24;
}
```

- [ ] **Step 4: Implement geometry**

Create `lib/src/dial/dial_geometry.dart`:

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
    final clamped = clampMinutes(minutes);
    final minuteOnDial = clamped % DialConstants.minutesPerLap;
    return minuteOnDial == 0
        ? 0
        : minuteOnDial / DialConstants.minutesPerLap * twoPi;
  }

  double displaySweepForMinutes(num minutes) {
    final clamped = clampMinutes(minutes);
    final visibleMinutes = math.min(clamped, DialConstants.minutesPerLap);
    return visibleMinutes / DialConstants.minutesPerLap * twoPi;
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
    return math.min(size.width, size.height) * DialConstants.dialOuterRadiusFactor;
  }

  double innerRadiusFor(Size size) {
    return math.min(size.width, size.height) * DialConstants.dialInnerRadiusFactor;
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

  bool isInsideCenterButton({
    required Size size,
    required Offset position,
  }) {
    final center = centerOf(size);
    final radius = math.min(size.width, size.height) * 0.15;
    return (position - center).distance <= radius;
  }

  bool isOnEdge({
    required Size size,
    required Offset position,
    required num minutes,
  }) {
    final center = centerOf(size);
    final distance = (position - center).distance;
    final outerRadius = outerRadiusFor(size);
    final innerRadius = innerRadiusFor(size);

    if (distance < innerRadius || distance > outerRadius) {
      return false;
    }

    final angle = angleFromCenter(size, position);
    final edgeAngle = angleForMinutes(minutes);
    final delta = shortestClockwiseDelta(edgeAngle, angle).abs();
    return delta <= DialConstants.edgeTouchAngularTolerance;
  }
}
```

- [ ] **Step 5: Run geometry tests**

Run:

```powershell
flutter test test/dial/dial_geometry_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Commit geometry**

Run:

```powershell
git add lib/src/dial/dial_constants.dart lib/src/dial/dial_geometry.dart test/dial/dial_geometry_test.dart
git commit -m "test: add dial geometry"
```

Expected: one focused geometry commit.

## Task 4: Add Two-Lap Drag Tracking

**Files:**
- Create: `test/dial/dial_drag_session_test.dart`
- Create: `lib/src/dial/dial_drag_session.dart`

- [ ] **Step 1: Write failing drag tests**

Create `test/dial/dial_drag_session_test.dart`:

```dart
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
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```powershell
flutter test test/dial/dial_drag_session_test.dart
```

Expected: fails because `DialDragSession` does not exist.

- [ ] **Step 3: Implement drag session**

Create `lib/src/dial/dial_drag_session.dart`:

```dart
import 'dial_geometry.dart';

class DialDragSession {
  DialDragSession({
    required this.geometry,
    required int initialMinutes,
    required double initialAngle,
  })  : _baseMinutes = geometry.clampMinutes(initialMinutes),
        _lastAngle = geometry.normalizeAngle(initialAngle);

  final DialGeometry geometry;
  final int _baseMinutes;

  double _lastAngle;
  double _accumulatedRadians = 0;

  int update(double currentAngle) {
    final normalized = geometry.normalizeAngle(currentAngle);
    _accumulatedRadians += geometry.shortestClockwiseDelta(_lastAngle, normalized);
    _lastAngle = normalized;

    final rawMinutes = _baseMinutes + _accumulatedRadians / DialGeometry.twoPi * 60;
    return geometry.snapMinutes(rawMinutes);
  }
}
```

- [ ] **Step 4: Run drag tests**

Run:

```powershell
flutter test test/dial/dial_drag_session_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Run all dial logic tests**

Run:

```powershell
flutter test test/dial/dial_geometry_test.dart test/dial/dial_drag_session_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Commit drag session**

Run:

```powershell
git add lib/src/dial/dial_drag_session.dart test/dial/dial_drag_session_test.dart
git commit -m "test: add dial drag tracking"
```

Expected: one focused drag tracking commit.

## Task 5: Add Timer Controller

**Files:**
- Create: `test/dial/dial_timer_controller_test.dart`
- Create: `lib/src/dial/dial_timer_controller.dart`

- [ ] **Step 1: Write failing controller tests**

Create `test/dial/dial_timer_controller_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pomodoro/src/dial/dial_constants.dart';
import 'package:simple_pomodoro/src/dial/dial_timer_controller.dart';

void main() {
  test('starts at the default 5 minute idle state', () {
    final controller = DialTimerController();

    expect(controller.phase, DialTimerPhase.idle);
    expect(controller.selectedMinutes, 5);
    expect(controller.remaining, const Duration(minutes: 5));
    expect(controller.visualMinutes, 5);
  });

  test('setSelectedMinutes clamps and updates remaining while idle', () {
    final controller = DialTimerController();

    controller.setSelectedMinutes(0);
    expect(controller.selectedMinutes, 5);

    controller.setSelectedMinutes(65);
    expect(controller.selectedMinutes, 65);
    expect(controller.remaining, const Duration(minutes: 65));
  });

  test('start records running phase and end time', () {
    final controller = DialTimerController()..setSelectedMinutes(25);
    final now = DateTime(2026, 5, 31, 12);

    controller.start(now);

    expect(controller.phase, DialTimerPhase.running);
    expect(controller.remaining, const Duration(minutes: 25));
  });

  test('syncWithClock calculates remaining time from real time', () {
    final controller = DialTimerController()..setSelectedMinutes(25);
    final now = DateTime(2026, 5, 31, 12);

    controller.start(now);
    final completed = controller.syncWithClock(now.add(const Duration(minutes: 4, seconds: 30)));

    expect(completed, isFalse);
    expect(controller.remaining, const Duration(minutes: 20, seconds: 30));
    expect(controller.visualMinutes, closeTo(20.5, 0.001));
  });

  test('completion resets to default 5 minutes', () {
    final controller = DialTimerController()..setSelectedMinutes(6);
    final now = DateTime(2026, 5, 31, 12);

    controller.start(now);
    final completed = controller.syncWithClock(now.add(const Duration(minutes: 6, seconds: 1)));

    expect(completed, isTrue);
    expect(controller.phase, DialTimerPhase.idle);
    expect(controller.selectedMinutes, 5);
    expect(controller.remaining, const Duration(minutes: 5));
  });

  test('stopAndReset resets a running timer without completion', () {
    final controller = DialTimerController()..setSelectedMinutes(40);

    controller.start(DateTime(2026, 5, 31, 12));
    controller.stopAndReset();

    expect(controller.phase, DialTimerPhase.idle);
    expect(controller.selectedMinutes, 5);
    expect(controller.remaining, const Duration(minutes: 5));
  });
}
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```powershell
flutter test test/dial/dial_timer_controller_test.dart
```

Expected: fails because `DialTimerController` does not exist.

- [ ] **Step 3: Implement timer controller**

Create `lib/src/dial/dial_timer_controller.dart`:

```dart
import 'package:flutter/foundation.dart';

import 'dial_constants.dart';
import 'dial_geometry.dart';

class DialTimerController extends ChangeNotifier {
  DialTimerController({DialGeometry geometry = const DialGeometry()})
      : _geometry = geometry;

  final DialGeometry _geometry;

  DialTimerPhase _phase = DialTimerPhase.idle;
  int _selectedMinutes = DialConstants.defaultMinutes;
  Duration _remaining = const Duration(minutes: DialConstants.defaultMinutes);
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
    if (next == _selectedMinutes && _remaining == Duration(minutes: next)) {
      return;
    }

    _selectedMinutes = next;
    _remaining = Duration(minutes: next);
    notifyListeners();
  }

  void start(DateTime now) {
    if (_phase == DialTimerPhase.running) {
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
        _remaining == const Duration(minutes: DialConstants.defaultMinutes)) {
      return;
    }

    _resetToDefault();
    notifyListeners();
  }

  void _resetToDefault() {
    _phase = DialTimerPhase.idle;
    _selectedMinutes = DialConstants.defaultMinutes;
    _remaining = const Duration(minutes: DialConstants.defaultMinutes);
    _endsAt = null;
  }
}
```

- [ ] **Step 4: Run controller tests**

Run:

```powershell
flutter test test/dial/dial_timer_controller_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Run all logic tests**

Run:

```powershell
flutter test test/dial
```

Expected: all tests pass.

- [ ] **Step 6: Commit controller**

Run:

```powershell
git add lib/src/dial/dial_timer_controller.dart test/dial/dial_timer_controller_test.dart
git commit -m "test: add dial timer controller"
```

Expected: one focused timer controller commit.

## Task 6: Add App Shell and Feedback Service

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/src/app/pomodoro_app.dart`
- Create: `lib/src/feedback/feedback_service.dart`
- Modify: `android/app/src/main/kotlin/com/bollks/simple_pomodoro/MainActivity.kt`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Replace app entry point**

Replace `lib/main.dart`:

```dart
import 'package:flutter/material.dart';

import 'src/app/pomodoro_app.dart';

void main() {
  runApp(const PomodoroApp());
}
```

- [ ] **Step 2: Add app shell**

Create `lib/src/app/pomodoro_app.dart`:

```dart
import 'package:flutter/material.dart';

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simple Pomodoro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F8F72)),
        useMaterial3: true,
      ),
      home: const SizedBox.expand(),
    );
  }
}
```

- [ ] **Step 3: Add feedback service**

Create `lib/src/feedback/feedback_service.dart`:

```dart
import 'package:flutter/services.dart';

class FeedbackService {
  static const MethodChannel _channel = MethodChannel('simple_pomodoro/feedback');

  Future<void> selectionChanged() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      return;
    }
  }

  Future<void> completed() async {
    await Future.wait<void>([
      _vibrate(),
      _playCompletionSound(),
    ]);
  }

  Future<void> _vibrate() async {
    try {
      await HapticFeedback.vibrate();
    } catch (_) {
      return;
    }
  }

  Future<void> _playCompletionSound() async {
    try {
      await _channel.invokeMethod<void>('playCompletionSound');
    } catch (_) {
      return;
    }
  }
}
```

- [ ] **Step 4: Add Android sound bridge**

Replace `android/app/src/main/kotlin/com/bollks/simple_pomodoro/MainActivity.kt`:

```kotlin
package com.bollks.simple_pomodoro

import android.media.RingtoneManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "simple_pomodoro/feedback"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playCompletionSound" -> {
                        playCompletionSound()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun playCompletionSound() {
        val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val ringtone = RingtoneManager.getRingtone(applicationContext, uri)
        ringtone?.play()
    }
}
```

- [ ] **Step 5: Add vibration permission**

Ensure `android/app/src/main/AndroidManifest.xml` includes this permission directly under the `<manifest>` element and before `<application>`:

```xml
<uses-permission android:name="android.permission.VIBRATE" />
```

- [ ] **Step 6: Run analysis**

Run:

```powershell
flutter analyze
```

Expected: no analysis issues.

- [ ] **Step 7: Commit shell and feedback bridge**

Run:

```powershell
git add lib/main.dart lib/src/app/pomodoro_app.dart lib/src/feedback/feedback_service.dart android/app/src/main/kotlin/com/bollks/simple_pomodoro/MainActivity.kt android/app/src/main/AndroidManifest.xml
git commit -m "feat: add app shell and feedback bridge"
```

Expected: one commit. The app does not compile until Task 7 adds the page.

## Task 7: Add Dial Painter and Page

**Files:**
- Create: `lib/src/dial/dial_painter.dart`
- Create: `lib/src/dial/dial_timer_page.dart`
- Modify: `lib/src/app/pomodoro_app.dart`

- [ ] **Step 1: Add dial painter**

Create `lib/src/dial/dial_painter.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dial_geometry.dart';

class DialPainter extends CustomPainter {
  DialPainter({
    required this.visualMinutes,
    required this.isRunning,
    this.geometry = const DialGeometry(),
  });

  final double visualMinutes;
  final bool isRunning;
  final DialGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final center = geometry.centerOf(size);
    final radius = geometry.outerRadiusFor(size);
    final dialRect = Rect.fromCircle(center: center, radius: radius);

    _drawShell(canvas, center, radius);
    _drawSector(canvas, dialRect);
    _drawEdgeShadow(canvas, center, radius);
    _drawMarkers(canvas, center, radius);
    _drawCenterButton(canvas, center, radius);
  }

  void _drawShell(Canvas canvas, Offset center, double radius) {
    final shellPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFFF8F6EF),
          Color(0xFFD9DAD6),
          Color(0xFFB9BDB8),
        ],
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

  void _drawSector(Canvas canvas, Rect dialRect) {
    final sweep = geometry.displaySweepForMinutes(visualMinutes);
    if (sweep <= 0) {
      return;
    }

    final sectorPaint = Paint()
      ..color = const Color(0xFF2F8F72)
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      dialRect.deflate(dialRect.width * 0.045),
      -math.pi / 2,
      sweep,
      true,
      sectorPaint,
    );
  }

  void _drawEdgeShadow(Canvas canvas, Offset center, double radius) {
    final angle = geometry.angleForMinutes(visualMinutes);
    final shadowLength = radius * 0.88;
    final shadowWidth = radius * 0.055;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle - math.pi / 2);

    final rect = Rect.fromLTWH(0, -shadowWidth / 2, shadowLength, shadowWidth);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x5520332A),
          Color(0x1120332A),
          Color(0x0020332A),
        ],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawRect(rect, paint);
    canvas.restore();
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

  void _drawCenterButton(Canvas canvas, Offset center, double radius) {
    final buttonRadius = radius * 0.26;
    final buttonRect = Rect.fromCircle(center: center, radius: buttonRadius);
    final buttonPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFE0E2DD),
          Color(0xFFC3C8C1),
          Color(0xFF9BA39B),
        ],
      ).createShader(buttonRect);

    canvas.drawCircle(center, buttonRadius, buttonPaint);

    final outlinePaint = Paint()
      ..color = const Color(0xFF8E968E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.012;
    canvas.drawCircle(center, buttonRadius, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant DialPainter oldDelegate) {
    return oldDelegate.visualMinutes != visualMinutes ||
        oldDelegate.isRunning != isRunning;
  }
}
```

- [ ] **Step 2: Add timer page**

Create `lib/src/dial/dial_timer_page.dart`:

```dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../feedback/feedback_service.dart';
import 'dial_drag_session.dart';
import 'dial_geometry.dart';
import 'dial_painter.dart';
import 'dial_timer_controller.dart';

class DialTimerPage extends StatefulWidget {
  const DialTimerPage({
    required this.feedbackService,
    super.key,
  });

  final FeedbackService feedbackService;

  @override
  State<DialTimerPage> createState() => _DialTimerPageState();
}

class _DialTimerPageState extends State<DialTimerPage>
    with WidgetsBindingObserver {
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

  void _handleTapUp(TapUpDetails details) {
    final position = details.localPosition;
    if (!_geometry.isInsideCenterButton(size: _dialSize, position: position)) {
      return;
    }

    if (_controller.isRunning) {
      _controller.stopAndReset();
      _stopTicker();
      return;
    }

    _controller.start(DateTime.now());
    _startTicker();
  }

  void _handlePanStart(DragStartDetails details) {
    if (_controller.isRunning) {
      return;
    }

    final position = details.localPosition;
    if (!_geometry.isOnEdge(
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
    _dragSession = null;
  }

  void _handlePanCancel() {
    _dragSession = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shortest = math.min(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final dialSide = shortest.clamp(260.0, 460.0) * 0.9;
              _dialSize = Size.square(dialSide);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _handleTapUp,
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                onPanCancel: _handlePanCancel,
                child: SizedBox.square(
                  dimension: dialSide,
                  child: CustomPaint(
                    painter: DialPainter(
                      visualMinutes: _controller.visualMinutes,
                      isRunning: _controller.isRunning,
                      geometry: _geometry,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Wire the app shell to the timer page**

Replace `lib/src/app/pomodoro_app.dart`:

```dart
import 'package:flutter/material.dart';

import '../dial/dial_timer_page.dart';
import '../feedback/feedback_service.dart';

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simple Pomodoro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F8F72)),
        useMaterial3: true,
      ),
      home: DialTimerPage(
        feedbackService: FeedbackService(),
      ),
    );
  }
}
```

- [ ] **Step 4: Run analysis**

Run:

```powershell
flutter analyze
```

Expected: no analysis issues.

- [ ] **Step 5: Run all current tests**

Run:

```powershell
flutter test test/dial
```

Expected: all logic tests pass.

- [ ] **Step 6: Commit page and renderer**

Run:

```powershell
git add lib/src/app/pomodoro_app.dart lib/src/dial/dial_painter.dart lib/src/dial/dial_timer_page.dart
git commit -m "feat: add minimal dial timer page"
```

Expected: one focused UI commit.

## Task 8: Add Widget Tests

**Files:**
- Create: `test/dial/dial_timer_page_test.dart`
- Modify: `lib/src/feedback/feedback_service.dart`

- [ ] **Step 1: Make feedback service testable**

Update `lib/src/feedback/feedback_service.dart` so methods are overridable:

```dart
import 'package:flutter/services.dart';

class FeedbackService {
  static const MethodChannel _channel = MethodChannel('simple_pomodoro/feedback');

  Future<void> selectionChanged() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      return;
    }
  }

  Future<void> completed() async {
    await Future.wait<void>([
      vibrate(),
      playCompletionSound(),
    ]);
  }

  Future<void> vibrate() async {
    try {
      await HapticFeedback.vibrate();
    } catch (_) {
      return;
    }
  }

  Future<void> playCompletionSound() async {
    try {
      await _channel.invokeMethod<void>('playCompletionSound');
    } catch (_) {
      return;
    }
  }
}
```

- [ ] **Step 2: Write widget smoke tests**

Create `test/dial/dial_timer_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pomodoro/src/dial/dial_timer_page.dart';
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
  testWidgets('renders without visible text controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DialTimerPage(feedbackService: FakeFeedbackService()),
      ),
    );

    expect(find.byType(CustomPaint), findsOneWidget);
    expect(find.text('Start'), findsNothing);
    expect(find.text('End'), findsNothing);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('center tap starts and second center tap resets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DialTimerPage(feedbackService: FakeFeedbackService()),
      ),
    );

    final center = tester.getCenter(find.byType(CustomPaint));
    await tester.tapAt(center);
    await tester.pump();

    await tester.tapAt(center);
    await tester.pump();

    expect(find.byType(CustomPaint), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run widget tests**

Run:

```powershell
flutter test test/dial/dial_timer_page_test.dart
```

Expected: all widget tests pass.

- [ ] **Step 4: Run full test suite**

Run:

```powershell
flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Commit widget tests**

Run:

```powershell
git add lib/src/feedback/feedback_service.dart test/dial/dial_timer_page_test.dart
git commit -m "test: add dial timer widget coverage"
```

Expected: one focused testing commit.

## Task 9: Android Run and APK Build

**Files:**
- Modify only files required by `flutter build apk` if Flutter reports generated Android configuration drift.

- [ ] **Step 1: Run analyzer**

Run:

```powershell
flutter analyze
```

Expected: no analysis issues.

- [ ] **Step 2: Run full tests**

Run:

```powershell
flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Run on an Android device or emulator**

Run:

```powershell
flutter devices
flutter run
```

Expected: app opens to a single dial screen with no visible text, numbers, or pointer.

- [ ] **Step 4: Manual interaction check**

Verify on device or emulator:

- Dragging near the green edge changes the sector in 1 minute steps.
- Dragging away from the green edge does not change time.
- Dragging below 5 minutes clamps to 5.
- Dragging clockwise through the first full lap keeps the dial fully green and moves the edge shadow through the second lap.
- Center tap starts the timer.
- Dragging is disabled while running.
- Second center tap stops and resets to 5 minutes.
- Letting the timer finish triggers haptic feedback and Android default notification sound when device settings allow them.

- [ ] **Step 5: Build debug APK**

Run:

```powershell
flutter build apk --debug
```

Expected: debug APK is generated under `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 6: Commit build-readiness fixes**

If Step 1 through Step 5 required source changes, run:

```powershell
git add lib android pubspec.yaml test
git commit -m "chore: verify Android debug build"
```

Expected: commit only if source or config files changed. Do not commit `build/`.

## Task 10: Completion Review

**Files:**
- Modify: `开发路径.md` only if first-version status notes are useful after implementation.

- [ ] **Step 1: Review git diff**

Run:

```powershell
git status -sb
git diff --stat
```

Expected: either a clean working tree or only intentional documentation notes.

- [ ] **Step 2: Run final verification**

Run:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Expected: analyzer passes, tests pass, APK builds.

- [ ] **Step 3: Inspect generated APK path**

Run:

```powershell
Get-ChildItem "D:\Documents\Codex-Project\Pomodoro\build\app\outputs\flutter-apk"
```

Expected: `app-debug.apk` exists.

- [ ] **Step 4: Commit final documentation note if changed**

If `开发路径.md` was updated with implementation status, run:

```powershell
git add 开发路径.md
git commit -m "docs: update development path status"
```

Expected: documentation-only commit. Skip this step if no documentation changed.

## Self-Review

- Spec coverage: the plan covers Flutter setup, Android-first delivery, no background notifications, no text UI, no numbers, no pointer, 12 five-minute markers, green sector, edge shadow dragging, center button start/end, 5-120 minute range, 1-minute snapping, two-lap drag, running-state lockout, completion reset, sound and vibration, tests, Android run, and APK build.
- Placeholder scan: no placeholder sections are intentionally left open. The plan names concrete files, code, commands, and expected results.
- Type consistency: `DialGeometry`, `DialDragSession`, `DialTimerController`, `DialPainter`, `DialTimerPage`, and `FeedbackService` names are consistent across tasks.
