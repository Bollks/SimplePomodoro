import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../feedback/feedback_service.dart';
import 'dial_drag_session.dart';
import 'dial_geometry.dart';
import 'dial_painter.dart';
import 'dial_timer_controller.dart';

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
  static const Duration _backgroundTransitionDuration = Duration(
    milliseconds: 200,
  );
  static const String _dialFaceAsset = 'assets/dials/fritillaria.webp';
  static const String _dialCaseAsset = 'assets/cases/case_01.webp';

  final DialGeometry _geometry = const DialGeometry();
  late final DialTimerController _controller;

  Timer? _ticker;
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

  void _handleTapUp(TapUpDetails details) {
    final position = details.localPosition;
    if (!_geometry.isInsideCenterButton(size: _dialSize, position: position)) {
      return;
    }

    if (_controller.isRunning) {
      _controller.stopAndReset();
      _stopTicker();
      return;
    }

    _controller.start(DateTime.now());
    _startTicker();
  }

  void _handlePanStart(DragStartDetails details) {
    if (_controller.isRunning) {
      return;
    }

    final position = details.localPosition;
    if (!_geometry.isOnEdge(
      size: _dialSize,
      position: position,
      minutes: _controller.selectedMinutes,
    )) {
      return;
    }

    _dragSession = DialDragSession(
      geometry: _geometry,
      initialMinutes: _controller.selectedMinutes,
      initialAngle: _geometry.angleFromCenter(_dialSize, position),
    );
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
    _dragSession = null;
  }

  void _handlePanCancel() {
    _dragSession = null;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _controller.isRunning
        ? _runningBackgroundColor
        : _idleBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnimatedContainer(
        key: const Key('dial-timer-background'),
        duration: _backgroundTransitionDuration,
        decoration: BoxDecoration(color: backgroundColor),
        width: double.infinity,
        height: double.infinity,
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
                  onTapUp: _handleTapUp,
                  onPanStart: _handlePanStart,
                  onPanUpdate: _handlePanUpdate,
                  onPanEnd: _handlePanEnd,
                  onPanCancel: _handlePanCancel,
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
                            visualMinutes: _controller.visualMinutes,
                            isRunning: _controller.isRunning,
                            geometry: _geometry,
                            drawShell: false,
                          ),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
