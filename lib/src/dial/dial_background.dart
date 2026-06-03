import 'package:flutter/material.dart';

class DialBackground extends StatefulWidget {
  const DialBackground({
    required this.isRunning,
    required this.idleColor,
    required this.runningColor,
    required this.child,
    this.startDuration = const Duration(milliseconds: 1300),
    this.completionDuration = const Duration(milliseconds: 1500),
    super.key,
  });

  final bool isRunning;
  final Color idleColor;
  final Color runningColor;
  final Widget child;
  final Duration startDuration;
  final Duration completionDuration;

  @override
  State<DialBackground> createState() => _DialBackgroundState();
}

class _DialBackgroundState extends State<DialBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _runningOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      animationBehavior: AnimationBehavior.preserve,
    )
      ..value = widget.isRunning ? 1 : 0;
    _runningOpacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant DialBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRunning == widget.isRunning) {
      return;
    }

    if (widget.isRunning) {
      _controller.animateTo(1, duration: widget.startDuration);
    } else {
      _controller.animateTo(0, duration: widget.completionDuration);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          key: const Key('dial-background-idle-layer'),
          decoration: BoxDecoration(color: widget.idleColor),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              key: const Key('dial-background-running-layer'),
              opacity: _runningOpacity.value,
              child: child,
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(color: widget.runningColor),
          ),
        ),
        widget.child,
      ],
    );
  }
}
