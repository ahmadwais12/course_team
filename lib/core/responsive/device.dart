enum DeviceType { mobile, tablet, desktop, ultraWide }

extension DeviceTypeX on DeviceType {
  bool get isMobile => this == DeviceType.mobile;
  bool get isTablet => this == DeviceType.tablet;
  bool get isDesktop => this == DeviceType.desktop;
  bool get isUltraWide => this == DeviceType.ultraWide;
  bool get isHandheld => isMobile || isTablet;
}

DeviceType getDeviceType(double width) {
  if (width < 600) return DeviceType.mobile;
  if (width < 1024) return DeviceType.tablet;
  if (width < 1440) return DeviceType.desktop;
  return DeviceType.ultraWide;
}
