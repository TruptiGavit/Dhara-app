// import 'package:agribot_flutter/res/theme/app_theme.dart';
import 'package:dharak_flutter/res/values/colors.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  //

  final Color surface; // = Colors.white;

  final Color back; // = Colors.white;
  final Color onSurface; // = Colors.black;
  final Color onSurfaceHigh;
  final Color onSurfaceMedium; // = Colors.black54;
  final Color onSurfaceDisable; // = Colors.black38;

  final Color onSurfaceLowest;

  final Color primaryHigh; // = Colors.greenAccent;
  final Color primary;
  final Color primaryLight;

  final Color secondaryLight;
  final Color secondaryColor;
  final Color seedColor;
  final Color errorColor;

  final bool isDark;

  AppThemeColors(
      {required this.surface,
      required this.back,
      required this.onSurface,
      required this.onSurfaceHigh,
      required this.onSurfaceMedium,
      required this.onSurfaceDisable,
      required this.onSurfaceLowest,
      required this.primaryHigh,
      required this.primary,
      required this.primaryLight,
      required this.secondaryLight,
      required this.seedColor,
      required this.secondaryColor,
      required this.errorColor,
      required this.isDark
      // required this.failure,
      }) {
    // onSurfaceHigh = AppTheme.colorSurface();
  }

  @override
  ThemeExtension<AppThemeColors> copyWith({
    Color? back,
    Color? surface,
    Color? onSurface,
    Color? onSurfaceHigh,
    Color? onSurfaceMedium,
    Color? onSurfaceDisable,
    Color? onSurfaceLowest,
    Color? primaryHigh,
    Color? primary,
    Color? primaryLight,
    Color? secondaryLight,
    Color? seedColor,
    Color? secondaryColor,
    Color? errorColor,
    bool? isDark
  }) {
    return AppThemeColors(
        surface: surface ?? this.surface, // = Colors.white;

        back: back ?? this.back,
        onSurface: onSurface ?? this.onSurface, // = Colors.black;
        onSurfaceHigh: onSurfaceHigh ?? this.onSurfaceHigh,
        onSurfaceMedium:
            onSurfaceMedium ?? this.onSurfaceMedium, // = Colors.black54;
        onSurfaceDisable:
            onSurfaceDisable ?? this.onSurfaceDisable, // = Colors.black38;

        onSurfaceLowest: onSurfaceLowest ?? this.onSurfaceLowest,
        primaryHigh: primaryHigh ?? this.primaryHigh, // = Colors.greenAccent;
        primary: primary ?? this.primary,
        primaryLight: primaryLight ?? this.primaryLight,
        seedColor: seedColor ?? this.seedColor,
        secondaryLight: secondaryLight ?? this.secondaryLight,
        secondaryColor: secondaryColor ?? this.secondaryColor,
        errorColor: errorColor ?? this.errorColor,
        isDark: isDark ?? this.isDark);
  }

  @override
  ThemeExtension<AppThemeColors> lerp(
      ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }
    return AppThemeColors(
      back: Color.lerp(back, other.back, t) ?? other.back,
      surface: Color.lerp(surface, other.surface, t) ?? other.surface,
      onSurface: Color.lerp(onSurface, other.onSurface, t) ?? other.onSurface,
      onSurfaceHigh: Color.lerp(onSurfaceHigh, other.onSurfaceHigh, t) ??
          other.onSurfaceHigh,
      onSurfaceMedium: Color.lerp(onSurfaceMedium, other.onSurfaceMedium, t) ??
          other.onSurfaceMedium,
      onSurfaceDisable:
          Color.lerp(onSurfaceDisable, other.onSurfaceDisable, t) ??
              other.onSurfaceDisable,
      onSurfaceLowest: Color.lerp(onSurfaceLowest, other.onSurfaceLowest, t) ??
          other.onSurfaceLowest,
      primaryHigh:
          Color.lerp(primaryHigh, other.primaryHigh, t) ?? other.primaryHigh,
      primary: Color.lerp(primary, other.primary, t) ?? other.primary,
      primaryLight:
          Color.lerp(primaryLight, other.primary, t) ?? other.primaryLight,
      secondaryLight: Color.lerp(secondaryLight, other.secondaryLight, t) ?? other.secondaryLight,

      seedColor: Color.lerp(seedColor, other.seedColor, t) ?? other.seedColor,
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t) ?? other.secondaryColor,
      errorColor:
          Color.lerp(errorColor, other.errorColor, t) ?? other.errorColor,
          isDark: other.isDark
      // isDark: true,
    );
  }

  @override
  String toString() {
    return 'AppThemeColors(seed: $seedColor)';
  }

  factory AppThemeColors.seedColor({
    Color seedColor = Colors.red,
    Color secondaryColor = TdResColors.colorSecondary50,
    Color? secondaryLight,
    
    bool isDark = false,
  }) {
    print("isDark: $isDark $seedColor");
    var back = TdThemeHelper.colorBack(isDark: isDark);
    var surface = TdThemeHelper.colorSurface(isDark: isDark);
    var onSurface = TdThemeHelper.colorOnSurface(isDark: isDark);

    var onSurfaceHigh =
        TdThemeHelper.colorBlend(surface, onSurface, TdResColorEmphasize.high);
    var onSurfaceMedium = TdThemeHelper.colorBlend(
        surface, onSurface, TdResColorEmphasize.medium);
    var onSurfaceDisable = TdThemeHelper.colorBlend(
        surface, onSurface, TdResColorEmphasize.disabled);
    var onSurfaceLowest = TdThemeHelper.colorBlend(
        surface, onSurface, TdResColorEmphasize.lowest);
    var primary = TdThemeHelper.colorPrimary(surface, seedColor);
    var primaryHigh = TdThemeHelper.colorBlend(
        seedColor, onSurface, TdResColorEmphasize.lowest);
    var primaryLight = TdThemeHelper.colorBlend(
        seedColor, surface, TdResColorEmphasize.disabled);
    var secondaryLightComputed = secondaryLight ?? TdThemeHelper.colorBlend(
        secondaryColor, surface, TdResColorEmphasize.disabled);

    return AppThemeColors(
        back: back,
        surface: surface,
        onSurface: onSurface,
        onSurfaceHigh: onSurfaceHigh,
        onSurfaceMedium: onSurfaceMedium,
        onSurfaceDisable: onSurfaceDisable,
        onSurfaceLowest: onSurfaceLowest,
        primaryHigh: primaryHigh,
        primary: primary,
        primaryLight: primaryLight,
        seedColor: seedColor,
        secondaryLight: secondaryLightComputed,
        secondaryColor: secondaryColor,
        errorColor: Color(0xFFEF3C54),
        isDark: isDark);
  }
}
