import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:simple_pomodoro/src/dial/dial_geometry.dart';
import 'package:simple_pomodoro/src/dial/minute_hand.dart';

void main() {
  testWidgets('renders configured asset artwork inside a rotating transform', (
    tester,
  ) async {
    const geometry = DialGeometry();

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.square(
          dimension: 240,
          child: MinuteHand(
            assetName: 'assets/hands/minute_hand_placeholder.svg',
            minutes: 15,
            geometry: geometry,
          ),
        ),
      ),
    );

    expect(find.byType(MinuteHand), findsOneWidget);
    expect(find.byKey(const Key('minute-hand-rotation')), findsOneWidget);
    expect(find.byKey(const Key('minute-hand-artwork')), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);

    final hand = tester.widget<MinuteHand>(find.byType(MinuteHand));
    expect(hand.assetName, 'assets/hands/minute_hand_placeholder.svg');
    expect(hand.minutes, 15);
    expect(hand.geometry, geometry);

    final rotation = tester.widget<Transform>(
      find.byKey(const Key('minute-hand-rotation')),
    );
    expect(rotation.alignment, Alignment.center);
    expect(
      rotation.transform.storage[0],
      closeTo(math.cos(math.pi / 2), 0.001),
    );
    expect(
      rotation.transform.storage[1],
      closeTo(math.sin(math.pi / 2), 0.001),
    );
    expect(
      rotation.transform.storage[4],
      closeTo(-math.sin(math.pi / 2), 0.001),
    );
    expect(
      rotation.transform.storage[5],
      closeTo(math.cos(math.pi / 2), 0.001),
    );
  });
}
