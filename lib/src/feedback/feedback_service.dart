import 'package:flutter/services.dart';

class FeedbackService {
  static const MethodChannel _channel =
      MethodChannel('simple_pomodoro/feedback');

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
