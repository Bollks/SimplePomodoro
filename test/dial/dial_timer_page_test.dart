import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pomodoro/src/dial/dial_background.dart';
import 'package:simple_pomodoro/src/dial/dial_geometry.dart';
import 'package:simple_pomodoro/src/dial/dial_painter.dart';
import 'package:simple_pomodoro/src/dial/dial_timer_page.dart';
import 'package:simple_pomodoro/src/dial/minute_hand.dart';
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

  DialBackground pageBackground(WidgetTester tester) {
    return tester.widget<DialBackground>(find.byType(DialBackground));
  }

  Scaffold pageScaffold(WidgetTester tester) {
    return tester.widget<Scaffold>(find.byType(Scaffold));
  }

  testWidgets('uses dial face, minute hand, and case artwork', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: FakeFeedbackService())),
    );

    expect(find.byKey(const Key('dial-face-artwork')), findsOneWidget);
    expect(find.byType(MinuteHand), findsOneWidget);
    expect(find.byKey(const Key('dial-case-artwork')), findsOneWidget);

    final face = tester.widget<Image>(
      find.byKey(const Key('dial-face-artwork')),
    );
    final hand = tester.widget<MinuteHand>(find.byType(MinuteHand));
    final shell = tester.widget<Image>(
      find.byKey(const Key('dial-case-artwork')),
    );

    expect(
      (face.image as AssetImage).assetName,
      'assets/dials/fritillaria.webp',
    );
    expect(hand.assetName, 'assets/hands/minute_hand_placeholder.svg');
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

  testWidgets('center tap no longer starts the timer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: FakeFeedbackService())),
    );

    expect(pageBackground(tester).isRunning, isFalse);

    await tester.tapAt(tester.getCenter(findDialPaint()));
    await tester.pump();

    expect(pageBackground(tester).isRunning, isFalse);
  });

  testWidgets('dragging the minute hand starts on release', (tester) async {
    final feedbackService = FakeFeedbackService();
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: feedbackService)),
    );

    const geometry = DialGeometry();
    final dialFinder = findDialPaint();
    final dialTopLeft = tester.getTopLeft(dialFinder);
    final dialSize = tester.getSize(dialFinder);
    final start =
        dialTopLeft + geometry.pointForMinutes(dialSize, 0, radiusFactor: 0.30);
    final end =
        dialTopLeft +
        geometry.pointForMinutes(dialSize, 15, radiusFactor: 0.30);

    await tester.dragFrom(start, end - start);
    await tester.pump();

    expect(pageBackground(tester).isRunning, isTrue);
    expect(
      pageBackground(tester).startDuration,
      const Duration(milliseconds: 900),
    );
    expect(
      pageBackground(tester).completionDuration,
      const Duration(milliseconds: 1100),
    );
    expect(pageScaffold(tester).backgroundColor, const Color(0xFFF5F1E8));
    expect(feedbackService.selections, greaterThan(0));
  });

  testWidgets('dragging from the hub uses the current hand angle', (
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
    final start = dialTopLeft + geometry.centerOf(dialSize);
    final end =
        dialTopLeft +
        geometry.pointForMinutes(dialSize, 15, radiusFactor: 0.30);

    final gesture = await tester.startGesture(start);
    await gesture.moveTo(end);
    await tester.pump();

    expect(pageBackground(tester).isRunning, isFalse);
    expect(feedbackService.selections, greaterThan(0));

    await gesture.up();
    await tester.pump();

    expect(pageBackground(tester).isRunning, isTrue);
  });

  testWidgets('dragging away from the minute hand does not start', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: DialTimerPage(feedbackService: FakeFeedbackService())),
    );

    const geometry = DialGeometry();
    final dialFinder = findDialPaint();
    final dialTopLeft = tester.getTopLeft(dialFinder);
    final dialSize = tester.getSize(dialFinder);
    final start =
        dialTopLeft +
        geometry.pointForMinutes(dialSize, 30, radiusFactor: 0.30);
    final end =
        dialTopLeft +
        geometry.pointForMinutes(dialSize, 45, radiusFactor: 0.30);

    await tester.dragFrom(start, end - start);
    await tester.pump();

    expect(pageBackground(tester).isRunning, isFalse);
  });
}
