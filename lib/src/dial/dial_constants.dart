enum DialTimerPhase {
  idle,
  running,
}

class DialConstants {
  const DialConstants._();

  static const int defaultMinutes = 0;
  static const int minMinutes = 0;
  static const int maxMinutes = 60;
  static const int minutesPerLap = 60;

  static const double dialOuterRadiusFactor = 0.48;
  static const double dialInnerRadiusFactor = 0.18;
  static const double minuteHandTipRadiusFactor = 0.38;
  static const double minuteHandTailRadiusFactor = 0.05;
  static const double minuteHandTouchWidthFactor = 0.055;
  static const double minuteHandHubRadiusFactor = 0.11;
  static const double edgeTouchAngularTolerance = 0.24;
}
