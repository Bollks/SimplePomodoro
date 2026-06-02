import 'package:flutter/material.dart';

class DialBackground extends StatefulWidget {
  const DialBackground({
    required this.isRunning,
    required this.idleColor,
    required this.runningColor,
    required this.child,
    this.startDuration = const Duration(milliseconds: 900),
    this.completionDuration = const Duration(milliseconds: 1100),
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
  late Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..value = widget.isRunning ? 1 : 0;
    _color = _buildColorAnimation();
  }

  @override
  void didUpdateWidget(covariant DialBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idleColor != widget.idleColor ||
        oldWidget.runningColor != widget.runningColor) {
      _color = _buildColorAnimation();
    }

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

  Animation<Color?> _buildColorAnimation() {
    return ColorTween(
      begin: widget.idleColor,
      end: widget.runningColor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _color,
      builder: (context, child) {
        return DecoratedBox(
          key: const Key('dial-background-color-layer'),
          decoration: BoxDecoration(color: _color.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
