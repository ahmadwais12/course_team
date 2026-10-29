import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;
import 'device.dart' as device;

extension ResponsiveContext on BuildContext {
  device.DeviceType get deviceType => device.getDeviceType(MediaQuery.of(this).size.width);

  bool get isMobile => deviceType == device.DeviceType.mobile;
  bool get isTablet => deviceType == device.DeviceType.tablet;
  bool get isDesktop => deviceType == device.DeviceType.desktop;
  bool get isUltraWide => deviceType == device.DeviceType.ultraWide;
  bool get isHandheld => isMobile || isTablet;

  double get responsiveWidth => MediaQuery.of(this).size.width;
  double get responsiveHeight => MediaQuery.of(this).size.height;

  int gridColumns() {
    final w = responsiveWidth;
    if (w < 600) return 2;
    if (w < 1024) return 3;
    if (w < 1440) return 4;
    return 6;
  }

  EdgeInsets responsivePadding() {
    final w = responsiveWidth;
    if (w < 600) return EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h);
    if (w < 1024) return EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h);
    return EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h);
  }

  double responsiveFontSize(double base) {
    if (isMobile) return base;
    if (isTablet) return base * 1.1;
    return base * 1.2;
  }
}
