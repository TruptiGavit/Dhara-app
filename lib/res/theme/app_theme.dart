import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:flutter/material.dart';

export 'app_theme_colors.dart';
export 'app_theme_display.dart';
export 'app_theme_provider.dart';
export 'theme_helper.dart';


class AppTheme {
  // static ThemeData lightThemeData =
  //     themeData(lightColorScheme, _lightFocusColor);

  // static ThemeData darkThemeData = themeData(darkColorScheme, _darkFocusColor);

  static Color colorSurface({bool isDark = false}){
    // var surfaceBasedColor = isDark ? Color.alphaBlend(Colors.white.withOpacity(0.1),Colors.black) : Colors.white;
    // return surfaceBasedColor;
    return TdThemeHelper.colorSurface(isDark: isDark);


  }

   static Color colorBack({bool isDark = false}){
    // var surfaceBasedColor = isDark ? Colors.black : Color.alphaBlend(Colors.black.withOpacity(0.03),Colors.white);
    // return surfaceBasedColor;
    return TdThemeHelper.colorBack(isDark: isDark);

  }

  static Color colorOnSurface({bool isDark = false}){
    // var onSurfaceBasedColor = isDark ? Colors.white :Colors.black  ;
    // return onSurfaceBasedColor;
    return TdThemeHelper.colorOnSurface(isDark: isDark);

  }

  static ThemeData themeData(
      {Color seedColor = Colors.red, bool isDark = false}) {

    var surfaceBasedColor = TdThemeHelper.colorSurface(isDark: isDark);
    var colorBack = TdThemeHelper.colorBack(isDark: isDark);
    var onSurfaceBasedColor = TdThemeHelper.colorOnSurface(isDark: isDark);

    final Color focusColor =  onSurfaceBasedColor.withOpacity(0.12);
        // : Colors.black.withOpacity(0.12);

    ColorScheme colorScheme = isDark
        ? ColorScheme.fromSeed(seedColor: seedColor).copyWith(
            brightness: Brightness.dark,

            // onPrimary: _lightFillColor,
            // onSecondary: _darkFillColor,
            // onError: _darkFillColor,
            background:
                colorBack, // TbResColors.colorBgDark,//_darkFillColor, //Color(0xFF241E30),
            onBackground: onSurfaceBasedColor, // White with 0.05 opacity
            surface:
                surfaceBasedColor, // TbResColors.colorSurfaceDark,//Color(0xFF1F1929),
            onSurface: onSurfaceBasedColor,
            // primaryContainer: Color(0xFF1CDEC9),
            // secondaryContainer: Color(0xFF457B6F),
          )
        : ColorScheme.fromSeed(seedColor: seedColor).copyWith(
            brightness: Brightness.light,
            // onPrimary: _darkFillColor,
            // onSecondary: Color(0xFF322942),
            // onError: _darkFillColor,
             background:
                colorBack, 
            onBackground: onSurfaceBasedColor,
            surface: surfaceBasedColor, //TbResColors.colorSurfaceLight,
            onSurface: onSurfaceBasedColor, //_darkFillColor,
            // primaryContainer: Color(0xFF117378),
            // secondaryContainer: Color(0xFFFAFBFB),
          );

    // var colorScheme = if()
    return ThemeData(
      colorScheme: colorScheme,
      textTheme: _textTheme,
      
      // Matches manifest.json colors and background color.
      primaryColor: const Color(0xFF030303),
      appBarTheme: AppBarTheme(
        // backgroundColor: colorScheme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.primary),
        color: colorScheme.background,
      ),
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      canvasColor: colorScheme.background,
      scaffoldBackgroundColor: colorScheme.background,
      highlightColor: Colors.transparent,
      focusColor: focusColor,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color.alphaBlend(
          onSurfaceBasedColor.withOpacity(0.80),
          surfaceBasedColor,
        ),
        contentTextStyle: _textTheme.bodyLarge!,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
         menuStyle: MenuStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
          )  
          
          // RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
         )
      ),
      popupMenuTheme: PopupMenuThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
  )
    );
  }

  static final TextTheme _textTheme = TextTheme(
      displayLarge: TdResTextStyles.h1,
      displayMedium: TdResTextStyles.h2,
      displaySmall: TdResTextStyles.h3,
      titleLarge: TdResTextStyles.h4,
      titleMedium: TdResTextStyles.h5,
      titleSmall: TdResTextStyles.h6,
      bodyLarge: TdResTextStyles.p1,
      bodyMedium: TdResTextStyles.p2,
      bodySmall: TdResTextStyles.p3,
      labelLarge: TdResTextStyles.caption);
}
