# Ceremonial Background Transition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make timer start and stop use a clearly perceptible full-screen background fade on real phones.

**Architecture:** Keep the public `DialBackground` API unchanged, but replace its single color tween with two stable background layers and an animated running overlay opacity. The timer page continues to pass `isRunning`; all ceremony stays inside the background component.

**Tech Stack:** Flutter, Dart, `AnimationController`, widget tests with `flutter_test`, Android device verification through Flutter/ADB.

---

### Task 1: Strengthen Background Animation Tests

**Files:**
- Modify: `test/dial/dial_background_test.dart`

- [ ] **Step 1: Add helpers that inspect the running overlay opacity**

Replace the existing `backgroundColor` helper with helpers that read the idle layer color and running overlay opacity:

```dart
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
```

- [ ] **Step 2: Rewrite the start transition test to require intermediate opacity**

Replace the existing start transition test with:

```dart
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
```

- [ ] **Step 3: Rewrite the stop transition test to require intermediate opacity**

Replace the existing completion transition test with:

```dart
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
```

- [ ] **Step 4: Add a mid-animation reversal test**

Add this test before the duration test:

```dart
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
```

- [ ] **Step 5: Add a reduced-animation regression test**

Add this test before the duration test:

```dart
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
```

- [ ] **Step 6: Update expected default durations**

In the duration test, update expected values:

```dart
expect(widget.startDuration, const Duration(milliseconds: 1300));
expect(widget.completionDuration, const Duration(milliseconds: 1500));
```

- [ ] **Step 7: Run the focused test and verify it fails**

Run:

```powershell
flutter test test/dial/dial_background_test.dart
```

Expected: FAIL because the production widget does not expose `dial-background-idle-layer` or `dial-background-running-layer`, and default durations still use the old values.

### Task 2: Implement Layered Background Fade

**Files:**
- Modify: `lib/src/dial/dial_background.dart`

- [ ] **Step 1: Change default durations**

Update constructor defaults:

```dart
this.startDuration = const Duration(milliseconds: 1300),
this.completionDuration = const Duration(milliseconds: 1500),
```

- [ ] **Step 2: Replace color animation with one curved opacity animation**

Replace the `_color` field with:

```dart
late Animation<double> _runningOpacity;
```

Initialize the animation in `initState`:

```dart
_controller = AnimationController(
  vsync: this,
  animationBehavior: AnimationBehavior.preserve,
)
  ..value = widget.isRunning ? 1 : 0;

_runningOpacity = CurvedAnimation(
  parent: _controller,
  curve: Curves.easeInOutCubic,
);
```

`AnimationBehavior.preserve` keeps this timer-mode transition visible on devices that request disabled or reduced system animations.

- [ ] **Step 3: Remove color tween rebuild logic**

Delete `_buildColorAnimation()` and the `oldWidget.idleColor` / `oldWidget.runningColor` branch in `didUpdateWidget`. Color changes should be picked up naturally by the rebuilt layer widgets.

- [ ] **Step 4: Keep animation reversal smooth**

In `didUpdateWidget`, keep the existing endpoint-based `animateTo` calls:

```dart
if (widget.isRunning) {
  _controller.animateTo(1, duration: widget.startDuration);
} else {
  _controller.animateTo(0, duration: widget.completionDuration);
}
```

This continues from the current controller value when state reverses mid-animation.

- [ ] **Step 5: Render the layered stack**

Replace `build` with:

```dart
@override
Widget build(BuildContext context) {
  return Stack(
    fit: StackFit.expand,
    children: [
      DecoratedBox(
        key: const Key('dial-background-idle-layer'),
        decoration: BoxDecoration(color: widget.idleColor),
      ),
      AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            key: const Key('dial-background-running-layer'),
            opacity: _runningOpacity.value,
            child: child,
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(color: widget.runningColor),
        ),
      ),
      widget.child,
    ],
  );
}
```

- [ ] **Step 6: Run the focused background test**

Run:

```powershell
flutter test test/dial/dial_background_test.dart
```

Expected: PASS.

### Task 3: Verify Page Integration And Existing Timer Behavior

**Files:**
- Modify only if tests expose a real integration issue: `test/dial/dial_timer_page_test.dart`
- Modify only if tests expose a real integration issue: `lib/src/dial/dial_timer_page.dart`

- [ ] **Step 1: Run dial page tests**

Run:

```powershell
flutter test test/dial/dial_timer_page_test.dart
```

Expected: PASS. Existing tests should continue to verify drag-to-start and long-press stop/reset behavior.

- [ ] **Step 2: Run all dial tests**

Run:

```powershell
flutter test test/dial
```

Expected: PASS.

- [ ] **Step 3: Run static analysis**

Run:

```powershell
flutter analyze
```

Expected: PASS with no issues.

### Task 4: Phone Verification

**Files:**
- No source file changes expected.

- [ ] **Step 1: Install the latest debug build on the connected Android phone**

Run:

```powershell
flutter run -d HQFE5TTSGUMBFIJ7 --debug --no-resident
```

Expected: build, install, and launch succeed.

- [ ] **Step 2: Wake and foreground the app**

Run:

```powershell
adb shell svc power stayon true
adb shell input keyevent KEYCODE_WAKEUP
adb shell wm dismiss-keyguard
adb shell cmd statusbar collapse
adb shell monkey -p com.bollks.simple_pomodoro -c android.intent.category.LAUNCHER 1
```

Expected: `MainActivity` is visible.

- [ ] **Step 3: Capture start transition evidence**

Run a drag to start the timer and capture screenshots around the transition:

```powershell
adb shell input swipe 610 1250 1030 1750 900
Start-Sleep -Milliseconds 250
adb shell screencap -p /sdcard/pomodoro_bg_start_250.png
Start-Sleep -Milliseconds 500
adb shell screencap -p /sdcard/pomodoro_bg_start_750.png
Start-Sleep -Milliseconds 900
adb shell screencap -p /sdcard/pomodoro_bg_start_done.png
adb pull /sdcard/pomodoro_bg_start_250.png "D:\Codex\tmp\pomodoro_background_transition\start_250.png"
adb pull /sdcard/pomodoro_bg_start_750.png "D:\Codex\tmp\pomodoro_background_transition\start_750.png"
adb pull /sdcard/pomodoro_bg_start_done.png "D:\Codex\tmp\pomodoro_background_transition\start_done.png"
```

Expected: screenshots show background progressing from warm to black.

- [ ] **Step 4: Capture stop transition evidence**

Run a long press on the minute hand and capture screenshots around the transition:

```powershell
adb shell input motionevent DOWN 850 1675
Start-Sleep -Milliseconds 1100
adb shell input motionevent UP 850 1675
Start-Sleep -Milliseconds 250
adb shell screencap -p /sdcard/pomodoro_bg_stop_250.png
Start-Sleep -Milliseconds 500
adb shell screencap -p /sdcard/pomodoro_bg_stop_750.png
Start-Sleep -Milliseconds 900
adb shell screencap -p /sdcard/pomodoro_bg_stop_done.png
adb pull /sdcard/pomodoro_bg_stop_250.png "D:\Codex\tmp\pomodoro_background_transition\stop_250.png"
adb pull /sdcard/pomodoro_bg_stop_750.png "D:\Codex\tmp\pomodoro_background_transition\stop_750.png"
adb pull /sdcard/pomodoro_bg_stop_done.png "D:\Codex\tmp\pomodoro_background_transition\stop_done.png"
```

Expected: screenshots show background progressing from black to warm.

### Task 5: Final Verification And Commit

**Files:**
- Commit all intended changes only.

- [ ] **Step 1: Run full tests**

Run:

```powershell
flutter test
```

Expected: PASS.

- [ ] **Step 2: Build debug APK**

Run:

```powershell
flutter build apk --debug
```

Expected: PASS.

- [ ] **Step 3: Review git diff**

Run:

```powershell
git diff --stat
git diff -- lib/src/dial/dial_background.dart test/dial/dial_background_test.dart
```

Expected: diff is limited to the layered background implementation, updated tests, and this implementation plan.

- [ ] **Step 4: Commit**

Run:

```powershell
git add docs/superpowers/plans/2026-06-03-ceremonial-background-transition-implementation.md lib/src/dial/dial_background.dart test/dial/dial_background_test.dart
git commit -m "feat: make background transitions perceptible"
```

Expected: one commit with the implementation and plan.
