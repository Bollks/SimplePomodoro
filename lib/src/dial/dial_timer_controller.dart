import 'package:flutter/foundation.dart';

import 'dial_constants.dart';
import 'dial_geometry.dart';

class DialTimerController extends ChangeNotifier {
  DialTimerController({DialGeometry? geometry})
    : _geometry = geometry ?? const DialGeometry();

  final DialGeometry _geometry;

  DialTimerPhase _phase = DialTimerPhase.idle;
  int _selectedMinutes = DialConstants.defaultMinutes;
  Duration _remaining = Duration.zero;
  DateTime? _endsAt;

  DialTimerPhase get phase => _phase;
  int get selectedMinutes => _selectedMinutes;
  Duration get remaining => _remaining;
  bool get isRunning => _phase == DialTimerPhase.running;

  double get visualMinutes {
    if (_phase == DialTimerPhase.idle) {
      return _selectedMinutes.toDouble();
    }
    return _remaining.inMilliseconds / Duration.millisecondsPerMinute;
  }

  void setSelectedMinutes(int minutes) {
    if (_phase == DialTimerPhase.running) {
      return;
    }

    final next = _geometry.clampMinutes(minutes);
    final nextRemaining = Duration(minutes: next);
    if (next == _selectedMinutes && _remaining == nextRemaining) {
      return;
    }

    _selectedMinutes = next;
    _remaining = nextRemaining;
    notifyListeners();
  }

  void start(DateTime now) {
    if (_phase == DialTimerPhase.running || _selectedMinutes <= 0) {
      return;
    }

    _phase = DialTimerPhase.running;
    _remaining = Duration(minutes: _selectedMinutes);
    _endsAt = now.add(_remaining);
    notifyListeners();
  }

  bool syncWithClock(DateTime now) {
    if (_phase != DialTimerPhase.running || _endsAt == null) {
      return false;
    }

    final nextRemaining = _endsAt!.difference(now);
    if (!nextRemaining.isNegative && nextRemaining > Duration.zero) {
      _remaining = nextRemaining;
      notifyListeners();
      return false;
    }

    _resetToDefault();
    notifyListeners();
    return true;
  }

  void stopAndReset() {
    if (_phase == DialTimerPhase.idle &&
        _selectedMinutes == DialConstants.defaultMinutes &&
        _remaining == Duration.zero) {
      return;
    }

    _resetToDefault();
    notifyListeners();
  }

  void _resetToDefault() {
    _phase = DialTimerPhase.idle;
    _selectedMinutes = DialConstants.defaultMinutes;
    _remaining = Duration.zero;
    _endsAt = null;
  }
}
