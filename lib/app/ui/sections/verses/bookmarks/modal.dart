import 'package:dharak_flutter/app/types/verse/bookmarks/verse_bookmark.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/ui/sections/verses/bookmarks/args.dart';
import 'package:dharak_flutter/app/ui/sections/verses/bookmarks/controller.dart';
import 'package:dharak_flutter/app/ui/sections/verses/bookmarks/cubit_states.dart';
import 'package:dharak_flutter/app/ui/shared/common/scrollbar/fix/index.dart';
import 'package:dharak_flutter/app/ui/widgets/code_wrapper.dart';
import 'package:dharak_flutter/app/ui/pages/verses/parts/item.dart';

import 'package:dharak_flutter/res/layouts/breakpoints.dart';
import 'package:dharak_flutter/res/layouts/containers.dart';
import 'package:dharak_flutter/res/styles/decorations.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/blocks/leaf/code_block.dart';
import 'package:markdown_widget/widget/markdown.dart';

class VerseBookmarksModal extends StatefulWidget {
  final VerseBookmarksArgsRequest mRequestArgs;
  const VerseBookmarksModal({super.key, required this.mRequestArgs});
  @override
  VerseBookmarksModalState createState() => VerseBookmarksModalState();
}

class VerseBookmarksModalState extends State<VerseBookmarksModal> {
  VerseBookmarksController mBloc = Modular.get<VerseBookmarksController>();

  var mLogger = Logger();
  late AppThemeColors themeColors;
  late AppThemeDisplay appThemeDisplay;

  final GlobalKey<ScaffoldState> _mScaffoldKey = GlobalKey<ScaffoldState>();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      mBloc.initData(widget.mRequestArgs);
      //
      // TODO set argument request
      // mBloc.setAuthCase(widget.authCase);
      // mBloc.setModalState(AuthUiConstants.STATE_BOTTOM_SHEET);
    });

    // _subscribeCubit();
  }

  @override
  Widget build(BuildContext context) {
    prepareTheme(context);
    return PopScope(
      canPop: () {

        return false;
      }(),
      // onPopInvoked: (didPop) => {
      //       // if (state == AuthUiConstants.STATE_DEFAULT) {
      //       //   // Navigator.pop(context);
      //       //   // mBloc.close();
      //       //   // return Future.value(true);
      //       // }
      //       //  mBloc.cancel();
      //     },
      child: MultiBlocListener(
        listeners: [
          BlocListener<VerseBookmarksController, VerseBookmarksCubitState>(
            bloc: mBloc,
            listenWhen:
                (previous, current) => previous.result != current.result,
            listener: (context, state) {
              if (state.result != null) {
                Navigator.of(context).pop(state.result);
              }
            },
          ),
        ],
        child: Scaffold(
          key: _mScaffoldKey,
          backgroundColor: Colors.transparent,
          body: CommonDialogContainer(
            appThemeDisplay: appThemeDisplay,
            child: Container(
              decoration: TdResDecorations.decorationDialogBackground(
                Color.alphaBlend(
                  themeColors?.primary.withAlpha(0x42) ?? Colors.red,
                  themeColors?.surface ?? Colors.black12,
                ),
                themeColors.onSurface,
              ).copyWith(
                borderRadius:
                    appThemeDisplay.breakpointType == BreakpointType.sm
                        ? null
                        : const BorderRadius.all(Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: TdResDimens.dp_20,
                vertical: TdResDimens.dp_12,
              ),
              // child: Column(
              //   children: [
              //     SizedBox(
              //       // height: 32,
              //       width: TdResDimens.dp_32,
              //     )
              //   ],
              // ),
              child: BlocBuilder<
                VerseBookmarksController,
                VerseBookmarksCubitState
              >(
                bloc: mBloc,
                buildWhen:
                    (previous, current) =>
                        current.isInProgress != previous.isInProgress,
                builder: (context, state) {
                  return IgnorePointer(
                    ignoring: state.isInProgress ?? false,
                    child:
                        appThemeDisplay.breakpointType == BreakpointType.sm
                            ? _widgetContents(context)
                            : IntrinsicHeight(child: _widgetContents(context)),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /* **********************************************************************88* 
   *                          widgets
   */

  _widgetContents(BuildContext context) {
    return Flex(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      direction: Axis.vertical,
      // mainAxisAlignment: appThemeDisplay?.breakpointType != BreakpointType.sm ? MainAxisAlignment.center : ,
      mainAxisSize:
          appThemeDisplay.breakpointType != BreakpointType.sm
              ? MainAxisSize.min
              : MainAxisSize.max,
      // mainAxisSize: MainAxisSize.min,
      // crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Container(
        //   constraints: Com,
        //   decoration: const BoxDecoration(
        //     image: DecorationImage(
        //       image: AssetImage('packages/common/assets/img/pic_onboard.png'),
        //       fit: BoxFit.fitWidth,
        //     ),
        //   ),
        // ),
        _widgetAppbar(context),
        TdResGaps.line,

        Flexible(
          flex: 1,
          fit: FlexFit.tight,
          child: Container(
            constraints: const BoxConstraints(minHeight: TdResDimens.dp_220),
            child: ScrollbarFix(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: _widgetVerseList(),
              ),
            ),
          ),
        ),

        // _widgetVerseList(),
        // if (appThemeDisplay.breakpointType == BreakpointType.sm)
        //   ..._widgetHeading(context),

        // if (appThemeDisplay?.breakpointType != BreakpointType.sm)
        //   ..._widgetHeading(context),
        TdResGaps.v_8,

        //  .._widgetHeading(context) : SizedBox.shrink(),
        if (!appThemeDisplay.isSamllHeight)
          const SizedBox(width: TdResDimens.dp_16, height: TdResDimens.dp_16),
      ],
    );
  }

  Widget _widgetVerseList() {
    return BlocBuilder<VerseBookmarksController, VerseBookmarksCubitState>(
      bloc: mBloc,
      buildWhen:
          (previous, current) =>
              current.verseBookmarks != previous.verseBookmarks ||
              current.removedVersesIds != previous.removedVersesIds,
      builder: (context, state) {
        
        if (state.verseBookmarks == null || state.verseBookmarks!.isEmpty) {
          return Container(
            constraints: const BoxConstraints(minHeight: 220),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 48,
                    color: themeColors.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bookmarked verses yet',
                    style: TdResTextStyles.h4.copyWith(
                      color: themeColors.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your bookmarked verses will appear here',
                    style: TdResTextStyles.p2.copyWith(
                      color: themeColors.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Container(
          constraints: const BoxConstraints(minHeight: 220),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: state.verseBookmarks!
                .where((verseBookmark) => !state.removedVersesIds.contains(verseBookmark.pk))
                .map((verseBookmark) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                  child: VerseItemWidget(
                    appThemeDisplay: appThemeDisplay,
                    themeColors: themeColors,
                    entity: _convertVerseBookmarkToVerse(verseBookmark),
                    onAddToBookmark: (entity, isToAdd) => {
                      mBloc.onBookmarkToggle(verseBookmark, !isToAdd),
                    },
                    onClickCopy: (message) => _handleCopy(message),
                    onClickExternalUrl: (urlLink) => _launchExternalUrl(urlLink),
                    onPreviousVerse: null, // No navigation in bookmarks modal
                    onNextVerse: null, // No navigation in bookmarks modal
                  ),
                ))
                .toList(),
          ),
        );
      },
    );
  }

  // Convert VerseBookmarkRM to VerseRM for use with VerseItemWidget
  VerseRM _convertVerseBookmarkToVerse(VerseBookmarkRM verseBookmark) {
    return VerseRM(
      versePk: verseBookmark.pk,
      verseText: verseBookmark.text,
      verseRef: verseBookmark.key,
      sourceTitle: verseBookmark.source,
      isStarred: true, // All bookmarks are starred by definition
      // Set default/null values for fields not available in VerseBookmarkRM
      verseLetText: null,
      verseLetOtherScripts: null,
      verseLetPart: null,
      verseOtherScripts: null,
      otherFields: null,
      sourceName: null,
      sourceUrl: null,
      wordHyplinks: null,
    );
  }

  // Helper methods for the VerseItemWidget callbacks
  void _handleCopy(String message) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Text copied to clipboard!'),
        backgroundColor: themeColors.primary,
      ),
    );
  }

  void _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch URL: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching URL: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  PreferredSizeWidget _widgetAppbar(BuildContext context) {

    // inspect(_mCollection);

    // var primaryColor = Theme.of(context).colorScheme

    return AppBar(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      title: Text(
        "Bookmark Verses",
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TdResTextStyles.h5Medium,
      ),
      // title: Text(
      //   widget.title,
      //   textAlign: TextAlign.center,
      //   overflow: TextOverflow.ellipsis,
      //   style: TdResTextStyles.h5,
      // ),
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          onPressed: () {
            mBloc.onClose();
          },
          icon: Icon(Icons.close_rounded, color: themeColors.onSurface),
        ),
        // IconButton(
        //   icon: Icon(
        //     Icons.more_vert,
        //     color: Colors.grey.shade900,
        //   ),
        //   onPressed: () => debugPrint("more vert"),
        // )
      ],
    );
  }

  /* *********************************************************************************
 *                                      theme
 */

  prepareTheme(BuildContext context) {
    themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(
          seedColor: const Color(0xFF6CE18D),
          isDark: false,
        );
    appThemeDisplay = TdThemeHelper.prepareThemeDisplay(context);
    // mLogger.d("prepareTheme: $themeColors.surface");
  }
}
