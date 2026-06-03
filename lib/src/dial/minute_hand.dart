import 'package:flutter/material.dart';

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

  static const Size _assetSize = Size(1024, 1536);
  static const Offset _assetPivot = Offset(512, 1255);
  static const double _assetTipY = 117;
  static const double _tipRadiusFactor = 0.38;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final tipDistance = _assetPivot.dy - _assetTipY;
        final scale = side * _tipRadiusFactor / tipDistance;
        final imageSize = _assetSize * scale;
        final pivot = _assetPivot * scale;

        return Transform.rotate(
          key: const Key('minute-hand-rotation'),
          angle: geometry.angleForMinutes(minutes),
          alignment: Alignment.center,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: side / 2 - pivot.dx,
                top: side / 2 - pivot.dy,
                width: imageSize.width,
                height: imageSize.height,
                child: Image.asset(
                  assetName,
                  key: const Key('minute-hand-artwork'),
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
