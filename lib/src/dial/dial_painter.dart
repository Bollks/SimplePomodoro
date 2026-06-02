import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dial_geometry.dart';

class DialPainter extends CustomPainter {
  DialPainter({this.geometry = const DialGeometry(), this.drawShell = true});

  final DialGeometry geometry;
  final bool drawShell;

  @override
  void paint(Canvas canvas, Size size) {
    final center = geometry.centerOf(size);
    final radius = geometry.outerRadiusFor(size);

    if (drawShell) {
      _drawShell(canvas, center, radius);
    }
    _drawMarkers(canvas, center, radius);
  }

  void _drawShell(Canvas canvas, Offset center, double radius) {
    final shellPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFF8F6EF), Color(0xFFD9DAD6), Color(0xFFB9BDB8)],
        stops: const [0.72, 0.88, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, shellPaint);

    final facePaint = Paint()..color = const Color(0xFFFBF8F0);
    canvas.drawCircle(center, radius * 0.91, facePaint);

    final rimPaint = Paint()
      ..color = const Color(0xFF9EA49D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.012;
    canvas.drawCircle(center, radius * 0.91, rimPaint);
  }

  void _drawMarkers(Canvas canvas, Offset center, double radius) {
    final markerPaint = Paint()
      ..color = const Color(0xFF485158)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.017;

    for (var index = 0; index < 12; index += 1) {
      final angle = index / 12 * math.pi * 2;
      final outer = Offset(
        center.dx + math.sin(angle) * radius * 0.78,
        center.dy - math.cos(angle) * radius * 0.78,
      );
      final inner = Offset(
        center.dx + math.sin(angle) * radius * 0.63,
        center.dy - math.cos(angle) * radius * 0.63,
      );
      canvas.drawLine(inner, outer, markerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant DialPainter oldDelegate) {
    return oldDelegate.drawShell != drawShell ||
        oldDelegate.geometry != geometry;
  }
}
