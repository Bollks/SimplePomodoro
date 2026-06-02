# Background Transition Design

Date: 2026-06-02

## Goal

Make the timer background visibly animate when the timer starts and when it completes. The current implementation changes the target background color through an `AnimatedContainer`, but the page also applies the target color directly to `Scaffold.backgroundColor`, and the 200ms duration reads as an instant black/bright switch on a phone.

The fix should make the start transition feel like the watch face is entering focus mode, and the completion transition feel like it is returning to idle.

## Scope

Included:

- Keep the existing minute-hand timer interaction.
- Keep the existing idle color `#F5F1E8`.
- Keep the running background visually black at the end of the start transition.
- Animate start from idle to running over 900ms.
- Animate completion/reset from running to idle over 1100ms.
- Remove the immediate `Scaffold.backgroundColor` state jump that makes the transition appear instant.
- Add widget tests that verify an intermediate color exists during start and completion transitions.

Excluded:

- New timer controls.
- New watch assets.
- Gradient artwork changes inside the dial face asset.
- Completion feedback changes.
- GitHub upload or release work.

## Design

`DialTimerPage` will own an explicit background animation instead of relying on an implicit container color change. The animation layer will cover the whole page behind the safe area content.

The page will keep `Scaffold.backgroundColor` fixed to the idle background color so no parent layer jumps directly to black or back to idle. A full-screen animated background child will interpolate between the idle and running colors.

The start and completion directions will use different durations:

- Start: 900ms from idle to running.
- Completion/reset: 1100ms from running to idle.

The transition will be implemented with a focused `DialBackground` widget so the animation behavior can be tested without exposing private page state. The widget receives `isRunning`, the idle color, the running color, and durations.

## Data Flow

1. The page builds with `isRunning == false`; background animation value is idle.
2. User drags the minute hand and releases with a value greater than zero.
3. `DialTimerController.start()` switches to running and notifies the page.
4. The background widget receives `isRunning == true` and animates from idle to running.
5. When the timer completes, `syncWithClock()` resets the controller to idle and notifies the page.
6. The background widget receives `isRunning == false` and animates from running to idle.

## Testing

Widget tests should cover:

- The start transition has a non-final intermediate background color after a partial pump.
- The start transition reaches black after the full duration.
- The completion transition has a non-final intermediate background color after a partial pump.
- The completion transition reaches the idle background after the full duration.
- Existing minute-hand interaction tests continue to pass.

## Success Criteria

- On phone, starting a timer no longer appears as an instant black switch.
- On phone, completion no longer appears as an instant bright switch.
- `flutter analyze` passes.
- `flutter test` passes.
- Android debug APK still builds.
