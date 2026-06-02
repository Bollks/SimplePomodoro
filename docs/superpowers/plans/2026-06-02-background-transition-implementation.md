# Background Transition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current perceived instant background switch with a visible start and completion background transition.

**Architecture:** Add a focused `DialBackground` widget that owns background interpolation and exposes a stable key for widget tests. Keep `Scaffold.backgroundColor` fixed to the idle color so parent layers do not jump directly to black or back to idle. Update `DialTimerPage` to use `DialBackground` behind the existing safe area and dial content.

**Tech Stack:** Flutter, Dart, `flutter_test`, existing dial widgets.

---

## File Structure

- Create `lib/src/dial/dial_background.dart`: full-screen animated background widget with fixed start and completion durations.
- Create `test/dial/dial_background_test.dart`: focused widget tests for start and completion intermediate colors and final colors.
- Modify `lib/src/dial/dial_timer_page.dart`: replace `AnimatedContainer` with `DialBackground` and keep `Scaffold.backgroundColor` fixed.
- Modify `test/dial/dial_timer_page_test.dart`: update page tests to assert the new background widget and durations.

## Task 1: Add Focused Background Animation Tests

**Files:**
- Create: `test/dial/dial_background_test.dart`

- [x] **Step 1: Write failing tests**

Create `test/dial/dial_background_test.dart` with:

```dart
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
```

- [x] **Step 2: Verify red**

Run:

```powershell
flutter test test/dial/dial_background_test.dart
```

Expected: test fails because `dial_background.dart` does not exist yet.

## Task 2: Implement `DialBackground`

**Files:**
- Create: `lib/src/dial/dial_background.dart`
- Test: `test/dial/dial_background_test.dart`

- [x] **Step 1: Implement the widget**

Create `lib/src/dial/dial_background.dart` with:

```dart
import 'package:flutter/material.dart';

class DialBackground extends StatefulWidget {
  const DialBackground({
    required this.isRunning,
    required this.idleColor,
    required this.runningColor,
    required this.child,
    this.startDuration = const Duration(milliseconds: 900),
    this.completionDuration = const Duration(milliseconds: 1100),
    super.key,
  });

  final bool isRunning;
  final Color idleColor;
  final Color runningColor;
  final Widget child;
  final Duration startDuration;
  final Duration completionDuration;

  @override
  State<DialBackground> createState() => _DialBackgroundState();
}

class _DialBackgroundState extends State<DialBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..value = widget.isRunning ? 1 : 0;
    _color = _buildColorAnimation();
  }

  @override
  void didUpdateWidget(covariant DialBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idleColor != widget.idleColor ||
        oldWidget.runningColor != widget.runningColor) {
      _color = _buildColorAnimation();
    }

    if (oldWidget.isRunning == widget.isRunning) {
      return;
    }

    if (widget.isRunning) {
      _controller.animateTo(1, duration: widget.startDuration);
    } else {
      _controller.animateTo(0, duration: widget.completionDuration);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<Color?> _buildColorAnimation() {
    return ColorTween(
      begin: widget.idleColor,
      end: widget.runningColor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _color,
      builder: (context, child) {
        return DecoratedBox(
          key: const Key('dial-background-color-layer'),
          decoration: BoxDecoration(color: _color.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
```

- [x] **Step 2: Verify green**

Run:

```powershell
flutter test test/dial/dial_background_test.dart
```

Expected: all `DialBackground` tests pass.

## Task 3: Integrate Page Background

**Files:**
- Modify: `lib/src/dial/dial_timer_page.dart`
- Modify: `test/dial/dial_timer_page_test.dart`

- [x] **Step 1: Update page tests**

In `test/dial/dial_timer_page_test.dart`, replace the `AnimatedContainer` helper with a `DialBackground` helper:

```dart
DialBackground pageBackground(WidgetTester tester) {
  return tester.widget<DialBackground>(find.byType(DialBackground));
}
```

Import:

```dart
import 'package:simple_pomodoro/src/dial/dial_background.dart';
```

Update assertions that used `backgroundContainer(tester).duration` to:

```dart
expect(
  pageBackground(tester).startDuration,
  const Duration(milliseconds: 900),
);
expect(
  pageBackground(tester).completionDuration,
  const Duration(milliseconds: 1100),
);
expect(pageBackground(tester).isRunning, isTrue);
```

Update idle assertions to:

```dart
expect(pageBackground(tester).isRunning, isFalse);
```

- [x] **Step 2: Verify red**

Run:

```powershell
flutter test test/dial/dial_timer_page_test.dart
```

Expected: test fails because `DialTimerPage` still uses `AnimatedContainer`.

- [x] **Step 3: Integrate `DialBackground`**

In `lib/src/dial/dial_timer_page.dart`, import:

```dart
import 'dial_background.dart';
```

Replace:

```dart
final backgroundColor = _controller.isRunning
    ? _runningBackgroundColor
    : _idleBackgroundColor;

return Scaffold(
  backgroundColor: backgroundColor,
  body: AnimatedContainer(
    key: const Key('dial-timer-background'),
    duration: _backgroundTransitionDuration,
    decoration: BoxDecoration(color: backgroundColor),
```

with:

```dart
return Scaffold(
  backgroundColor: _idleBackgroundColor,
  body: DialBackground(
    isRunning: _controller.isRunning,
    idleColor: _idleBackgroundColor,
    runningColor: _runningBackgroundColor,
```

Remove `_backgroundTransitionDuration`.

- [x] **Step 4: Verify green**

Run:

```powershell
flutter test test/dial/dial_timer_page_test.dart test/dial/dial_background_test.dart
```

Expected: page and background tests pass.

## Task 4: Full Verification and Commit

**Files:**
- No planned source changes beyond fixes required by verification.

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

Expected: only background transition source, tests, docs, and existing untracked debug screenshots are present.

- [ ] **Step 5: Commit implementation**

Run:

```powershell
git add docs/superpowers/plans/2026-06-02-background-transition-implementation.md lib/src/dial/dial_background.dart lib/src/dial/dial_timer_page.dart test/dial/dial_background_test.dart test/dial/dial_timer_page_test.dart
git commit -m "feat: animate dial background transitions"
```

Expected: implementation commit succeeds. Do not add debug screenshots.

## Self-Review

- Spec coverage: the plan covers start animation, completion animation, fixed scaffold background, focused widget tests, page integration, analyze, tests, and Android debug build.
- Placeholder scan: no unresolved markers or deferred implementation steps remain.
- Type consistency: `DialBackground`, `isRunning`, `idleColor`, `runningColor`, `startDuration`, and `completionDuration` are named consistently across tests, implementation, and page integration.
