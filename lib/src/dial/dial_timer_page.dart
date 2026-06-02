import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../feedback/feedback_service.dart';
import 'dial_background.dart';
import 'dial_drag_session.dart';
import 'dial_geometry.dart';
import 'dial_painter.dart';
import 'dial_timer_controller.dart';
import 'minute_hand.dart';

class DialTimerPage extends StatefulWidget {
  const DialTimerPage({required this.feedbackService, super.key});

  final FeedbackService feedbackService;

  @override
  State<DialTimerPage> createState() => _DialTimerPageState();
}

class _DialTimerPageState extends State<DialTimerPage>
    with WidgetsBindingObserver {
  static const Color _idleBackgroundColor = Color(0xFFF5F1E8);
  static const Color _runningBackgroundColor = Colors.black;
  static const Duration _stopLongPressDuration = Duration(milliseconds: 700);
  static const String _dialFaceAsset = 'assets/dials/fritillaria.webp';
  static const String _dialCaseAsset = 'assets/cases/case_01.webp';
  static const String _minuteHandAsset =
      'assets/hands/minute_hand_placeholder.svg';

  final DialGeometry _geometry = const DialGeometry();
  late final DialTimerController _controller;

  Timer? _ticker;
  Timer? _stopLongPressTimer;
  DialDragSession? _dragSession;
  Size _dialSize = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = DialTimerController(geometry: _geometry);
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _stopLongPressTimer?.cancel();
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncTimer();
    }
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _syncTimer();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _syncTimer() async {
    final completed = _controller.syncWithClock(DateTime.now());
    if (completed) {
      _stopTicker();
      await widget.feedbackService.completed();
    }
  }

  void _handlePanStart(DragStartDetails details) {
    if (_controller.isRunning) {
      return;
    }

    final position = details.localPosition;
    if (!_geometry.isOnMinuteHand(
      size: _dialSize,
      position: position,
      minutes: _controller.selectedMinutes,
    )) {
      return;
    }

    _dragSession = DialDragSession(
      geometry: _geometry,
      initialMinutes: _controller.selectedMinutes,
      initialAngle: _initialDragAngleFor(position),
    );
  }

  double _initialDragAngleFor(Offset position) {
    if (_geometry.isInsideMinuteHandHub(size: _dialSize, position: position)) {
      return _geometry.angleForMinutes(_controller.selectedMinutes);
    }

    return _geometry.angleFromCenter(_dialSize, position);
  }

  Future<void> _handlePanUpdate(DragUpdateDetails details) async {
    final session = _dragSession;
    if (session == null || _controller.isRunning) {
      return;
    }

    final angle = _geometry.angleFromCenter(_dialSize, details.localPosition);
    final nextMinutes = session.update(angle);
    final previousMinutes = _controller.selectedMinutes;
    _controller.setSelectedMinutes(nextMinutes);

    if (nextMinutes != previousMinutes) {
      await widget.feedbackService.selectionChanged();
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    final shouldStart =
        _dragSession != null &&
        !_controller.isRunning &&
        _controller.selectedMinutes > 0;
    _dragSession = null;

    if (!shouldStart) {
      return;
    }

    _controller.start(DateTime.now());
    _startTicker();
  }

  void _handlePanCancel() {
    _dragSession = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    _stopLongPressTimer?.cancel();
    if (!_controller.isRunning) {
      return;
    }

    if (!_geometry.isOnMinuteHandStopTarget(
      size: _dialSize,
      position: event.localPosition,
      minutes: _controller.visualMinutes,
    )) {
      return;
    }

    _stopLongPressTimer = Timer(_stopLongPressDuration, _stopRunningTimer);
  }

  void _handlePointerUp(PointerUpEvent event) {
    _stopLongPressTimer?.cancel();
    _stopLongPressTimer = null;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _stopLongPressTimer?.cancel();
    _stopLongPressTimer = null;
  }

  void _stopRunningTimer() {
    if (!mounted || !_controller.isRunning) {
      return;
    }

    _stopLongPressTimer = null;
    _dragSession = null;
    _stopTicker();
    _controller.stopAndReset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _idleBackgroundColor,
      body: DialBackground(
        key: const Key('dial-timer-background'),
        isRunning: _controller.isRunning,
        idleColor: _idleBackgroundColor,
        runningColor: _runningBackgroundColor,
        child: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final shortest = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final dialSide = shortest.clamp(260.0, 460.0).toDouble() * 0.9;
                _dialSize = Size.square(dialSide);

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _handlePanStart,
                  onPanUpdate: _handlePanUpdate,
                  onPanEnd: _handlePanEnd,
                  onPanCancel: _handlePanCancel,
                  child: Listener(
                    onPointerDown: _handlePointerDown,
                    onPointerUp: _handlePointerUp,
                    onPointerCancel: _handlePointerCancel,
                    child: SizedBox.square(
                      dimension: dialSide,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            _dialFaceAsset,
                            key: const Key('dial-face-artwork'),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                          CustomPaint(
                            painter: DialPainter(
                              geometry: _geometry,
                              drawShell: false,
                            ),
                          ),
                          MinuteHand(
                            assetName: _minuteHandAsset,
                            minutes: _controller.visualMinutes,
                            geometry: _geometry,
                          ),
                          Image.asset(
                            _dialCaseAsset,
                            key: const Key('dial-case-artwork'),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
