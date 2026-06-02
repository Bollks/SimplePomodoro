import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'dial_geometry.dart';

class MinuteHand extends StatelessWidget {
  const MinuteHand({
    required this.assetName,
    required this.minutes,
    required this.geometry,
    super.key,
  });

  final String assetName;
  final double minutes;
  final DialGeometry geometry;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      key: const Key('minute-hand-rotation'),
      angle: geometry.angleForMinutes(minutes),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        assetName,
        key: const Key('minute-hand-artwork'),
        fit: BoxFit.contain,
      ),
    );
  }
}
