enum BreakpointType { sm, md, lg, xl, xxl, xxxl }

enum DeviceType { desktop, tablet, largePhone, smallPhone }

class Breakpoints {
  // static double sm = 640;
  // static double md = 768;
  // static double lg = 1024;
  // static double xl = 1280;
  // static double xxl = 1536;

  static Map<BreakpointType, int> BREAKPOINTS_VALUES = {
    BreakpointType.sm: 640,
    BreakpointType.md: 768,
    BreakpointType.lg: 1024,
    BreakpointType.xl: 1280,
    BreakpointType.xxl: 1536,
    BreakpointType.xxxl: 5536,
  };

  static Map<DeviceType, int> DEVICE_VALUES = {
    DeviceType.tablet: 900,
    DeviceType.largePhone: 600,
    DeviceType.smallPhone: 300
  };

  static get(double width) {
    for (var breakpointType in BREAKPOINTS_VALUES.keys) {
      if ((BREAKPOINTS_VALUES[breakpointType] ?? double.maxFinite) > width) {
        return breakpointType;
      }
    }

    return BreakpointType.xxxl;
  }
}
