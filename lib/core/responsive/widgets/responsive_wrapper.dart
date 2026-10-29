import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;
import '../device.dart' as device;

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class AdaptivePadding extends StatelessWidget {
  final Widget child;

  const AdaptivePadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final d = device.getDeviceType(MediaQuery.of(context).size.width);
    final pad = switch (d) {
      device.DeviceType.mobile => 16.0,
      device.DeviceType.tablet => 24.0,
      device.DeviceType.desktop => 32.0,
      device.DeviceType.ultraWide => 40.0,
    };
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad.w, vertical: 12.h),
      child: child,
    );
  }
}

class AdaptiveScrollPhysics extends StatelessWidget {
  final Widget child;

  const AdaptiveScrollPhysics({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isHandheld = device.getDeviceType(MediaQuery.of(context).size.width).isHandheld;
    return ScrollConfiguration(
      behavior: _AdaptiveScrollBehavior(isHandheld: isHandheld),
      child: child,
    );
  }
}

class _AdaptiveScrollBehavior extends ScrollBehavior {
  final bool isHandheld;
  const _AdaptiveScrollBehavior({required this.isHandheld});

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return isHandheld
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
  }
}
