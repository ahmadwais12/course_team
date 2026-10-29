import 'package:flutter/material.dart';
import 'device.dart' as device;

class Adaptive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? ultraWide;

  const Adaptive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.ultraWide,
  });

  @override
  Widget build(BuildContext context) {
    final d = device.getDeviceType(MediaQuery.of(context).size.width);
    switch (d) {
      case device.DeviceType.mobile:
        return mobile;
      case device.DeviceType.tablet:
        return tablet ?? mobile;
      case device.DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case device.DeviceType.ultraWide:
        return ultraWide ?? desktop ?? tablet ?? mobile;
    }
  }
}

class AdaptiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;
  final T? ultraWide;

  const AdaptiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.ultraWide,
  });

  T resolve(BuildContext context) {
    final d = device.getDeviceType(MediaQuery.of(context).size.width);
    switch (d) {
      case device.DeviceType.mobile:
        return mobile;
      case device.DeviceType.tablet:
        return tablet ?? mobile;
      case device.DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case device.DeviceType.ultraWide:
        return ultraWide ?? desktop ?? tablet ?? mobile;
    }
  }
}
