import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dial_geometry.dart';

class DialPainter extends CustomPainter {
  DialPainter({
    required this.visualMinutes,
    required this.isRunning,
    this.geometry = const DialGeometry(),
    this.drawShell = true,
  });

  final double visualMinutes;
  final bool isRunning;
  final DialGeometry geometry;
  final bool drawShell;

  @override
  void paint(Canvas canvas, Size size) {
    final center = geometry.centerOf(size);
    final radius = geometry.outerRadiusFor(size);
    final dialRect = Rect.fromCircle(center: center, radius: radius);

    if (drawShell) {
      _drawShell(canvas, center, radius);
    }
    _drawSector(canvas, dialRect);
    _drawEdgeShadow(canvas, center, radius);
    _drawMarkers(canvas, center, radius);
    _drawCenterButton(canvas, center, radius);
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

  void _drawSector(Canvas canvas, Rect dialRect) {
    final sweep = geometry.displaySweepForMinutes(visualMinutes);
    if (sweep <= 0) {
      return;
    }

    final sectorPaint = Paint()
      ..color = const Color(0xFF2F8F72)
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      dialRect.deflate(dialRect.width * 0.045),
      -math.pi / 2,
      sweep,
      true,
      sectorPaint,
    );
  }

  void _drawEdgeShadow(Canvas canvas, Offset center, double radius) {
    final angle = geometry.angleForMinutes(visualMinutes);
    final shadowLength = radius * 0.88;
    final shadowWidth = radius * 0.055;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle - math.pi / 2);

    final rect = Rect.fromLTWH(0, -shadowWidth / 2, shadowLength, shadowWidth);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x5520332A), Color(0x1120332A), Color(0x0020332A)],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawRect(rect, paint);
    canvas.restore();
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

  void _drawCenterButton(Canvas canvas, Offset center, double radius) {
    final buttonRadius = radius * 0.26;
    final buttonRect = Rect.fromCircle(center: center, radius: buttonRadius);
    final buttonPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFE0E2DD), Color(0xFFC3C8C1), Color(0xFF9BA39B)],
      ).createShader(buttonRect);

    canvas.drawCircle(center, buttonRadius, buttonPaint);

    final outlinePaint = Paint()
      ..color = const Color(0xFF8E968E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.012;
    canvas.drawCircle(center, buttonRadius, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant DialPainter oldDelegate) {
    return oldDelegate.visualMinutes != visualMinutes ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.drawShell != drawShell;
  }
}
