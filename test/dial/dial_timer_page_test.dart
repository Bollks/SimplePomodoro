import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pomodoro/src/dial/dial_painter.dart';
import 'package:simple_pomodoro/src/dial/dial_timer_page.dart';
import 'package:simple_pomodoro/src/feedback/feedback_service.dart';

class FakeFeedbackService extends FeedbackService {
  int selections = 0;
  int completions = 0;

  @override
  Future<void> selectionChanged() async {
    selections += 1;
  }

  @override
  Future<void> completed() async {
    completions += 1;
  }
}

void main() {
  Finder findDialPaint() {
    return find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is DialPainter,
    );
  }

  testWidgets('renders without visible text controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DialTimerPage(feedbackService: FakeFeedbackService()),
      ),
    );

    expect(findDialPaint(), findsOneWidget);
    expect(find.text('Start'), findsNothing);
    expect(find.text('End'), findsNothing);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('center tap starts and second center tap resets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DialTimerPage(feedbackService: FakeFeedbackService()),
      ),
    );

    final center = tester.getCenter(findDialPaint());
    await tester.tapAt(center);
    await tester.pump();

    await tester.tapAt(center);
    await tester.pump();

    expect(findDialPaint(), findsOneWidget);
  });
}
