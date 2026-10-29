import 'package:flutter/material.dart';

class FadeSlide extends StatefulWidget {
  final Widget child;
  final double beginOffsetY;
  final double beginScale;
  final Duration duration;
  final Duration delay;

  const FadeSlide({
    super.key,
    required this.child,
    this.beginOffsetY = 12,
    this.beginScale = 0.98,
    this.duration = const Duration(milliseconds: 450),
    this.delay = Duration.zero,
  });

  @override
  State<FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<FadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        final dy = (1 - t) * widget.beginOffsetY;
        final scale = widget.beginScale + (1 - widget.beginScale) * t;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Duration duration;
  final double pressedScale;
  final EdgeInsetsGeometry? padding;
  final Color? splashColor;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 120),
    this.pressedScale = 0.98,
    this.padding,
    this.splashColor,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            splashColor: widget.splashColor,
            onTap: widget.onTap,
            child: Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.baseDelay = const Duration(milliseconds: 40),
  });

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: (index * baseDelay.inMilliseconds));
    return FadeSlide(
      delay: delay,
      child: child,
    );
  }
}
