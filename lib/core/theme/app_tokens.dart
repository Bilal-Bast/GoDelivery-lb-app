import 'package:flutter/material.dart';

abstract final class AppColors {
  static const brand = Color(0xFFF5663A);
  static const brandStrong = Color(0xFFD94A22);
  static const brandSoft = Color(0xFFFFEAE2);

  static const ink = Color(0xFF172033);
  static const inkMuted = Color(0xFF667085);
  static const inkSubtle = Color(0xFF98A2B3);
  static const canvas = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF0F2F5);
  static const outline = Color(0xFFE4E7EC);
  static const outlineStrong = Color(0xFFD0D5DD);

  static const navy = Color(0xFF183153);
  static const navyLight = Color(0xFF24496F);
  static const teal = Color(0xFF168568);
  static const tealSoft = Color(0x14168568);
  static const amber = Color(0xFFE89A21);
  static const red = Color(0xFFD64550);
  static const blue = Color(0xFF3478C9);
  static const violet = Color(0xFF7357C7);
  static const violetSoft = Color(0x147357C7);
  static const cyan = Color(0xFF1687A7);
  static const onDarkMuted = Color(0xCCDDE7F2);
  static const onDark = Color(0xCCFFFFFF);
  static const darkShadow = Color(0x33000000);

  static const darkCanvas = Color(0xFF0E1624);
  static const darkSurface = Color(0xFF172235);
  static const darkOutline = Color(0xFF2B3A50);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const pill = 999.0;
}

abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const medium = 840.0;
  static const expanded = 1200.0;
  static const maxContent = 1440.0;
}

abstract final class AppShadows {
  static const subtle = [
    BoxShadow(
      color: Color(0x0A101828),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const raised = [
    BoxShadow(
      color: Color(0x10101828),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

extension GoDeliveryContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;

  double get pagePadding {
    final width = MediaQuery.sizeOf(this).width;
    if (width >= AppBreakpoints.expanded) return AppSpacing.xl;
    if (width >= AppBreakpoints.compact) return AppSpacing.lg;
    return AppSpacing.md;
  }
}
