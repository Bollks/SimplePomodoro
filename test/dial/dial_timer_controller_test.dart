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
    final completed = controller.syncWithClock(
      now.add(const Duration(minutes: 4, seconds: 30)),
    );

    expect(completed, isFalse);
    expect(controller.remaining, const Duration(minutes: 20, seconds: 30));
    expect(controller.visualMinutes, closeTo(20.5, 0.001));
  });

  test('running timer continues below 5 minutes and then completes', () {
    final controller = DialTimerController()..setSelectedMinutes(6);
    final now = DateTime(2026, 5, 31, 12);

    controller.start(now);
    final stillRunning = controller.syncWithClock(
      now.add(const Duration(minutes: 5, seconds: 30)),
    );

    expect(stillRunning, isFalse);
    expect(controller.phase, DialTimerPhase.running);
    expect(controller.remaining, const Duration(seconds: 30));
    expect(controller.visualMinutes, closeTo(0.5, 0.001));

    final completed = controller.syncWithClock(
      now.add(const Duration(minutes: 6)),
    );

    expect(completed, isTrue);
    expect(controller.phase, DialTimerPhase.idle);
    expect(controller.remaining, const Duration(minutes: 5));
  });

  test('completion resets to default 5 minutes', () {
    final controller = DialTimerController()..setSelectedMinutes(6);
    final now = DateTime(2026, 5, 31, 12);

    controller.start(now);
    final completed = controller.syncWithClock(
      now.add(const Duration(minutes: 6, seconds: 1)),
    );

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
