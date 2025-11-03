
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:flutter/material.dart';

class WordSpecialScriptWidget extends StatelessWidget {
  final AppThemeColors? themeColors;
  final AppThemeDisplay? appThemeDisplay;
  final Map<String, String?>? otherScripts;

  const WordSpecialScriptWidget({
    super.key,
    this.otherScripts,
    this.themeColors,
    this.appThemeDisplay,
  });

  @override
  Widget build(BuildContext context) {
    if (otherScripts == null || otherScripts?["devanagari"] == null) {
      return SizedBox.shrink();
    }

    // return Container()

    return Container(
      // alignment: Alignment.centerLeft,
      // constraints: BoxConstraints(maxWidth: double.minPositive),
      margin: EdgeInsets.symmetric(vertical: 1),
      padding: EdgeInsets.symmetric(vertical: TdResDimens.dp_8, horizontal: TdResDimens.dp_16),
      decoration: BoxDecoration(
        // color: ,
        borderRadius: BorderRadius.circular(TdResDimens.dp_12),
        border: Border.all(
          // width: 1,
          color: themeColors?.secondaryLight??Colors.red
        ),
        gradient: LinearGradient(
          colors: [
            Color.alphaBlend(
              themeColors?.secondaryColor.withAlpha(0x10) ?? Colors.amber,
              themeColors?.surface ?? Colors.white70,
            ),
            Color.alphaBlend(
              themeColors?.secondaryColor.withAlpha(0x14) ?? Colors.amber,
              themeColors?.surface ?? Colors.white70,
            ),
          ],
        ),
      ),
      child: Row(
        // crossAxisAlignment: WrapCrossAlignment.center,
        // direction: Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        spacing: TdResDimens.dp_12,
        children: [
          Icon(Icons.translate, color: Color.alphaBlend(
              themeColors?.onSurface.withAlpha(0x96) ?? Colors.black38,
              themeColors?.secondaryLight ?? Colors.red,
            ),
          size: TdResDimens.dp_20,),
          Text(
            "${otherScripts?["devanagari"]}",
            style: TdResTextStyles.h5Medium.merge(
              TextStyle(color: Color.alphaBlend(
              themeColors?.onSurface.withAlpha(0x96) ?? Colors.black38,
              themeColors?.secondaryLight ?? Colors.red,
            ),),
            ),
          ),
        ],
      ),
    );
    // return CommonContainer(
    //   appThemeDisplay: appThemeDisplay,
    //   child: Column(
    //     children: [
    //       Align(
    //         alignment: Alignment.topLeft,
    //         child: Text(
    //           "${otherScripts?["devanagari"]}",
    //           style: TdResTextStyles.h5Medium.merge(
    //             TextStyle(color: themeColors?.onSurface),
    //           ),
    //         ),
    //       ),
    //       TdResGaps.v_12,
    //     ],
    //   ),
    // );
  }
}
