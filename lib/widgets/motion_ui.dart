import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 1. 3D Tilt Card (3D UI with tilt effect)
class TiltCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double maxTiltAngle;

  const TiltCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.maxTiltAngle = 0.05,
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  double _tiltX = 0;
  double _tiltY = 0;

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    setState(() {
      _tiltY = (details.localPosition.dx / constraints.maxWidth - 0.5) * widget.maxTiltAngle * 2;
      _tiltX = (details.localPosition.dy / constraints.maxHeight - 0.5) * -widget.maxTiltAngle * 2;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (details) => _onPanUpdate(details, constraints),
          onPanEnd: _onPanEnd,
          onPanCancel: () => _onPanEnd(DragEndDetails()),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(_tiltX)
              ..rotateY(_tiltY),
            transformAlignment: FractionalOffset.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: Offset(_tiltY * 50, _tiltX * -50),
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// 2. Glassmorphism Card (Enhanced)
class AdvancedGlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final List<Color>? gradientColors;

  const AdvancedGlassCard({
    super.key,
    required this.child,
    this.blur = 15,
    this.opacity = 0.1,
    this.borderRadius = 24,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            gradient: gradientColors != null 
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors!,
                )
              : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 3. Staggered List Animation
class StaggeredList extends StatelessWidget {
  final List<Widget> items;
  final Axis scrollDirection;
  final EdgeInsets padding;

  const StaggeredList({
    super.key,
    required this.items,
    this.scrollDirection = Axis.vertical,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      scrollDirection: scrollDirection,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return items[index]
            .animate()
            .fadeIn(duration: 500.ms, delay: (index * 100).ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
      },
    );
  }
}

/// 4. Micro-interactions: Animated Ripple Button
class RippleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? color;
  final double borderRadius;

  const RippleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        child: child,
      ),
    )
    .animate(onPlay: (controller) => controller.repeat(reverse: true))
    .shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.05));
  }
}
