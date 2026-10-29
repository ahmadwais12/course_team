import 'package:flutter/material.dart';

class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile = const EdgeInsets.all(16),
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    EdgeInsets padding;
    if (w >= 1024) {
      padding = desktop ?? tablet ?? mobile;
    } else if (w >= 600) {
      padding = tablet ?? mobile;
    } else {
      padding = mobile;
    }
    return Padding(padding: padding, child: child);
  }
}

class ResponsiveHorizontalPadding extends StatelessWidget {
  final Widget child;

  const ResponsiveHorizontalPadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    double horizontal;
    if (w < 600) {
      horizontal = 16;
    } else if (w < 1024) {
      horizontal = 24;
    } else {
      horizontal = 32;
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      child: child,
    );
  }
}
