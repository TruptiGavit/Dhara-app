import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/values/colors.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TdResDecorations {
  static BoxDecoration decorationCard(Color borderColor, Color shadow,
      {bool isElevated = true}) {
    debugPrint("decorationCard: $borderColor, $shadow");
    return BoxDecoration(
        border: Border.all(color: borderColor),
        color: borderColor.withOpacity(0.75),
        boxShadow: [
          isElevated
              ? BoxShadow(
                  blurRadius: 8.0,
                  offset: const Offset(1, 8),
                  color: shadow.withOpacity(0.04))
              : BoxShadow(
                  blurRadius: 2.0,
                  offset: const Offset(1, 2),
                  color: shadow.withOpacity(0.04))
        ]);
  }

   static BoxDecoration decorationCardOutlined(Color borderColor, Color background, 
      {bool isElevated = true, Color? shadow,}) {
    // debugPrint("decorationCardOutlined: $borderColor, $shadow");
    return BoxDecoration(
        border: Border.all(color: borderColor),
        color: background,
        boxShadow: [
          isElevated
              ? BoxShadow(
                  blurRadius: 8.0,
                  offset: const Offset(1, 8),
                  color: shadow??borderColor.withOpacity(0.04))
              : BoxShadow(
                  blurRadius: 2.0,
                  offset: const Offset(1, 2),
                  color: shadow??borderColor.withOpacity(0.04))
        ]);
  }

  static BoxDecoration decorationCardAction(Color background,
      {required AppThemeColors appThemeColors}) {
    debugPrint("decorationCard: $background");
    return BoxDecoration(
        border: Border(
          bottom: BorderSide(color: appThemeColors.primary),
        ),
        // color: borderColor.withOpacity(0.6),
        gradient: LinearGradient(colors: [
          appThemeColors.primaryLight,
          Color.alphaBlend(appThemeColors.primaryLight, background)
        ]),
        boxShadow: [
          BoxShadow(
              blurRadius: 8.0,
              offset: const Offset(1, 8),
              color: appThemeColors.primary.withOpacity(0.04))
        ]);
  }

  static BoxDecoration decorationCardActionForColor(
      Color surface, Color colorOnSurface) {
    // debugPrint("decorationCard: $background");
    return BoxDecoration(
        // border: Border(
        //   bottom: BorderSide(color: TdResColors.colorPrimary),
        // ),
        // color: borderColor.withOpacity(0.6),
        gradient: LinearGradient(colors: [
          Color.alphaBlend(colorOnSurface.withOpacity(0.2), surface),
          Color.alphaBlend(colorOnSurface.withOpacity(0.1), surface)
        ]),
        boxShadow: [
          BoxShadow(
              blurRadius: 8.0,
              offset: const Offset(1, 8),
              color: colorOnSurface.withOpacity(0.04))
        ]);
  }

  static BoxDecoration decorationCardPrimaryLight(Color background,
      {required AppThemeColors appThemeColors}) {
    // debugPrint("decorationCard: $background");
    return BoxDecoration(

        // color: borderColor.withOpacity(0.6),
        gradient: LinearGradient(colors: [
          appThemeColors.primaryLight,
          Color.alphaBlend(appThemeColors.primaryLight, background)
        ]),
        boxShadow: [
          BoxShadow(
              blurRadius: 8.0,
              offset: const Offset(1, 8),
              color: appThemeColors.primary.withOpacity(0.04))
        ]);
  }

  static BoxDecoration decorationCardSeedLight(Color background,
      {required Color seedLight, required Color seed}) {
    // debugPrint("decorationCard: $background");
    return BoxDecoration(

        // color: borderColor.withOpacity(0.6),
        gradient: LinearGradient(colors: [
          seedLight,
          Color.alphaBlend(seedLight, background)
        ]),
        boxShadow: [
          BoxShadow(
              blurRadius: 8.0,
              offset: const Offset(1, 8),
              color: seed.withOpacity(0.04))
        ]);
  }

  static BoxDecoration decorationDialogBackground(
      Color colorSurface, Color colorOnSurface) {
    return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.alphaBlend(colorOnSurface.withOpacity(0.01), colorSurface).withOpacity(0.92),
            Color.alphaBlend(colorOnSurface.withOpacity(0.02), colorSurface).withOpacity(0.92)
          ],
          begin: Alignment(-1, -1),
          end: Alignment(1, 1),
        ),
        border: Border.fromBorderSide(BorderSide(
          width: 2,
          color: colorSurface
        )),
        boxShadow: [
          BoxShadow(
              blurRadius: 8.0,
              offset: const Offset(1, 8),
              color: colorOnSurface.withOpacity(0.04))
        ]);
  }

  static BoxDecoration selectedBackground(Color colorOnSurface) {
    // debugPrint("decorationCard: $background");
    return BoxDecoration(
      color: colorOnSurface.withOpacity(0.06),
      border: Border(
        bottom: BorderSide(color: colorOnSurface.withOpacity(0.14)),
      ),
      // color: borderColor.withOpacity(0.6),
    );
  }

  static BoxDecoration borderBottom(Color colorOnSurface) {
    // debugPrint("decorationCard: $background");
    return BoxDecoration(
      border: Border(
        bottom: BorderSide(color: colorOnSurface.withOpacity(0.1)),
      ),
      // color: borderColor.withOpacity(0.6),
    );
  }

  static BoxDecoration borderTop(Color colorOnSurface) {
    // debugPrint("decorationCard: $background");
    return BoxDecoration(
      border: Border(
        top: BorderSide(color: colorOnSurface.withOpacity(0.1)),
      ),
      // color: borderColor.withOpacity(0.6),
    );
  }

  /* ***********************************************************
   *                input
   */

  static BoxDecoration inputSmallDecorationOuter(AppThemeColors? themeColors,
      {bool isLight = false, double radius =TdResDimens.dp_8, Color color =TdResColors.colorInput}) {
    // debugPrint("decorationCard: $background");
    return BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border(
          top: BorderSide(
            color: Color.alphaBlend(
                color.withOpacity(isLight ? 0.1 : 0.4),
                themeColors?.surface ??
                    Colors.white), // Set the bottom border color
            width: 2.0,
          ),
        ),
        color: Color.alphaBlend(
            color.withOpacity(isLight ? 0.05 : 0.3),
            themeColors?.surface ?? Colors.white));
            
  }

  static InputDecoration inputSmallDecorationInner(
      AppThemeColors? themeColors) {
    // debugPrint("decorationCard: $background");
    return InputDecoration(
      focusColor: themeColors?.primaryLight,
      border: InputBorder.none,

      isDense: true,
      // hintText: "Type name ..",
      hintStyle: TdResTextStyles.h5.merge(TextStyle(
          color: Color.alphaBlend(TdResColors.colorInput.withOpacity(0.2),
              themeColors?.onSurfaceMedium ?? Colors.black54))),
      contentPadding:
          const EdgeInsets.only(left: 10, right: 10, bottom: 8, top: 6),
    );
  }
}
