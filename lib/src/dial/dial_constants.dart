enum DialTimerPhase {
  idle,
  running,
}

class DialConstants {
  const DialConstants._();

  static const int defaultMinutes = 5;
  static const int minMinutes = 5;
  static const int maxMinutes = 120;
  static const int minutesPerLap = 60;

  static const double dialOuterRadiusFactor = 0.48;
  static const double dialInnerRadiusFactor = 0.18;
  static const double edgeTouchAngularTolerance = 0.24;
}
