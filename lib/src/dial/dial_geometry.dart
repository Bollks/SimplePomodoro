import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'dial_constants.dart';

class DialGeometry {
  const DialGeometry();

  static const double twoPi = math.pi * 2;

  int clampMinutes(num minutes) {
    return minutes
        .round()
        .clamp(DialConstants.minMinutes, DialConstants.maxMinutes)
        .toInt();
  }

  int snapMinutes(num minutes) {
    return clampMinutes(minutes.round());
  }

  double angleForMinutes(num minutes) {
    final clamped = _clampVisualMinutes(minutes);
    final minuteOnDial = clamped % DialConstants.minutesPerLap;
    return minuteOnDial == 0
        ? 0
        : minuteOnDial / DialConstants.minutesPerLap * twoPi;
  }

  int minutesForAngle(double angle) {
    final normalized = normalizeAngle(angle);
    final rawMinutes = normalized / twoPi * DialConstants.minutesPerLap;
    return clampMinutes(rawMinutes);
  }

  double displaySweepForMinutes(num minutes) {
    final clamped = _clampVisualMinutes(minutes);
    final visibleMinutes = math.min(clamped, DialConstants.minutesPerLap);
    return visibleMinutes / DialConstants.minutesPerLap * twoPi;
  }

  double _clampVisualMinutes(num minutes) {
    return minutes
        .toDouble()
        .clamp(
          DialConstants.minMinutes.toDouble(),
          DialConstants.maxMinutes.toDouble(),
        )
        .toDouble();
  }

  double angleFromCenter(Size size, Offset position) {
    final center = Offset(size.width / 2, size.height / 2);
    final vector = position - center;
    final raw = math.atan2(vector.dy, vector.dx) + math.pi / 2;
    return normalizeAngle(raw);
  }

  double normalizeAngle(double angle) {
    var normalized = angle % twoPi;
    if (normalized < 0) {
      normalized += twoPi;
    }
    return normalized;
  }

  double shortestClockwiseDelta(double previousAngle, double currentAngle) {
    var delta = currentAngle - previousAngle;
    if (delta > math.pi) {
      delta -= twoPi;
    }
    if (delta < -math.pi) {
      delta += twoPi;
    }
    return delta;
  }

  Offset centerOf(Size size) {
    return Offset(size.width / 2, size.height / 2);
  }

  double outerRadiusFor(Size size) {
    return math.min(size.width, size.height) *
        DialConstants.dialOuterRadiusFactor;
  }

  double innerRadiusFor(Size size) {
    return math.min(size.width, size.height) *
        DialConstants.dialInnerRadiusFactor;
  }

  Offset pointForMinutes(Size size, num minutes, {double radiusFactor = 0.42}) {
    final center = centerOf(size);
    final radius = math.min(size.width, size.height) * radiusFactor;
    final angle = angleForMinutes(minutes);
    return Offset(
      center.dx + math.sin(angle) * radius,
      center.dy - math.cos(angle) * radius,
    );
  }

  bool isInsideCenterButton({required Size size, required Offset position}) {
    final center = centerOf(size);
    final radius = math.min(size.width, size.height) * 0.15;
    return (position - center).distance <= radius;
  }

  bool isOnEdge({
    required Size size,
    required Offset position,
    required num minutes,
  }) {
    final center = centerOf(size);
    final distance = (position - center).distance;
    final outerRadius = outerRadiusFor(size);
    final innerRadius = innerRadiusFor(size);

    if (distance < innerRadius || distance > outerRadius) {
      return false;
    }

    final angle = angleFromCenter(size, position);
    final edgeAngle = angleForMinutes(minutes);
    final delta = shortestClockwiseDelta(edgeAngle, angle).abs();
    return delta <= DialConstants.edgeTouchAngularTolerance;
  }

  bool isOnMinuteHand({
    required Size size,
    required Offset position,
    required num minutes,
  }) {
    final shortestSide = math.min(size.width, size.height);
    final center = centerOf(size);
    final hubRadius = shortestSide * DialConstants.minuteHandHubRadiusFactor;
    if ((position - center).distance <= hubRadius) {
      return true;
    }

    final angle = angleForMinutes(minutes);
    final direction = Offset(math.sin(angle), -math.cos(angle));
    final start =
        center -
        direction * shortestSide * DialConstants.minuteHandTailRadiusFactor;
    final end =
        center +
        direction * shortestSide * DialConstants.minuteHandTipRadiusFactor;
    final touchWidth = shortestSide * DialConstants.minuteHandTouchWidthFactor;

    return _distanceToSegment(position, start, end) <= touchWidth;
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
    if (lengthSquared == 0) {
      return (point - start).distance;
    }

    final relative = point - start;
    final projection =
        (relative.dx * segment.dx + relative.dy * segment.dy) / lengthSquared;
    final clampedProjection = projection.clamp(0.0, 1.0).toDouble();
    final closest = start + segment * clampedProjection;
    return (point - closest).distance;
  }
}
