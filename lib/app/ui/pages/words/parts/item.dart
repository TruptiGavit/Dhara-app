import 'package:dharak_flutter/app/types/dictionary/definition.dart';
import 'package:dharak_flutter/app/ui/widgets/code_wrapper.dart';
import 'package:dharak_flutter/res/layouts/containers.dart';
import 'package:dharak_flutter/res/styles/decorations.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/blocks/leaf/code_block.dart';
import 'package:markdown_widget/widget/markdown.dart';

class WordDefinitionItemWidget extends StatelessWidget {
  // final String title;

  final AppThemeColors? themeColors;
  final AppThemeDisplay? appThemeDisplay;

  final WordDefinitionRM entity;

  final Function(String message)? onClickCopy;
  final Function(String urlLink)? onClickExternalUrl;

  // final Function(String id)? onClick;
  // List<String>  ds = ["Wew", "wer"];
  const WordDefinitionItemWidget({
    super.key,
    // this.title = 'StoreSettingPresenseSection',
    this.themeColors,
    this.appThemeDisplay,
    // this.onClick,
    // this.isSubmitValid,
    required this.entity,
    this.onClickCopy,
    this.onClickExternalUrl,
    // this.customizationGroups = const [],
    // this.customizations = const []
  });

  @override
  Widget build(BuildContext context) {
    // prepareTheme(context);
    return _widgetContents();
    // return SizedBox(height: 200,);
    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text(widget.title),
    //   ),
    //   body: Column(
    //     children: <Widget>[],
    //   ),
    // );
  }

  /* ************************************************************************************
   *                                        Widget
   */

  Widget _widgetContents() {
    // Container(
    //   // decoration: BoxDecoration(
    //   //     borderRadius: BorderRadius.circular(TdResDimens.dp_24),
    //   //     color: themeColors?.primary),
    //   // padding: const EdgeInsets.symmetric(
    //   //     horizontal: TdResDimens.dp_12, vertical: TdResDimens.dp_12),
    //   child:
    return CommonContainer(
      appThemeDisplay: appThemeDisplay,

      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: TdResDimens.dp_12),

        decoration: TdResDecorations.decorationCardOutlined(
          // Color.alphaBlend(
          //   themeColors?.onSurface.withAlpha(0x62) ?? Colors.black12,
          //   themeColors?.secondaryColor ?? Colors.red,
          // ),
          Colors.transparent,

          //      Color.alphaBlend(
          //   themeColors.secondaryColor.withAlpha(0x12),
          //   themeColors.surface,
          // )
          // Color.alphaBlend(
          //   themeColors?.secondaryColor.withAlpha(0x10) ?? Colors.black12,
          //   themeColors?.back ?? Colors.red,
          // )?? Colors.white70,
          (themeColors?.isDark == true
                  ? themeColors?.onSurface.withAlpha(0x08)
                  : themeColors?.surface) ??
              Colors.white70,
          // themeColors?.surface.withAlpha(0x96) ?? Colors.white70,
          // Color.alphaBlend(
          //   themeColors?.secondaryColor.withAlpha(0x22) ?? Colors.red,
          //   themeColors?.surface?? Colors.black12,

          // ) ,
          isElevated: false,
          shadow:
              themeColors?.isDark == true
                  ? null
                  : themeColors?.secondaryColor.withAlpha(0x2),
          // shadow: themeColors?.secondaryColor
        ).copyWith(
          borderRadius: BorderRadius.circular(TdResDimens.dp_12),
          border: Border(
            left: BorderSide(
              width: 4,
              color: Color.alphaBlend(
                themeColors?.onSurface.withAlpha(0x56) ?? Colors.black38,
                themeColors?.secondaryLight ?? Colors.red,
              ),
            ),
          ),
        ),
        // decoration: BoxDecoration(
        //   borderRadius: BorderRadius.circular(TdResDimens.dp_24),
        //   color: themeColors?.primary,
        // ),
        // padding: const EdgeInsets.symmetric(
        //     horizontal: TdResDimens.dp_12, vertical: TdResDimens.dp_12),
        child: Column(
          children: [
            ExpandableNotifier(
              child: ExpandablePanel(
                // tapHeaderToExpand: true,
                collapsed: Container(
                  // alignment: Alignment.centerLeft,
                  // padding: EdgeInsets.symmetric(vertical: TdResDimens.dp_12),
                  padding: EdgeInsets.symmetric(
                    horizontal: TdResDimens.dp_16,
                    vertical: TdResDimens.dp_4,
                  ).copyWith(top: TdResDimens.dp_14),
                  child: Text(
                    entity.text,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TdResTextStyles.h5,
                  ),
                  // decoration: BoxDecoration(
                  //     border: Border(
                  //         bottom: BorderSide(
                  //             color:
                  //                 themeColors?.onSurfaceDisable ?? Colors.black12))),
                ),

                theme: ExpandableThemeData(
                  inkWellBorderRadius: BorderRadius.circular(TdResDimens.dp_18),
                  iconPadding: EdgeInsets.only(
                    right: TdResDimens.dp_8,
                    top: TdResDimens.dp_12,
                  ),
                  iconColor: themeColors?.onSurfaceHigh,
                  headerAlignment: ExpandablePanelHeaderAlignment.center,
                  tapBodyToExpand: true,
                  tapBodyToCollapse: true,
                  hasIcon: true,
                  // collapseIcon: Icons.pin_drop,
                  // bodyAlignment: ExpandablePanelBodyAlignment.left

                  // alignment: Alignment.center

                  //  expandIcon: Icons.arrow_right,
                  //                   collapseIcon: Icons.arrow_drop_down,
                  //                   iconColor: Colors.white,
                  //                   iconSize: 28.0,
                  //                   iconRotationAngle: math.pi / 2,
                  //                   iconPadding: EdgeInsets.only(right: 5),
                  //                   hasIcon: false,
                ),
                header: _widgetHeading(),

                expanded: _widgetExpanded(),
              ),
            ),
            _widgetActions(),
          ],
        ),
      ),
    );

    // return SizedBox.shrink();
  }

  Widget _widgetHeading() {
    var linkColor = Color.alphaBlend(
      themeColors?.onSurface.withAlpha(0x46) ?? Colors.black38,
      themeColors?.secondaryColor ?? Colors.red,
    );
    return Container(
      constraints: BoxConstraints(minHeight: TdResDimens.dp_40),
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.only(
        left: TdResDimens.dp_16,
        right: TdResDimens.dp_16,
        top: TdResDimens.dp_12,
      ),
      child: Row(
        spacing: TdResDimens.dp_6,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 20, color: linkColor),

          Flexible(
            flex: 1,
            child: Text(
              entity.srcShortTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,

              style: TdResTextStyles.p3.copyWith(
                color: Color.alphaBlend(
                  themeColors?.onSurface.withAlpha(0x66) ?? Colors.black38,
                  themeColors?.secondaryColor ?? Colors.red,
                ),
              ),
            ),
          ),
          // Flexible(
          //   flex: 1,
          //   child: RichText(
          //     text: TextSpan(
          //       children: [
          //         TextSpan(
          //           text: entity.srcShortTitle + ' ',

          //           style: TdResTextStyles.p3.copyWith(

          //             color: Color.alphaBlend(
          //               themeColors?.onSurface.withAlpha(0x66) ??
          //                   Colors.black38,
          //               themeColors?.secondaryColor ?? Colors.red,
          //             ),
          //           ),
          //         ),

          //         // WidgetSpan(
          //         //   child: SizedBox(
          //         //     height: 20,
          //         //     width: 24,
          //         //     child: IconButton(
          //         //       padding: EdgeInsets.all(0),
          //         //       // iconAlignment: IconAlignment.end,
          //         //       style: IconButton.styleFrom(
          //         //         // maximumSize: Size(200, 24),
          //         //         // iconColor: linkColor,
          //         //         shape: RoundedRectangleBorder(
          //         //           borderRadius: BorderRadius.circular(4),
          //         //         ),
          //         //         foregroundColor: linkColor,
          //         //         padding: EdgeInsets.symmetric(
          //         //           horizontal: TdResDimens.dp_4,
          //         //         ),
          //         //         backgroundColor: themeColors?.secondaryColor
          //         //             .withAlpha(0x2),
          //         //       ),

          //         //       onPressed: () {},
          //         //       icon: Icon(Icons.open_in_new, size: 18),
          //         //     ),
          //         //   ),
          //         // ),
          //         // WidgetSpan(
          //         //   alignment: PlaceholderAlignment.middle,
          //         //   child: Container(
          //         //     padding: EdgeInsets.symmetric(
          //         //       horizontal: TdResDimens.dp_4,
          //         //       vertical: TdResDimens.dp_1,
          //         //     ),
          //         //     margin: EdgeInsets.only(left: 8),
          //         //     decoration: BoxDecoration(
          //         //       color: themeColors?.primary,
          //         //       borderRadius: BorderRadius.circular(TdResDimens.dp_6),
          //         //     ),
          //         //     child: Text(
          //         //       entity.language,
          //         //       style: TdResTextStyles.caption.copyWith(
          //         //         color: Colors.white,
          //         //       ),
          //         //     ),
          //         //   ),
          //         // ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _widgetExpanded() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: TdResDimens.dp_16,
        vertical: TdResDimens.dp_4,
      ),
      child: Column(children: [_widgetmarkdown(entity.text)]),
    );
  }

  Widget _widgetActions() {
    var linkColor = Color.alphaBlend(
      themeColors?.onSurface.withAlpha(0x46) ?? Colors.black38,
      themeColors?.secondaryColor ?? Colors.red,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TdResGaps.h_12,

        if (entity.sourceUrl != null)
          SizedBox(
            height: 30,
            child: TextButton.icon(
              iconAlignment: IconAlignment.end,
              style: TextButton.styleFrom(
                // maximumSize: Size(200, 24),
                iconColor: linkColor,
                foregroundColor: linkColor,
                padding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_4),
                backgroundColor: themeColors?.secondaryColor.withAlpha(0x2),
              ),

              onPressed:
                  entity.sourceUrl != null
                      ? () {
                        onClickExternalUrl?.call(entity.sourceUrl!);
                      }
                      : null,
              icon: Icon(Icons.open_in_new, size: 18),
              label: Text(
                "Source",
                style: TdResTextStyles.buttonSmall.copyWith(
                  decoration: TextDecoration.underline,

                  decorationThickness: 2,
                  shadows: [
                    Shadow(
                      color: linkColor,
                      blurRadius: 0,
                      offset: Offset(0, -1),
                    ),
                  ],
                  color: Colors.transparent,

                  decorationColor: linkColor,
                ),
              ),
            ),
          ),
        Spacer(flex: 1),
        // Container(
        //   padding: EdgeInsets.symmetric(
        //     horizontal: TdResDimens.dp_4,
        //     vertical: TdResDimens.dp_2,
        //   ),
        //   decoration: BoxDecoration(
        //     color: themeColors?.primary,
        //     borderRadius: BorderRadius.circular(TdResDimens.dp_6),
        //   ),
        //   child: Text(
        //     entity.language,
        //     style: TdResTextStyles.caption.copyWith(color: Colors.white),
        //   ),
        // ),
        IconButton(
          onPressed: () {
            // mBloc.onClose();
            onClickCopy?.call(entity.text);
          },
          icon: Icon(
            Icons.copy,
            size: TdResDimens.dp_18,
            color: themeColors?.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _widgetmarkdown(String message) {
    final config =
        themeColors?.isDark == true
            ? MarkdownConfig.darkConfig
            : MarkdownConfig.defaultConfig;
    codeWrapper(child, text, language) =>
        MarkdownCodeWrapperWidget(child, text, language);
    return MarkdownWidget(
      data: message,
      shrinkWrap: true,
      selectable: false,

      config: config.copy(
        configs: [
          themeColors?.isDark == true
              ? PreConfig.darkConfig.copy(wrapper: codeWrapper)
              : PreConfig().copy(wrapper: codeWrapper),
          // PreConfig(
          //   decoration: BoxDecoration(
          //     color: themeColors?.onSurface.withOpacity(0.04),
          //     borderRadius: BorderRadius.circular(
          //       TdResDimens.dp_16,
          //     ),
          //   ),
          //   theme: a11yLightTheme
          // ),
        ],
      ),
    );
  }

  /* *********************************************************************************
 *                                      theme
 */
}
