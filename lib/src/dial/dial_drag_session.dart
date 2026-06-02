import 'dial_constants.dart';
import 'dial_geometry.dart';

class DialDragSession {
  DialDragSession({
    required this.geometry,
    required int initialMinutes,
    required double initialAngle,
  }) : _baseMinutes = geometry.clampMinutes(initialMinutes),
       _lastAngle = geometry.normalizeAngle(initialAngle);

  final DialGeometry geometry;
  final int _baseMinutes;

  double _lastAngle;
  double _accumulatedRadians = 0;

  int update(double currentAngle) {
    final normalized = geometry.normalizeAngle(currentAngle);
    final delta = geometry.shortestClockwiseDelta(_lastAngle, normalized);
    _accumulatedRadians = (_accumulatedRadians + delta)
        .clamp(_minimumAccumulatedRadians, _maximumAccumulatedRadians)
        .toDouble();
    _lastAngle = normalized;

    final rawMinutes =
        _baseMinutes +
        _accumulatedRadians / DialGeometry.twoPi * DialConstants.minutesPerLap;
    return geometry.snapMinutes(rawMinutes);
  }

  double get _minimumAccumulatedRadians {
    return (DialConstants.minMinutes - _baseMinutes) /
        DialConstants.minutesPerLap *
        DialGeometry.twoPi;
  }

  double get _maximumAccumulatedRadians {
    return (DialConstants.maxMinutes - _baseMinutes) /
        DialConstants.minutesPerLap *
        DialGeometry.twoPi;
  }
}
