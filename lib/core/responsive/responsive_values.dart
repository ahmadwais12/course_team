import 'package:flutter/material.dart';
import 'breakpoints.dart';

class ResponsiveValues {
  static double gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return 2;
    if (w < 1024) return 3;
    if (w < 1440) return 4;
    return 6;
  }

  static double padding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return 16;
    if (w < 1024) return 24;
    return 32;
  }

  static T value<T>(BuildContext context,
      {required T mobile, T? tablet, T? desktop, T? ultraWide}) {
    final w = MediaQuery.of(context).size.width;
    if (AppBreakpoints.isUltraWide(w)) return ultraWide ?? desktop ?? tablet ?? mobile;
    if (AppBreakpoints.isDesktop(w)) return desktop ?? tablet ?? mobile;
    if (AppBreakpoints.isTablet(w)) return tablet ?? mobile;
    return mobile;
  }
}
