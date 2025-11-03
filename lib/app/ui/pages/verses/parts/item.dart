import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/types/verse/verse_other_field.dart';
import 'package:dharak_flutter/app/ui/widgets/code_wrapper.dart';
import 'package:dharak_flutter/res/layouts/containers.dart';
import 'package:dharak_flutter/res/styles/decorations.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:markdown_widget/widget/blocks/leaf/code_block.dart';
import 'package:markdown_widget/widget/markdown.dart';

class VerseItemWidget extends StatefulWidget {
  // final String title;

  final AppThemeColors? themeColors;
  final AppThemeDisplay? appThemeDisplay;

  final VerseRM entity;

  final Function(VerseRM entity, bool isToAdd)? onAddToBookmark;

  final Function(String message)? onClickCopy;
  final Function(String urlLink)? onClickExternalUrl;
  
  // New callbacks for Previous/Next verse navigation
  final Function(String versePk)? onPreviousVerse;
  final Function(String versePk)? onNextVerse;
  
  // final Function(String id)? onClick;
  // List<String>  ds = ["Wew", "wer"];
  const VerseItemWidget({
    super.key,
    // this.title = 'StoreSettingPresenseSection',
    this.themeColors,
    this.appThemeDisplay,
    this.onAddToBookmark,
    this.onClickCopy,
    this.onClickExternalUrl,
    this.onPreviousVerse,
    this.onNextVerse,
    // this.onClick,
    // this.isSubmitValid,
    required this.entity,
    // this.customizationGroups = const [],
    // this.customizations = const []
  });

  @override
  VerseItemState createState() => VerseItemState();
}

class VerseItemState extends State<VerseItemWidget> {
  ExpansionTileController mOtherTextsExpansionTileController =
      ExpansionTileController();

  bool _mIsFitlerOpen = false;
  List<bool> _mOtherFieldsExpandedStates = List<bool>.empty(growable: true);

  ExpandableController? _expansionController = ExpandableController(
    initialExpanded: false,
  );

  // var _mIsExpanded = false;

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

  @override
  void didUpdateWidget(covariant VerseItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entity != widget.entity) {
      // Re-fetch the image URL when the id changes
      // setState(() {
      //   isLoading = true;
      //   hasError = false;
      // });
      var list = List<bool>.filled(widget.entity.otherFields?.length ?? 0, false);

      setState(() {
        _mOtherFieldsExpandedStates = list;
      });

      // print("didUpdateWidget :${widget.entity.verseRef}");
      // mBloc.formBind(widget.mRequestArgs.product);
    } else {
      // print("didUpdateWidget 2 :${widget.entity.verseRef}");
    }
  }

  expansionListener() {
    setState(() {
      // Trigger rebuild when expansion state changes so buttons show/hide properly
    });
  }

  @override
  void initState() {
    super.initState();
    var list = List<bool>.filled(widget.entity.otherFields?.length ?? 0, false);

    _mOtherFieldsExpandedStates = list;
    _expansionController?.addListener(expansionListener);
  }

  @override
  void dispose() {
    _expansionController?.removeListener(expansionListener);
    super.dispose();
  }

  _onOtherFieldsExpansionToggle() {
    bool isToOpen = !_mIsFitlerOpen;

    setState(() {
      _mIsFitlerOpen = isToOpen;
    });

    if (isToOpen) {
      mOtherTextsExpansionTileController.expand();
    } else {
      mOtherTextsExpansionTileController.collapse();
    }
  }

  _onOtherFieldsItemExpansionState(int index, bool isOpened) {
    if (_mOtherFieldsExpandedStates.length <= index) {
      return false;
    }

    setState(() {
      _mOtherFieldsExpandedStates[index] = isOpened;
    });

    // if (isToOpen) {
    //   mOtherTextsExpansionTileController.expand();
    // } else {
    //   mOtherTextsExpansionTileController.collapse();
    // }
  }

  _onOtherFieldsItemExpansionToggle(int index) {
    print("_mOtherFieldsExpandedStates: ${index}");
    if (_mOtherFieldsExpandedStates.length <= index) {
      return false;
    }

    bool isToOpen = !_mOtherFieldsExpandedStates[index];
    print("_mOtherFieldsExpandedStates 2: ${index} ${isToOpen}");

    _onOtherFieldsItemExpansionState(index, isToOpen);
  }

  /* ************************************************************************************
   *                                        Widget
   */

  Widget _widgetContents() {
    // Container(
    //   // decoration: BoxDecoration(
    //   //     borderRadius: BorderRadius.circular(TdResDimens.dp_24),
    //   //     color: widget.themeColors?.primary),
    //   // padding: const EdgeInsets.symmetric(
    //   //     horizontal: TdResDimens.dp_12, vertical: TdResDimens.dp_12),
    //   child:
    return CommonContainer(
      appThemeDisplay: widget.appThemeDisplay,

      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: TdResDimens.dp_12),

        decoration: TdResDecorations.decorationCardOutlined(
          Color.alphaBlend(
            widget.themeColors?.primary.withAlpha(0x12) ?? Colors.green,
            widget.themeColors?.onSurfaceLowest ?? Colors.black12,
          ),
          widget.themeColors?.surface.withAlpha(0x96) ?? Colors.white70,
          //  Color.alphaBlend(
          //    widget.themeColors?.secondaryColor.withAlpha(0x22) ?? Colors.red,
          //   widget. widget.themeColors?.surface?? Colors.black12,

          // ) ,
          isElevated: false,
        ).copyWith(
          borderRadius: BorderRadius.circular(TdResDimens.dp_12),
          border: Border.all(
            color: widget.themeColors?.onSurfaceDisable ?? Colors.black12,
            // left: BorderSide(
            //   width: 4,
            //   color: UtilColor.darken(
            //     widget.themeColors?.primary ?? Colors.green,
            //     0.3,
            //   ),
            // ),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        // decoration: BoxDecoration(
        //   borderRadius: BorderRadius.circular(TdResDimens.dp_24),
        //   color: widget.themeColors?.primary,
        // ),
        // padding: const EdgeInsets.symmetric(
        //     horizontal: TdResDimens.dp_12, vertical: TdResDimens.dp_12),
        child: Column(
          children: [
            ExpandableNotifier(
              child: ExpandablePanel(
                // tapHeaderToExpand: true,
                // key: Key(UtilString.getCustomUniqueId()),
                controller: _expansionController,
                collapsed: InkWell(
                  onTap: () {
                    _expansionController?.toggle();
                  },
                  child: Container(
                    width: double.maxFinite,
                    // alignment: Alignment.centerLeft,
                    // padding: EdgeInsets.symmetric(vertical: TdResDimens.dp_12),
                    padding: EdgeInsets.symmetric(
                      horizontal: TdResDimens.dp_16,
                      // vertical: TdResDimens.dp_8,
                    ).copyWith(top: TdResDimens.dp_16),
                    child: Text(
                      "..${(widget.entity.verseLetText ?? widget.entity.verseText ?? 'No text').substring(0, (widget.entity.verseLetText ?? widget.entity.verseText ?? 'No text').length > 30 ? 30 : (widget.entity.verseLetText ?? widget.entity.verseText ?? 'No text').length)}..",
                      overflow: TextOverflow.ellipsis,

                      maxLines: 1,
                      style: TdResTextStyles.p2,
                    ),
                    // decoration: BoxDecoration(
                    //     border: Border(
                    //         bottom: BorderSide(
                    //             color:
                    //                 widget.themeColors?.onSurfaceDisable ?? Colors.black12))),
                  ),
                ),

                theme: ExpandableThemeData(
                  inkWellBorderRadius: BorderRadius.circular(TdResDimens.dp_18),
                  iconPadding: EdgeInsets.only(right: TdResDimens.dp_12),
                  headerAlignment: ExpandablePanelHeaderAlignment.center,
                  iconColor: widget.themeColors?.onSurfaceHigh,

                  tapBodyToCollapse: true,
                  tapBodyToExpand: true,
                  tapHeaderToExpand: true,

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

                expanded: _widgetMainExpanded(),
              ),
            ),
            _widgetColumnBottom(),
          ],
        ),
      ),
    );

    // return SizedBox.shrink();
  }

  Widget _widgetHeading() {
    return Container(
      padding: EdgeInsets.only(
        left: TdResDimens.dp_16,
        right: TdResDimens.dp_16,
        top: TdResDimens.dp_8,
      ),
      child: Row(
        spacing: TdResDimens.dp_8,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon(
          //   Icons.description,
          //   color: UtilColor.darken(
          //     widget.themeColors?.secondaryLight ?? Colors.green,
          //     0.2,
          //   ),
          // ),
          // Flexible(
          //   flex: 1,
          //   child: Container(
          //     padding: EdgeInsets.symmetric(
          //       horizontal: TdResDimens.dp_8,
          //       vertical: TdResDimens.dp_2,
          //     ),
          //     decoration: BoxDecoration(
          //       color:
          //           widget.themeColors?.secondaryColor.withAlpha(0x23) ??
          //           Colors.red,

          //       borderRadius: BorderRadius.circular(TdResDimens.dp_6),
          //     ),
          //     child: Text(
          //       widget.entity.verseRef,
          //       style: TdResTextStyles.p3.copyWith(
          //         color: Color.alphaBlend(
          //           widget.themeColors?.onSurface.withAlpha(0x96) ??
          //               Colors.black38,
          //           widget.themeColors?.secondaryColor ?? Colors.red,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          Flexible(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: TdResDimens.dp_8,
                vertical: TdResDimens.dp_2,
              ),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  widget.themeColors?.onSurface.withAlpha(0x56) ??
                      Colors.black38,
                  widget.themeColors?.primaryLight ?? Colors.red,
                ).withAlpha(0x12),

                // color: Color.alphaBlend(
                //   widget.themeColors?.onSurface.withAlpha(0x02) ??
                //       Colors.black38,
                //   widget.themeColors?.secondaryLight ?? Colors.red,
                // ),
                borderRadius: BorderRadius.circular(TdResDimens.dp_6),
              ),
              //  ${widget.entity.verseRef} ${widget.entity.verseRef}
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${widget.entity.verseRef}",
                      style: TdResTextStyles.p3.copyWith(
                        color: Color.alphaBlend(
                          widget.themeColors?.onSurface.withAlpha(0x76) ??
                              Colors.black38,
                          widget.themeColors?.primaryHigh ?? Colors.red,
                        ),
                        // height: 1.2,
                        // background:
                        //     Paint()
                        //       ..color = Colors.blue
                        //       ..strokeWidth = 20
                        //       // ..style = PaintingStyle.fill
                        //       ..style = PaintingStyle.stroke
                        //       ..strokeJoin = StrokeJoin.round,
                      ),
                    ),

                    //#ecfd8a
                    // if (widget.entity.similarity != null)
                    //   WidgetSpan(
                    //     alignment: PlaceholderAlignment.middle,
                    //     child: _widgetSimilarity(),
                    //   ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.entity.similarity != null) _widgetSimilarity(),
        ],
      ),
    );
  }

  Widget _widgetSimilarity() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: TdResDimens.dp_4,
        vertical: TdResDimens.dp_1,
      ),
      margin: EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: widget.themeColors?.primary,
        borderRadius: BorderRadius.circular(TdResDimens.dp_6),

        boxShadow: [
          BoxShadow(
            color:
                widget.themeColors?.secondaryColor.withAlpha(0x12) ??
                Colors.red,
            spreadRadius: 0,
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        widget.entity.similarity ?? "",
        style: TdResTextStyles.caption.copyWith(
          color: Colors.white,

          // Color.alphaBlend(
          //   widget.themeColors?.onSurface.withAlpha(0x66) ?? Colors.black38,
          //   widget.themeColors?.primary ?? Colors.red,
          // ),
        ),
      ),
    );
  }

  Widget _widgetMainExpanded() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: TdResDimens.dp_4,
      ).copyWith(top: TdResDimens.dp_12),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              _expansionController?.toggle();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_16),
              child: _widgetmarkdown(widget.entity.verseText ?? 'No verse text available'),
            ),
          ),

          // if (widget.entity.otherFields.isNotEmpty)
          //   _widgetOtherExpansionTile(
          //     header: Container(
          //       // color: Colors.amber,
          //       padding: EdgeInsets.only(left: TdResDimens.dp_12),
          //       child: _widgetMainActions(),
          //     ),
          //   )
          // else
          //   Container(
          //     padding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_12),
          //     child: _widgetMainActions(),
          //   ),
        ],
      ),
    );
  }

  Widget _widgetColumnBottom() {
    if (widget.entity.otherFields?.isNotEmpty ?? false) {
      return _widgetOtherExpansionTile(
        header: Container(
          // color: Colors.amber,
          padding: EdgeInsets.only(left: TdResDimens.dp_12),
          child: _widgetMainActions(),
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: TdResDimens.dp_12,
          vertical: TdResDimens.dp_10,
        ),
        child: _widgetMainActions(),
      );
    }
  }

  Widget _widgetMainActions() {
    var linkColor = Color.alphaBlend(
      widget.themeColors?.onSurface.withAlpha(0x46) ?? Colors.black38,
      widget.themeColors?.primaryHigh ?? Colors.red,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.entity.sourceUrl != null)
          SizedBox(
            height: 30,
            child: TextButton(
              style: TextButton.styleFrom(
                // maximumSize: Size(200, 24),
                iconColor: linkColor,
                foregroundColor: linkColor,
                padding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_4),
                backgroundColor: widget.themeColors?.secondaryColor.withAlpha(
                  0x2,
                ),
              ),
              onPressed:
                  widget.entity.sourceUrl != null
                      ? () {
                        widget.onClickExternalUrl?.call(
                          widget.entity.sourceUrl!,
                        );
                      }
                      : null,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                direction: Axis.horizontal,
                spacing: TdResDimens.dp_4,
                children: [
                  Text(
                    "Source:",
                    style: TdResTextStyles.caption.copyWith(color: linkColor),
                  ),
                  Text(
                    widget.entity.sourceName ?? 'Unknown Source',
                    style: TdResTextStyles.caption.copyWith(
                      // color: widget.themeColors?.onSurfaceHigh,
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
                ],
              ),
            ),
          ),

        Wrap(
          spacing: 8,
          direction: Axis.horizontal,
          children: [
            // Previous/Next buttons - only show when card is expanded
            if (_expansionController?.expanded == true) ...[
              // Previous verse button
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: widget.onPreviousVerse != null 
                      ? () {
                          widget.onPreviousVerse?.call(widget.entity.versePk.toString());
                        }
                      : null,
                  customBorder: CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.chevron_left,
                      size: TdResDimens.dp_18,
                      color: widget.themeColors?.onSurface,
                    ),
                  ),
                ),
              ),
              
              // Next verse button  
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: widget.onNextVerse != null
                      ? () {
                          widget.onNextVerse?.call(widget.entity.versePk.toString());
                        }
                      : null,
                  customBorder: CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.chevron_right,
                      size: TdResDimens.dp_18,
                      color: widget.themeColors?.onSurface,
                    ),
                  ),
                ),
              ),
            ],
            
            // Existing bookmark button
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () {
                  widget.onAddToBookmark?.call(
                    widget.entity,
                    !(widget.entity.isStarred ?? false),
                  );
                },
                customBorder: CircleBorder(),
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    (widget.entity.isStarred ?? false)
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_outlined,
                    size: TdResDimens.dp_18,
                    color: widget.themeColors?.onSurface,
                  ),
                ),
              ),
            ),

            // Existing copy button
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () {
                  widget.onClickCopy?.call(widget.entity.verseText ?? 'No verse text available');
                },
                customBorder: CircleBorder(),
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.copy,
                    size: TdResDimens.dp_18,
                    color: widget.themeColors?.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _widgetOtherExpansionTile({Widget? header}) {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: Colors.white, // here for close state
        // here for open state in replacement of deprecated accentColor
        dividerColor: Colors.transparent, // if you want to remove the border
      ),
      child: ExpansionTile(
        // backgroundColor: state.isFitlerOpen == true
        //     ? themeColors.primary
        //     : Colors.transparent,
        // backgroundColor:
        //     _mIsFitlerOpen
        //         ? widget.themeColors?.primary.withAlpha(0x64)
        //         : widget.themeColors?.surface,

        // backgroundColor: widget.themeColors?.,
        controller: mOtherTextsExpansionTileController,
        collapsedBackgroundColor: Colors.transparent,
        childrenPadding: EdgeInsets.all(0),

        // clipBehavior: Clip.antiAlias,
        // shape: RoundedRectangleBorder(
        //   borderRadius: BorderRadius.circular(TdResDimens.dp_12),
        // ),
        tilePadding: EdgeInsets.all(0),

        // shape: Bor,
        trailing: Padding(
          padding: EdgeInsets.only(right: TdResDimens.dp_12),
          child: InkWell(
            child: const Icon(Icons.info),
            // tooltip: 'more details',
            onTap: () {
              _onOtherFieldsExpansionToggle();
              // mBloc.onFilterToggle(!(state.isFitlerOpen ?? false));
            },
          ),
        ),

        // IconButton(
        // style: IconButton.styleFrom(
        //   maximumSize: Size.fromWidth(24)
        // ),
        //   icon: const Icon(Icons.info),
        //   tooltip: 'more details',
        //   onPressed: () {
        //     _onOtherFieldsExpansionToggle();
        //     // mBloc.onFilterToggle(!(state.isFitlerOpen ?? false));
        //   },
        // ),
        title: header ?? Text("Other"),
        children: [
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: TdResDimens.dp_8,
            ).copyWith(bottom: TdResDimens.dp_8),
            decoration: BoxDecoration(
              color: widget.themeColors?.primary.withAlpha(0x64),
              borderRadius: BorderRadius.circular(TdResDimens.dp_12),
            ),
            clipBehavior: Clip.antiAlias,
            width: double.maxFinite,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: TdResDimens.dp_12,
                    vertical: TdResDimens.dp_12,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "More Info",
                    style: TdResTextStyles.h6Medium,
                    textAlign: TextAlign.left,
                  ),
                ),
                Divider(color: Colors.black26, height: 1),
                ...(widget.entity.otherFields ?? [])
                    .asMap()
                    .map((i, e) => MapEntry(i, _widgetOtherFieldItem(i, e)))
                    .values,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _widgetOtherFieldItem(int index, VerseOtherFieldRM e) {
    var isExpanded =
        _mOtherFieldsExpandedStates.length > index
            ? _mOtherFieldsExpandedStates[index]
            : false;
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: Colors.white, // here for close state
        // here for open state in replacement of deprecated accentColor
        dividerColor: Colors.transparent, // if you want to remove the border
      ),
      child: ExpansionTile(
        key: Key('tile_${index}_${isExpanded}'),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        initiallyExpanded: isExpanded,

        childrenPadding: EdgeInsets.symmetric(
          horizontal: TdResDimens.dp_12,
          vertical: TdResDimens.dp_8,
        ),
        iconColor: Colors.black87,
        minTileHeight: 44,
        collapsedIconColor: Colors.black54,
        tilePadding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_12),
        shape: Border(bottom: BorderSide(color: Colors.black12)),
        collapsedShape: Border(bottom: BorderSide(color: Colors.black12)),
        onExpansionChanged: (bool expanded) {
          _onOtherFieldsItemExpansionState(index, expanded);
        },

        // shape: Bor,
        // trailing: IconButton(
        //   icon: const Icon(Icons.info),
        //   tooltip: 'more details',
        //   onPressed: () {
        //     _onOtherFieldsExpansionToggle();
        //     // mBloc.onFilterToggle(!(state.isFitlerOpen ?? false));
        //   },
        // ),
        title: Container(
          padding: EdgeInsets.only(
            // left: TdResDimens.dp_16,
            right: TdResDimens.dp_16,
            // top: TdResDimens.dp_8,
          ),
          child: Text(
            e.title ?? 'Other Field',
            style: TdResTextStyles.h5Medium.copyWith(
              color: widget.themeColors?.onSurface.withAlpha(0x90),
            ),
          ),
        ),
        children: [
          InkWell(
            onTap: () {
              _onOtherFieldsItemExpansionToggle(index);
            },
            child: Container(
              decoration: TdResDecorations.decorationCardOutlined(
                Color.alphaBlend(
                  widget.themeColors?.primary.withAlpha(0x12) ?? Colors.green,
                  widget.themeColors?.onSurfaceLowest ?? Colors.black12,
                ),
                widget.themeColors?.surface.withAlpha(0xb0) ?? Colors.black12,
                isElevated: false,
              ).copyWith(
                borderRadius: BorderRadius.circular(TdResDimens.dp_6),
                border: Border(
                  left: BorderSide(
                    width: 4,
                    color: Color.alphaBlend(
                      widget.themeColors?.onSurface.withAlpha(0x36) ??
                          Colors.black38,
                      widget.themeColors?.primary ?? Colors.green,
                    ),
                  ),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_12),
              child: _widgetmarkdown(e.value ?? 'No content available'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _widgetOtherFieldItemBug(VerseOtherFieldRM e) {
    return ExpandablePanel(
      // key: {$e.},
      // key: Key(UtilString.getCustomUniqueId()),
      controller: null,
      collapsed: Container(
        // alignment: Alignment.centerLeft,
        // padding: EdgeInsets.symmetric(vertical: TdResDimens.dp_12),
        padding: EdgeInsets.symmetric(
          horizontal: TdResDimens.dp_16,
          vertical: TdResDimens.dp_8,
        ),
        child: SizedBox.shrink(),
        // decoration: BoxDecoration(
        //     border: Border(
        //         bottom: BorderSide(
        //             color:
        //                 widget.themeColors?.onSurfaceDisable ?? Colors.black12))),
      ),

      theme: ExpandableThemeData(
        inkWellBorderRadius: BorderRadius.circular(TdResDimens.dp_18),
        iconPadding: EdgeInsets.only(right: TdResDimens.dp_12),
        headerAlignment: ExpandablePanelHeaderAlignment.center,
      ),
      header: Container(
        padding: EdgeInsets.only(
          left: TdResDimens.dp_16,
          right: TdResDimens.dp_16,
          top: TdResDimens.dp_8,
        ),
        child: Text(
          e.title ?? 'Other Field',
          style: TdResTextStyles.h4Medium.copyWith(
            color: widget.themeColors?.onSurface.withAlpha(0x90),
          ),
        ),
      ),

      expanded: Container(
        decoration: TdResDecorations.decorationCardOutlined(
          Color.alphaBlend(
            widget.themeColors?.primary.withAlpha(0x12) ?? Colors.green,
            widget.themeColors?.onSurfaceLowest ?? Colors.black12,
          ),
          widget.themeColors?.surface.withAlpha(0xb0) ?? Colors.black12,
          isElevated: false,
        ).copyWith(
          borderRadius: BorderRadius.circular(TdResDimens.dp_12),
          border: Border(
            left: BorderSide(
              width: 4,
              color: Color.alphaBlend(
                widget.themeColors?.onSurface.withAlpha(0x66) ?? Colors.black38,
                widget.themeColors?.primary ?? Colors.green,
              ),
            ),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_12),
        child: _widgetmarkdown(e.value ?? 'No content available'),
      ),
    );
  }

  /* ********************************************************
   *                        other
   */

  Widget _widgetmarkdown(String message) {
    final config =
        widget.themeColors?.isDark == true
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
          widget.themeColors?.isDark == true
              ? PreConfig.darkConfig.copy(wrapper: codeWrapper)
              : PreConfig().copy(wrapper: codeWrapper),
          //  PConfig(
          //   textStyle: TdResTextStyles.p1

          // )
        ],
      ),
    );
  }

  /* *********************************************************************************
 *                                      theme
 */
}