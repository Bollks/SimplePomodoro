# Ceremonial Background Transition Design

## Context

The app already has a `DialBackground` animation that changes the page background between the idle warm color and the running black color. Widget tests confirm intermediate color values, but phone testing still feels like an instant switch. The next change should make the start and stop transitions visually obvious on device without adding visible controls or changing the minute-hand interaction model.

## Goal

Make timer start and timer stop feel like a short, deliberate watch-mode transition:

- Starting a timer fades the page into a black running background.
- Stopping or completing a timer fades the page back to the warm idle background.
- The transition is perceptible on a real phone, not only detectable by widget tests.
- The dial remains centered and interactive; no new buttons, labels, or controls are added.

## Recommended Approach

Use a full-screen layered background rather than a single color tween.

`DialBackground` should render a `Stack` with:

1. A base idle-color layer that is always present.
2. A full-screen running-color overlay whose opacity is driven by an animation controller.
3. The existing child content above both background layers.

When `isRunning` changes to `true`, animate overlay opacity from its current value to `1`. When `isRunning` changes to `false`, animate it back to `0`.

This makes the transition easier to perceive than directly tweening one solid color. It also keeps the implementation local to `DialBackground`, so timer and dial logic do not need to change.

## Visual Behavior

Start transition:

- Duration: around `1300ms`.
- Curve: deliberate but not sluggish, such as `easeInOutCubic`.
- Visual result: the warm idle background fades into black while the dial remains stable.

Stop transition:

- Duration: around `1500ms`.
- Curve: slightly softer than start, such as `easeOutCubic` or `easeInOutCubic`.
- Visual result: black fades back to the warm idle background after long-press stop or natural completion.

The transition must not flash, scale, blur, or move the dial. It should feel like the environment lighting changes around the watch face.

## Interaction Rules

- Dragging the minute hand to start the timer keeps the existing behavior.
- Long-pressing the running minute hand keeps the existing stop-and-reset behavior.
- Starting and stopping during an active transition should continue smoothly from the current opacity, not jump to either endpoint first.
- The animation should not block gesture handling.

## Implementation Boundaries

Primary implementation file:

- `lib/src/dial/dial_background.dart`

Likely test files:

- `test/dial/dial_background_test.dart`
- `test/dial/dial_timer_page_test.dart`

The page-level API should remain:

- `isRunning`
- `idleColor`
- `runningColor`
- `startDuration`
- `completionDuration`
- `child`

No new app-level state should be introduced for this change.

## Testing

Automated tests should verify:

- The background starts at idle with running overlay opacity `0`.
- The background reaches running with overlay opacity `1`.
- At 25%, 50%, and 75% of the start transition, opacity is between `0` and `1`.
- At 25%, 50%, and 75% of the stop transition, opacity is between `0` and `1`.
- Reversing state mid-animation continues from the current visual value.
- `DialTimerPage` still passes its existing drag-to-start and long-press-stop tests.

Manual phone verification should include:

- Install the latest debug build on the Android device.
- Start from the idle 12 o'clock state.
- Drag the minute hand to start and visually confirm a gradual fade to black.
- Long-press the running minute hand and visually confirm a gradual fade back to idle.
- Capture screenshots or a short recording if needed to confirm intermediate frames.

## Out Of Scope

- New timer controls.
- Text labels or tutorial copy.
- Dial movement, zoom, blur, or glow effects.
- Replacing the dial artwork or minute hand asset.
- Changing timer duration rules.

## Success Criteria

The feature is complete when:

- The start and stop transitions are visibly gradual on the connected phone.
- Existing timer interactions still work.
- Automated tests cover intermediate animation states.
- `flutter analyze` and the relevant Flutter tests pass.
