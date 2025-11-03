
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/layouts/breakpoints.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';

class CommonContainer extends StatelessWidget {
  final mLogger = Logger();
  final AppThemeDisplay? appThemeDisplay;
  // ThemeColorsType themeColors;
  // BankerSecureBox entity;

  final bool mIsEditing;
  final GlobalKey buttonKey;

  final double defaultPadding;

  // final Function(BankerSecureBox bankerSecureBox, GlobalKey itemKey) onClickMenu;

  final Widget child;
  CommonContainer({
    Key? key,
    this.appThemeDisplay,
    this.defaultPadding = 20,
    // required this.entity,
    required this.child,
    bool isEditing = false,
    // required this.onClickMenu
  })  : mIsEditing = isEditing,
        buttonKey = GlobalKey(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    var max = maxWidth();

    // mLogger.d("CommonContainer: ${max}");
    return Align(
      child: Container(
        padding:  EdgeInsets.only(
            left: defaultPadding, right: defaultPadding), //  top: 8.0, bottom: 4.0
        constraints: BoxConstraints.loose(
          max != null
              ? Size.fromWidth(max.toDouble())
              : Size.fromWidth(double.maxFinite),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  int? maxWidth() {
    if (appThemeDisplay?.breakpointType == BreakpointType.lg) {
      return Breakpoints.BREAKPOINTS_VALUES[BreakpointType.md];
    } else if (appThemeDisplay?.breakpointType == BreakpointType.xl) {
      return Breakpoints.BREAKPOINTS_VALUES[BreakpointType.lg];
    } else if (appThemeDisplay?.breakpointType == BreakpointType.xxl) {
      return Breakpoints.BREAKPOINTS_VALUES[BreakpointType.xl];
    } else if (appThemeDisplay?.breakpointType == BreakpointType.xxxl) {
      return Breakpoints.BREAKPOINTS_VALUES[BreakpointType.xxl];
    } else {
      return null;
    }
  }
}

class FillContainer extends StatelessWidget {
  final mLogger = Logger();
  final AppThemeDisplay? appThemeDisplay;
  // ThemeColorsType themeColors;
  // BankerSecureBox entity;


  // final Function(BankerSecureBox bankerSecureBox, GlobalKey itemKey) onClickMenu;

  final Widget child;
  FillContainer({
    super.key,
    this.appThemeDisplay,
    // required this.entity,
    required this.child,
    bool isEditing = false,
    // required this.onClickMenu
  });

  @override
  Widget build(BuildContext context) {
    var sideOffset = _sideOffset();

    // mLogger.d("FillContainer: ${sideOffset}");
    return Align(
      child: Container(
        // padding: const EdgeInsets.only(
        //     left: 20.0, right: 20.0, top: 8.0, bottom: 4.0),
        // constraints: max != null
        //     ? BoxConstraints.loose(Size.fromWidth(max.toDouble()))
        //     : null,
            margin: EdgeInsets.symmetric(horizontal: sideOffset),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  

  double _sideOffset(){
    if (appThemeDisplay?.breakpointType == BreakpointType.sm) {
      return TdResDimens.dp_12;
    } else if (appThemeDisplay?.breakpointType == BreakpointType.md) {
      return TdResDimens.dp_32;
    } else if (appThemeDisplay?.breakpointType == BreakpointType.lg) {
      return TdResDimens.dp_56;
    } else {
      return TdResDimens.dp_72;
    }
  }
}



class CommonDialogContainer extends StatelessWidget {
  final mLogger = Logger();
  final AppThemeDisplay? appThemeDisplay;
  // ThemeColorsType themeColors;
  // BankerSecureBox entity;

  final bool mIsEditing;
  final GlobalKey buttonKey;

  // final Function(BankerSecureBox bankerSecureBox, GlobalKey itemKey) onClickMenu;

  final Widget child;
  CommonDialogContainer({
    super.key,
    this.appThemeDisplay,
    // required this.entity,
    required this.child,
    bool isEditing = false,
    // required this.onClickMenu
  })  : mIsEditing = isEditing,
        buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    var max = maxWidth();

    // mLogger.d("CommonContainer: ${max}");
    return Align(
      child: Container(
        // padding: const EdgeInsets.only(
        //     left: 20.0, right: 20.0, top: 8.0, bottom: 4.0),
        constraints: max != null
            ? BoxConstraints.loose(Size.fromWidth(max.toDouble()))
            : null,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  int? maxWidth() {
    if (appThemeDisplay?.breakpointType == BreakpointType.lg) {
      return Breakpoints.BREAKPOINTS_VALUES[BreakpointType.md];
    } else if (appThemeDisplay?.breakpointType == BreakpointType.xl) {
      return Breakpoints.BREAKPOINTS_VALUES[BreakpointType.md];
    } else if (appThemeDisplay?.breakpointType == BreakpointType.xxl) {
      return Breakpoints.BREAKPOINTS_VALUES[BreakpointType.md];
    } else if (appThemeDisplay?.breakpointType == BreakpointType.xxxl) {
      return Breakpoints.BREAKPOINTS_VALUES[BreakpointType.md];
    } else {
      return null;
    }
  }
}
