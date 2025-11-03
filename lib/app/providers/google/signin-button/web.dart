import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'stub.dart';

/// Renders a SIGN IN button that calls `handleSignIn` onclick for web.

Widget googleSignInButton({
  AppThemeColors? themeColors,
  AppThemeDisplay? appThemeDisplay,
  HandleSignInFn? onPressed,
  bool isDense = false,
}) {
  return ElevatedButton(
    onPressed: () {
      onPressed?.call();
    },
    style: ElevatedButton.styleFrom(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.3),

      minimumSize: Size(
        isDense ? double.minPositive : double.infinity,
        double.minPositive,
      ),
      backgroundColor: Color.alphaBlend(
        themeColors?.back.withAlpha(0x12) ?? Colors.black12,
        themeColors?.surface ?? Colors.white,
      ),
      foregroundColor: themeColors?.onSurface ?? Colors.black,
      padding:
          appThemeDisplay?.isSamllHeight == true || isDense
              ? const EdgeInsets.symmetric(
                horizontal: TdResDimens.dp_16,
                vertical: TdResDimens.dp_12,
              )
              : const EdgeInsets.symmetric(
                horizontal: TdResDimens.dp_24,
                vertical: TdResDimens.dp_20,
              ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.3),
          width: 1.0,
        ),
      ),
    ),
    child: Row(
      mainAxisSize: isDense ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/svg/google_icon.svg',
          width: TdResDimens.dp_20,
        ),
        TdResGaps.h_12,
        Flexible(
          fit: FlexFit.tight,
          flex: isDense ? 0 : 1,
          child: Text(
            isDense ? "Sign-In" : "Google Sign-In",
            textAlign: TextAlign.center,
            style: TdResTextStyles.button.copyWith(
              color: themeColors?.onSurface ?? Colors.black,
            ),
          ),
        ),
        TdResGaps.h_20,
      ],
    ),
  );
}