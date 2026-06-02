import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pomodoro/src/dial/dial_geometry.dart';
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

  AnimatedContainer backgroundContainer(WidgetTester tester) {
    return tester.widget<AnimatedContainer>(
      find.byKey(const Key('dial-timer-background')),
    );
  }

  Color? backgroundColorOf(AnimatedContainer container) {
    final decoration = container.decoration;
    return decoration is BoxDecoration ? decoration.color : null;
  }

  testWidgets('uses Calatrava dial face and case artwork', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: FakeFeedbackService())),
    );

    expect(find.byKey(const Key('dial-face-artwork')), findsOneWidget);
    expect(find.byKey(const Key('dial-case-artwork')), findsOneWidget);

    final face = tester.widget<Image>(
      find.byKey(const Key('dial-face-artwork')),
    );
    final shell = tester.widget<Image>(
      find.byKey(const Key('dial-case-artwork')),
    );

    expect(
      (face.image as AssetImage).assetName,
      'assets/dials/fritillaria.webp',
    );
    expect((shell.image as AssetImage).assetName, 'assets/cases/case_01.webp');
  });

  testWidgets('renders without visible text controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: FakeFeedbackService())),
    );

    expect(findDialPaint(), findsOneWidget);
    expect(find.text('Start'), findsNothing);
    expect(find.text('End'), findsNothing);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('center tap starts and second center tap resets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: FakeFeedbackService())),
    );

    final center = tester.getCenter(findDialPaint());
    await tester.tapAt(center);
    await tester.pump();

    await tester.tapAt(center);
    await tester.pump();

    expect(findDialPaint(), findsOneWidget);
  });

  testWidgets('background darkens while running and restores when reset', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: FakeFeedbackService())),
    );

    expect(
      backgroundColorOf(backgroundContainer(tester)),
      const Color(0xFFF5F1E8),
    );

    final center = tester.getCenter(findDialPaint());
    await tester.tapAt(center);
    await tester.pump();

    expect(
      backgroundContainer(tester).duration,
      const Duration(milliseconds: 200),
    );
    expect(backgroundColorOf(backgroundContainer(tester)), Colors.black);

    await tester.tapAt(center);
    await tester.pump();

    expect(
      backgroundColorOf(backgroundContainer(tester)),
      const Color(0xFFF5F1E8),
    );
  });

  testWidgets('dragging the active edge updates selected minutes', (
    tester,
  ) async {
    final feedbackService = FakeFeedbackService();
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: feedbackService)),
    );

    const geometry = DialGeometry();
    final dialFinder = findDialPaint();
    final dialTopLeft = tester.getTopLeft(dialFinder);
    final dialSize = tester.getSize(dialFinder);
    final start = dialTopLeft + geometry.pointForMinutes(dialSize, 5);
    final end = dialTopLeft + geometry.pointForMinutes(dialSize, 15);

    await tester.dragFrom(start, end - start);
    await tester.pump();

    final customPaint = tester.widget<CustomPaint>(dialFinder);
    final painter = customPaint.painter! as DialPainter;
    expect(painter.visualMinutes, greaterThan(5));
    expect(feedbackService.selections, greaterThan(0));
  });
}
