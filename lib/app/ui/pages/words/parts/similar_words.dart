import 'package:dharak_flutter/res/layouts/containers.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';

class WordSimilarWordsWidget extends StatelessWidget {
  final AppThemeColors? themeColors;
  final AppThemeDisplay? appThemeDisplay;
  final List<String> similarWords;

  final Function(String queryStr)? onSearchClick;

  const WordSimilarWordsWidget({
    super.key,
    this.similarWords = const [],
    this.onSearchClick,
    this.themeColors,
    this.appThemeDisplay,
  });

  @override
  Widget build(BuildContext context) {
    if (similarWords.isEmpty) {
      return SizedBox.shrink();
    }

    // return Container()

    return CommonContainer(
      appThemeDisplay: appThemeDisplay,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: TdResDimens.dp_16,
        children: [
          TdResGaps.v_12,
          Text(
            "Here are some similar words you might be interested in:",
            style: TdResTextStyles.h5,
          ),

          Wrap(
            direction: Axis.horizontal,
            spacing: TdResDimens.dp_8,
            runSpacing: TdResDimens.dp_4,
            children: similarWords.map((e) => _widgetItem(e)).toList(),
          ),

          TdResGaps.v_32,
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

  Widget _widgetItem(String word) {
    return OutlinedButton(
      onPressed: () {
        // onClickUpdate?.call(entity.address!);

        onSearchClick?.call(word);
      },
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.all(0),

        side: BorderSide(

          color:
              Color.alphaBlend(
                themeColors?.onSurface.withAlpha(0x66) ?? Colors.white,
                themeColors?.secondaryColor ?? Colors.red,
              ) .withAlpha(0x64),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TdResDimens.dp_16),
        ),

        // backgroundColor: themeColors?.surface
      ),
      child: Text(
        word,
        style: TdResTextStyles.buttonSmall.copyWith(
          color: Color.alphaBlend(
            themeColors?.onSurface.withAlpha(0x76) ?? Colors.white,
            themeColors?.secondaryColor ?? Colors.red,
          ),
        ),
      ),
    );
    // Container(
    //   // alignment: Alignment.centerLeft,
    //   // constraints: BoxConstraints(maxWidth: double.minPositive),
    //   padding: EdgeInsets.symmetric(
    //     vertical: TdResDimens.dp_8,
    //     horizontal: TdResDimens.dp_16,
    //   ),
    //   decoration: BoxDecoration(
    //     // color: ,
    //     borderRadius: BorderRadius.circular(TdResDimens.dp_12),
    //     border: Border.all(
    //       // width: 1,
    //       color: themeColors?.secondaryLight ?? Colors.red,
    //     ),
    //     gradient: LinearGradient(
    //       colors: [
    //         Color.alphaBlend(
    //           themeColors?.secondaryColor.withAlpha(0x10) ?? Colors.amber,
    //           themeColors?.surface ?? Colors.white70,
    //         ),
    //         Color.alphaBlend(
    //           themeColors?.secondaryColor.withAlpha(0x14) ?? Colors.amber,
    //           themeColors?.surface ?? Colors.white70,
    //         ),
    //       ],
    //     ),
    //   ),
    //   child: Text(
    //     "${word}",
    //     style: TdResTextStyles.h5Medium.merge(
    //       TextStyle(
    //         color: UtilColor.darken(
    //           themeColors?.secondaryColor ?? Colors.red,
    //           0.4,
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }
}
