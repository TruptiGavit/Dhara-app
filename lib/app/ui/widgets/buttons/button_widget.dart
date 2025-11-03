
import 'package:dharak_flutter/app/utils/util_color.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';

class TdButtonWidget extends StatelessWidget {
  // static const TYPE_ICON = 0;
  // static const TYPE_DEFAULT = 1;
  static const WIDTH_WRAP = 0;
  static const WIDTH_EXPANDED = 1;

  final String? mTxt;
  final IconData? mIconData;
  // final bool mIsSecondary;
  final bool mIsRtl;
  final bool mIsCompact;
  final bool? isInProgress;
  final VoidCallback? mOnClicked;

  final int mWidthType;

  // Color _mColorPrimaryHigh = Colors.greenAccent;
  Color? seedColor; //= Colors.green;
  final Color? textColor; //= Colors.green;
  final AppThemeColors? themeColors;

  Color _mColorBackgroundHigh = Colors.greenAccent;
  Color _mColorBackground = Colors.green;
  Color _mColorText = Colors.white;

  final double borderRadius;
  /** for width */
  Size? minSize;
  double? minHeight;

  bool mIsSecondary;

  TdButtonWidget(
      {Key? key,
      required this.mOnClicked,
      this.mTxt,
      this.mIconData,
      int widthType = WIDTH_WRAP,
      bool isSecondary = false,
      bool isRtl = false,
      bool isCompact = false,
      this.borderRadius = TdResDimens.dp_12,
      this.minSize,
      this.minHeight,
      this.themeColors,
      this.seedColor,
      this.textColor,
      this.isInProgress})
      : mWidthType = widthType,
        mIsRtl = isRtl,
        mIsCompact = isCompact,
        mIsSecondary = isSecondary,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    prepareTheme(context);
    return Container(
      // constraints: BoxConstraints.loose(buttonSize()),
      // padding: EdgeInsets.zero,
      // constraints: BoxConstraints(
      //   maxHeight: double.minPositive
      // ),
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,

      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(borderRadius + 2), // Make the button rounded
        border: Border(
          bottom: BorderSide(
            color: mOnClicked != null
                ? UtilColor.darken(_mColorBackgroundHigh)
                : Colors.transparent, // Set the bottom border color
            width: 2.0, // Set the bottom border width
          ),
        ),
      ),

      // child: Container(height:20, width: 200, color: Colors.amber,),
      // child: ElevatedButton(
      //   child: Text("data"),
      //   style: ElevatedButton.styleFrom(
      //     // elevation: 0,

      //     padding: EdgeInsets.zero,
      //     backgroundColor: _mColorBackground,
      //     // minimumSize: buttonSize(),

      //     ),

      //   onPressed: (){},
      // ),

      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          // elevation: 0,

          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
          backgroundColor: _mColorBackground,
          minimumSize: buttonSize(),
          shadowColor: _mColorBackground.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          foregroundColor: Colors.white,

          // primary: Colors.transparent,
          // onPrimary: onSurfaceDisabled,

          // shape: RoundedRectangleBorder(
          //   borderRadius: BorderRadius.circular(18.0),
          // ),
        ),
        onPressed:
            mOnClicked, // mOnClicked!=null ? () => {mOnClicked?.call()} : null,
        // child: Ink(
        //   decoration: BoxDecoration(
        //     gradient: LinearGradient(
        //         begin: const Alignment(0, -1),
        //         end: const Alignment(0, 1),
        //         colors: [_mColorBackgroundHigh, _mColorBackground]),
        //     borderRadius: const BorderRadius.all(Radius.circular(28)),
        //   ),
        child: getChild(),
        // ),
      ),
    );
  }

  Widget getChild() {
    var padding = mIsCompact
        ? const EdgeInsets.symmetric(
            horizontal: TdResDimens.dp_16, vertical: TdResDimens.dp_8)
        : const EdgeInsets.symmetric(
            horizontal: TdResDimens.dp_32, vertical: TdResDimens.dp_12);

    if (isInProgress == true) {
      padding = mIsCompact
          ? const EdgeInsets.symmetric(
              horizontal: TdResDimens.dp_16, vertical: TdResDimens.dp_2)
          : const EdgeInsets.symmetric(
              horizontal: TdResDimens.dp_32, vertical: TdResDimens.dp_6);
      return Container(
        padding: mIconData != null && mTxt == null
            ? const EdgeInsets.symmetric(
                horizontal: TdResDimens.dp_4, vertical: TdResDimens.dp_4)
            : padding,
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }
    if (mIconData == null) {
      return Container(
        padding: padding,
        constraints: minSize != null
            ? BoxConstraints(minWidth: minSize!.width)
            : minHeight != null
                ? BoxConstraints(minHeight: minHeight!)
                : null,
        // alignment: Alignment.center,
        child: Row(
            textDirection: mIsRtl ? TextDirection.rtl : TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: rowAxisSize(),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                mTxt ?? "",
                style: (mIsCompact
                        ? TdResTextStyles.buttonSmall
                        : TdResTextStyles.button)
                    .copyWith(color: _mColorText),
              )
            ]),
      );
    } else if (mTxt == null) {
      return Container(
        padding: mIsCompact ? const EdgeInsets.symmetric(
            horizontal: TdResDimens.dp_12, vertical: TdResDimens.dp_12) : const EdgeInsets.symmetric(
            horizontal: TdResDimens.dp_16, vertical: TdResDimens.dp_16),
        child: Icon(
          mIconData,
          color: _mColorText,
          size: mIsCompact ?  20 : 24,
        ),
      );
    } else {
      return Container(
        padding: padding,
         constraints: minSize != null
            ? BoxConstraints(minWidth: minSize!.width, minHeight:  minHeight??0.0)
            : minHeight != null
                ? BoxConstraints(minHeight: minHeight!)
                : null,
        child: Row(
          mainAxisAlignment:  minSize != null
            ? MainAxisAlignment.center
            :MainAxisAlignment.start,
            textDirection: mIsRtl ? TextDirection.rtl : TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: rowAxisSize(),
            children: [
              mIconData != null
                  ? Icon(
                      mIconData,
                      color: _mColorText,
                      size: mIsCompact ? 16 :  20,
                    )
                  : const SizedBox.shrink(),
              TdResGaps.h_4,
              Text(
                mTxt ?? "",
                style: TdResTextStyles.button.copyWith(color: _mColorText),
              ),
            ]),
      );
    }
  }

  Size buttonSize() {
    // debugPrint("buttonSize: $mWidthType");
    // if (minSize != null) {
    //   return minSize!;
    // } else
    if (mWidthType == WIDTH_EXPANDED) {
      return const Size(double.maxFinite, double.minPositive);
    } else {
      // debugPrint("buttonSize 2: $mWidthType");
      return const Size(double.minPositive, double.minPositive);
    }
  }

  double buttonWidth() {
    if (mWidthType == WIDTH_EXPANDED) {
      return double.maxFinite;
    } else {
      return double.minPositive;
    }
  }

  double buttonContainerMaxHeight() {
    if (mWidthType == WIDTH_EXPANDED) {
      return double.maxFinite;
    } else {
      return double.minPositive;
    }
  }

  MainAxisSize rowAxisSize() {
    if (mWidthType == WIDTH_EXPANDED) {
      return MainAxisSize.max;
    } else {
      return MainAxisSize.min;
    }
  }

  prepareTheme(BuildContext context) {
    if (seedColor == null) {
      if (mIsSecondary) {
        seedColor = themeColors?.secondaryColor;
      } else {
        seedColor = themeColors?.primary;
      }
      // seedColor
    }
    var seed = seedColor ?? Colors.green;

    _mColorBackgroundHigh = UtilColor.darken(seed);
    _mColorBackground = seed;
    _mColorText = mOnClicked == null
        ? (themeColors?.onSurfaceDisable ?? Colors.black26)
        : textColor ?? Colors.white;

    // print("button_widget: $_mColorText");

    //  debugPrint("prepareTheme 2: $_mColorOnSurface04 ");
  }

  // prepareTheme(BuildContext context) {
  //   if (mIsSecondary) {
  //     _mColorBackgroundHigh = TbThemeHelper.colorBlend(
  //         context,
  //         TbThemeColor.surface,
  //         TbThemeColor.secondary,
  //         TbColorEmphasize.medium);
  //     _mColorBackground = Theme.of(context).colorScheme.secondary;
  //   } else {
  //     _mColorBackgroundHigh = TbThemeHelper.colorBlend(context,
  //         TbThemeColor.surface, TbThemeColor.primary, TbColorEmphasize.medium);
  //     _mColorBackground = Theme.of(context).colorScheme.primary;
  //   }
  // }
}
