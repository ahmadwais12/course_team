import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveSpacing extends StatelessWidget {
  final double mobileSize;
  final double? tabletSize;
  final double? desktopSize;
  final Axis axis;

  const ResponsiveSpacing({
    super.key,
    this.mobileSize = 16,
    this.tabletSize,
    this.desktopSize,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    double size;
    if (w >= 1024) {
      size = desktopSize ?? tabletSize ?? mobileSize;
    } else if (w >= 600) {
      size = tabletSize ?? mobileSize;
    } else {
      size = mobileSize;
    }
    if (axis == Axis.vertical) {
      return SizedBox(height: size.h);
    }
    return SizedBox(width: size.w);
  }
}
