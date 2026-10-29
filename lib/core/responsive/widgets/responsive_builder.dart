import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final data = ResponsiveBreakpoints.of(context);
    final isMobile = data.isMobile || data.isPhone;
    final isTablet = data.isTablet;
    final isDesktop = data.isDesktop;
    return builder(context, isMobile, isTablet, isDesktop);
  }
}

class LayoutSwitcher extends StatelessWidget {
  final Widget mobileLayout;
  final Widget? tabletLayout;
  final Widget? desktopLayout;

  const LayoutSwitcher({
    super.key,
    required this.mobileLayout,
    this.tabletLayout,
    this.desktopLayout,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        if (isDesktop) return desktopLayout ?? tabletLayout ?? mobileLayout;
        if (isTablet) return tabletLayout ?? mobileLayout;
        return mobileLayout;
      },
    );
  }
}
