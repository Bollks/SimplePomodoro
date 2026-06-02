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
