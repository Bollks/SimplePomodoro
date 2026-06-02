# Long Press Minute Hand Stop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users stop a running timer by long pressing the current minute-hand shaft or tip, resetting the dial to `0min` without adding visible controls.

**Architecture:** Reuse `DialTimerController.stopAndReset()` for state reset. Add a focused `DialGeometry.isOnMinuteHandStopTarget()` hit test that excludes the center hub and widens the hand shaft/tip target by `1.4x`. Wire `DialTimerPage` pointer-down events to a 700ms timer so the stop gesture does not compete with existing pan dragging.

**Tech Stack:** Flutter, Dart, `flutter_test`, existing dial widgets and feedback service.

---

## File Structure

- Modify `lib/src/dial/dial_geometry.dart`: add `isOnMinuteHandStopTarget()` and a reusable private segment hit-test helper.
- Modify `test/dial/dial_geometry_test.dart`: add stop-target coverage for shaft, hub exclusion, and away-from-hand rejection.
- Modify `lib/src/dial/dial_timer_page.dart`: add running-only pointer long-press timer that stops ticker and resets controller.
- Modify `test/dial/dial_timer_page_test.dart`: add widget coverage for stopping, no completion feedback, away long press no-op, and idle long press no-op.

## Task 1: Add Minute-Hand Stop Target Geometry

**Files:**
- Modify: `test/dial/dial_geometry_test.dart`
- Modify: `lib/src/dial/dial_geometry.dart`

- [x] **Step 1: Write failing geometry tests**

Add these tests to `test/dial/dial_geometry_test.dart`:

```dart
  test('isOnMinuteHandStopTarget accepts shaft and tip points only', () {
    const size = Size(300, 300);
    final shaft = geometry.pointForMinutes(size, 15, radiusFactor: 0.30);
    final tip = geometry.pointForMinutes(size, 15, radiusFactor: 0.38);
    final awayFromHand = geometry.pointForMinutes(
      size,
      45,
      radiusFactor: 0.30,
    );

    expect(
      geometry.isOnMinuteHandStopTarget(
        size: size,
        position: shaft,
        minutes: 15,
      ),
      isTrue,
    );
    expect(
      geometry.isOnMinuteHandStopTarget(
        size: size,
        position: tip,
        minutes: 15,
      ),
      isTrue,
    );
    expect(
      geometry.isOnMinuteHandStopTarget(
        size: size,
        position: awayFromHand,
        minutes: 15,
      ),
      isFalse,
    );
  });

  test('isOnMinuteHandStopTarget rejects the center hub', () {
    const size = Size(300, 300);

    expect(
      geometry.isOnMinuteHandStopTarget(
        size: size,
        position: geometry.centerOf(size),
        minutes: 15,
      ),
      isFalse,
    );
  });
```

- [x] **Step 2: Verify red**

Run:

```powershell
flutter test test/dial/dial_geometry_test.dart
```

Expected: tests fail because `isOnMinuteHandStopTarget()` does not exist.

- [x] **Step 3: Implement stop target hit testing**

In `lib/src/dial/dial_geometry.dart`, add:

```dart
  bool isOnMinuteHandStopTarget({
    required Size size,
    required Offset position,
    required num minutes,
  }) {
    if (isInsideMinuteHandHub(size: size, position: position)) {
      return false;
    }

    return _isNearMinuteHandSegment(
      size: size,
      position: position,
      minutes: minutes,
      touchWidthMultiplier: 1.4,
    );
  }
```

Refactor `isOnMinuteHand()` so it calls a private helper:

```dart
  bool isOnMinuteHand({
    required Size size,
    required Offset position,
    required num minutes,
  }) {
    if (isInsideMinuteHandHub(size: size, position: position)) {
      return true;
    }

    return _isNearMinuteHandSegment(
      size: size,
      position: position,
      minutes: minutes,
    );
  }

  bool _isNearMinuteHandSegment({
    required Size size,
    required Offset position,
    required num minutes,
    double touchWidthMultiplier = 1,
  }) {
    final shortestSide = math.min(size.width, size.height);
    final center = centerOf(size);
    final angle = angleForMinutes(minutes);
    final direction = Offset(math.sin(angle), -math.cos(angle));
    final start =
        center -
        direction * shortestSide * DialConstants.minuteHandTailRadiusFactor;
    final end =
        center +
        direction * shortestSide * DialConstants.minuteHandTipRadiusFactor;
    final touchWidth =
        shortestSide *
        DialConstants.minuteHandTouchWidthFactor *
        touchWidthMultiplier;

    return _distanceToSegment(position, start, end) <= touchWidth;
  }
```

- [x] **Step 4: Verify green**

Run:

```powershell
flutter test test/dial/dial_geometry_test.dart
```

Expected: geometry tests pass.

## Task 2: Add Running Long-Press Stop Page Behavior

**Files:**
- Modify: `test/dial/dial_timer_page_test.dart`
- Modify: `lib/src/dial/dial_timer_page.dart`

- [x] **Step 1: Write failing page tests**

Add this helper to `test/dial/dial_timer_page_test.dart`:

```dart
  Future<void> startTimerByDraggingHand(WidgetTester tester) async {
    const geometry = DialGeometry();
    final dialFinder = findDialPaint();
    final dialTopLeft = tester.getTopLeft(dialFinder);
    final dialSize = tester.getSize(dialFinder);
    final start =
        dialTopLeft + geometry.pointForMinutes(dialSize, 0, radiusFactor: 0.30);
    final end =
        dialTopLeft +
        geometry.pointForMinutes(dialSize, 15, radiusFactor: 0.30);

    await tester.dragFrom(start, end - start);
    await tester.pump();
  }
```

Add these tests:

```dart
  testWidgets('long pressing the running minute hand stops and resets', (
    tester,
  ) async {
    final feedbackService = FakeFeedbackService();
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: feedbackService)),
    );

    await startTimerByDraggingHand(tester);
    expect(pageBackground(tester).isRunning, isTrue);

    const geometry = DialGeometry();
    final dialFinder = findDialPaint();
    final dialTopLeft = tester.getTopLeft(dialFinder);
    final dialSize = tester.getSize(dialFinder);
    final handPoint =
        dialTopLeft +
        geometry.pointForMinutes(dialSize, 15, radiusFactor: 0.30);

    await tester.longPressAt(handPoint);
    await tester.pump();

    expect(pageBackground(tester).isRunning, isFalse);
    final hand = tester.widget<MinuteHand>(find.byType(MinuteHand));
    expect(hand.minutes, 0);
    expect(feedbackService.completions, 0);
  });

  testWidgets('long pressing away from the running minute hand does not stop', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: FakeFeedbackService())),
    );

    await startTimerByDraggingHand(tester);

    const geometry = DialGeometry();
    final dialFinder = findDialPaint();
    final dialTopLeft = tester.getTopLeft(dialFinder);
    final dialSize = tester.getSize(dialFinder);
    final awayPoint =
        dialTopLeft +
        geometry.pointForMinutes(dialSize, 45, radiusFactor: 0.30);

    await tester.longPressAt(awayPoint);
    await tester.pump();

    expect(pageBackground(tester).isRunning, isTrue);
  });

  testWidgets('long pressing the idle minute hand does not start or reset', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: FakeFeedbackService())),
    );

    const geometry = DialGeometry();
    final dialFinder = findDialPaint();
    final dialTopLeft = tester.getTopLeft(dialFinder);
    final dialSize = tester.getSize(dialFinder);
    final handPoint =
        dialTopLeft + geometry.pointForMinutes(dialSize, 0, radiusFactor: 0.30);

    await tester.longPressAt(handPoint);
    await tester.pump();

    expect(pageBackground(tester).isRunning, isFalse);
    final hand = tester.widget<MinuteHand>(find.byType(MinuteHand));
    expect(hand.minutes, 0);
  });
```

- [x] **Step 2: Verify red**

Run:

```powershell
flutter test test/dial/dial_timer_page_test.dart
```

Expected: the stop test fails because the page has no long-press handler.

- [x] **Step 3: Implement page long press**

In `lib/src/dial/dial_timer_page.dart`, add:

```dart
  void _handlePointerDown(PointerDownEvent event) {
    _stopLongPressTimer?.cancel();
    if (!_controller.isRunning) {
      return;
    }

    if (!_geometry.isOnMinuteHandStopTarget(
      size: _dialSize,
      position: event.localPosition,
      minutes: _controller.visualMinutes,
    )) {
      return;
    }

    _stopLongPressTimer = Timer(_stopLongPressDuration, _stopRunningTimer);
  }

  void _handlePointerUp(PointerUpEvent event) {
    _stopLongPressTimer?.cancel();
    _stopLongPressTimer = null;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _stopLongPressTimer?.cancel();
    _stopLongPressTimer = null;
  }

  void _stopRunningTimer() {
    if (!mounted || !_controller.isRunning) {
      return;
    }

    _stopLongPressTimer = null;
    _dragSession = null;
    _stopTicker();
    _controller.stopAndReset();
  }
```

Wrap the `GestureDetector` child with `Listener`:

```dart
                  child: Listener(
                    onPointerDown: _handlePointerDown,
                    onPointerUp: _handlePointerUp,
                    onPointerCancel: _handlePointerCancel,
                    child: SizedBox.square(
                      dimension: dialSide,
                      child: Stack(
                        fit: StackFit.expand,
```

Also add fields:

```dart
  static const Duration _stopLongPressDuration = Duration(milliseconds: 700);
  Timer? _stopLongPressTimer;
```

- [x] **Step 4: Verify green**

Run:

```powershell
flutter test test/dial/dial_timer_page_test.dart
```

Expected: page tests pass.

## Task 3: Full Verification and Commit

**Files:**
- Modify: `docs/superpowers/plans/2026-06-02-long-press-minute-hand-stop-implementation.md`
- Modify: `lib/src/dial/dial_geometry.dart`
- Modify: `lib/src/dial/dial_timer_page.dart`
- Modify: `test/dial/dial_geometry_test.dart`
- Modify: `test/dial/dial_timer_page_test.dart`

- [x] **Step 1: Run analyzer**

Run:

```powershell
flutter analyze
```

Expected: `No issues found!`

- [x] **Step 2: Run tests**

Run:

```powershell
flutter test
```

Expected: all tests pass.

- [x] **Step 3: Build Android debug APK**

Run:

```powershell
flutter build apk --debug
```

Expected: build completes and writes `build/app/outputs/flutter-apk/app-debug.apk`.

- [x] **Step 4: Inspect git status**

Run:

```powershell
git status -sb
git diff --stat
git diff --cached --stat
```

Expected: only the plan, dial geometry, dial page, and tests are modified.

- [ ] **Step 5: Commit implementation**

Run:

```powershell
git add docs/superpowers/plans/2026-06-02-long-press-minute-hand-stop-implementation.md lib/src/dial/dial_geometry.dart lib/src/dial/dial_timer_page.dart test/dial/dial_geometry_test.dart test/dial/dial_timer_page_test.dart
git commit -m "feat: stop timer from minute hand long press"
```

Expected: implementation commit succeeds.

## Self-Review

- Spec coverage: the plan covers running-only stop, shaft/tip hit testing, hub exclusion, no visible button, no pause/resume, no completion feedback, ticker cancellation, background return to idle, analyze, tests, and Android debug build.
- Placeholder scan: no open markers or postponed implementation steps remain.
- Type consistency: `isOnMinuteHandStopTarget()`, `_handlePointerDown`, `_stopRunningTimer`, `pageBackground`, `MinuteHand.minutes`, and `FakeFeedbackService.completions` are named consistently across tests and implementation.
