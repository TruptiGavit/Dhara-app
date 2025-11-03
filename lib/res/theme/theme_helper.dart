import 'package:dharak_flutter/res/values/colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:flutter/material.dart';

class TdThemeHelper {
  static AppThemeDisplay prepareThemeDisplay(BuildContext context) {
    var height = MediaQuery.of(context).size.height;

    var width = MediaQuery.of(context).size.width;

    return AppThemeDisplay(
        height: height, width: width, isSamllHeight: height < 630);
  }

  static Color colorBlend(Color background, Color foregroundColor,
      TdResColorEmphasize foregroundEmphasize) {
    return Color.alphaBlend(
        foregroundColor.withOpacity(TdResColors.alpha(foregroundEmphasize)),
        background);
  }

  static Color colorPrimary(
    Color background,
    Color seedColor,
  ) {
    return Color.alphaBlend(
        seedColor.withOpacity(TdResColors.alpha(TdResColorEmphasize.high)),
        background);
  }

  static Color colorSurface({bool isDark = false}) {
    var surfaceBasedColor = isDark
        ? Color.alphaBlend(Colors.white.withOpacity(0.1), Colors.black)
        : Colors.white;
    return surfaceBasedColor;
  }

  static Color colorBack({bool isDark = false}) {
    var surfaceBasedColor = isDark
        ? Colors.black
        : Color.alphaBlend(Colors.black.withOpacity(0.02), Colors.white);
    return surfaceBasedColor;
  }

  static Color colorOnSurface({bool isDark = false}) {
    var onSurfaceBasedColor = isDark ? Colors.white : Colors.black;
    return onSurfaceBasedColor;
  }
}

enum ThemeColorType { primary, secondary, surface, onSurface, background }
