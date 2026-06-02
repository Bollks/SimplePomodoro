# Long Press Minute Hand Stop Design

Date: 2026-06-02

## Goal

Add a stop method for the running timer without adding visible controls. The selected interaction is: while the timer is running, long press the minute hand to stop the timer and reset the dial to `0min` at 12 o'clock.

## Scope

Included:

- Stop is available only while the timer is running.
- Stop is triggered by a long press on the visible minute hand shaft or tip area.
- Stop resets the timer to idle, `0min`, and `Duration.zero`.
- Stop moves the minute hand back to the 12 o'clock position.
- Stop uses the existing background transition from running black back to idle light.
- Stop cancels the ticker so the page no longer syncs a completed timer.
- Stop does not trigger completion sound or vibration.
- The long-press target uses the minute-hand shaft segment, excludes the center hub, and uses `1.4x` the normal minute-hand touch width for phone usability.

Excluded:

- Pause and resume.
- A visible stop button.
- Center-hub long press stop behavior.
- Dragging the running hand back to 12 o'clock.
- Confirmation dialogs.
- GitHub upload or release work.

## Interaction Rules

Idle state:

- Dragging the minute hand still selects `0-60min`.
- Releasing the hand with a value greater than `0min` still starts the timer.
- Long pressing the hand while idle does not start, stop, or reset anything.

Running state:

- Normal dragging remains disabled.
- Long pressing the current minute-hand shaft or tip stops the timer and resets to `0min`.
- Long pressing away from the minute hand does nothing.
- Long pressing the center hub alone does not stop the timer.
- The stop action does not call `FeedbackService.completed()`.

## Architecture

`DialTimerController` already exposes `stopAndReset()`. The implementation should reuse it instead of adding a new controller state.

`DialTimerPage` should add a running-only long-press handler. The handler should check whether the long-press position is on the minute-hand shaft or tip for the current visual remaining minutes. If the point is valid, it should:

1. Clear any active drag session.
2. Call `_stopTicker()`.
3. Call `_controller.stopAndReset()`.

`DialGeometry` should expose a focused running-stop hit test, named `isOnMinuteHandStopTarget()`. It should reuse the minute-hand segment math, exclude the center hub, and use `DialConstants.minuteHandTouchWidthFactor * 1.4` as the touch width.

## Testing

Tests should cover:

- `DialTimerController.stopAndReset()` already resets running timers to `0min`; keep that coverage.
- Running page long press on the minute hand resets the timer to idle.
- Running page long press on the minute hand transitions the background back to idle state.
- Running page long press on the minute hand does not call completion feedback.
- Running page long press away from the minute hand does not reset.
- Idle long press on the minute hand does nothing.

## Success Criteria

- A user can stop an active timer by long pressing the minute hand.
- The timer resets to `0min` and the hand returns to 12 o'clock.
- No visible stop control is added.
- Completion feedback is not played when manually stopping.
- `flutter analyze` passes.
- `flutter test` passes.
- Android debug APK builds.
