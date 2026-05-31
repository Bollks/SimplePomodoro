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
    _accumulatedRadians += geometry.shortestClockwiseDelta(
      _lastAngle,
      normalized,
    );
    _lastAngle = normalized;

    final rawMinutes =
        _baseMinutes + _accumulatedRadians / DialGeometry.twoPi * 60;
    return geometry.snapMinutes(rawMinutes);
  }
}
