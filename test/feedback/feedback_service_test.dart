import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pomodoro/src/feedback/feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const feedbackChannel = MethodChannel('simple_pomodoro/feedback');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(feedbackChannel, null);
  });

  test('completed triggers strong vibration and completion sound', () async {
    final methods = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(feedbackChannel, (call) async {
          methods.add(call.method);
          return null;
        });

    await FeedbackService().completed();

    expect(methods, containsAll(['vibrateCompletion', 'playCompletionSound']));
  });
}
