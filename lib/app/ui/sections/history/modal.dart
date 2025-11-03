import 'package:dharak_flutter/app/ui/sections/history/args.dart';
import 'package:dharak_flutter/app/ui/sections/history/controller.dart';
import 'package:dharak_flutter/app/ui/sections/history/cubit_states.dart';
import 'package:dharak_flutter/app/ui/shared/common/scrollbar/fix/index.dart';

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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:logger/logger.dart';

class SearchHistoryModal extends StatefulWidget {
  final SearchHistoryArgsRequest mRequestArgs;
  const SearchHistoryModal({super.key, required this.mRequestArgs});
  @override
  SearchHistoryModalState createState() => SearchHistoryModalState();
}

class SearchHistoryModalState extends State<SearchHistoryModal> {
  SearchHistoryController mBloc = Modular.get<SearchHistoryController>();

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
        print("SearchHistoryModal PopScope back press");

        return false;
      }(),
      // onPopInvoked: (didPop) => {
      //       print("AuthPageState back press 2")
      //       // if (state == AuthUiConstants.STATE_DEFAULT) {
      //       //   // Navigator.pop(context);
      //       //   // mBloc.close();
      //       //   // return Future.value(true);
      //       // }
      //       //  mBloc.cancel();
      //     },
      child: MultiBlocListener(
        listeners: [
          BlocListener<SearchHistoryController, SearchHistoryCubitState>(
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
                  widget.mRequestArgs.isForVerse
                      ? themeColors.primary.withAlpha(0x62)
                      : themeColors.secondaryColor.withAlpha(0x80),
                  themeColors.surface,
                ),
                themeColors.onSurface,
              ).copyWith(
                borderRadius:
                    appThemeDisplay.breakpointType == BreakpointType.sm
                        ? null
                        : const BorderRadius.all(Radius.circular(24)),
              ),
              padding: appThemeDisplay.breakpointType == BreakpointType.sm ? null : const EdgeInsets.symmetric(vertical: TdResDimens.dp_12, horizontal: TdResDimens.dp_12),
              // child: Column(
              //   children: [
              //     SizedBox(
              //       // height: 32,
              //       width: TdResDimens.dp_32,
              //     )
              //   ],
              // ),
              child:
                  BlocBuilder<SearchHistoryController, SearchHistoryCubitState>(
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
                                : IntrinsicHeight(
                                  child: _widgetContents(context),
                                ),
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
        // TdResGaps.v_8,

        //  .._widgetHeading(context) : SizedBox.shrink(),
      ],
    );
  }

  Widget _widgetVerseList() {
    return BlocBuilder<SearchHistoryController, SearchHistoryCubitState>(
      bloc: mBloc,
      buildWhen:
          (previous, current) =>
              current.searchHistoryList != previous.searchHistoryList,
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_20),
          constraints: const BoxConstraints(minHeight: TdResDimens.dp_220),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...(state.searchHistoryList
                      ?.map((e) => _widgetSearchItem(e))
                      .toList() ??
                  []),
              if (!appThemeDisplay.isSamllHeight)
                const SizedBox(
                  width: TdResDimens.dp_16,
                  height: TdResDimens.dp_16,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _widgetSearchItem(String historyItem) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          mBloc.onItemSelected(historyItem);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical: TdResDimens.dp_8,
            horizontal: TdResDimens.dp_0,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: TdResDimens.dp_12,
            vertical: TdResDimens.dp_12,
          ),
          decoration: TdResDecorations.decorationCardOutlined(
            Color.alphaBlend(
              themeColors.secondaryColor.withAlpha(0x12),
              themeColors.surface,
            ),
            themeColors.surface.withAlpha(0x2d),
            isElevated: false,
          ).copyWith(borderRadius: BorderRadius.circular(TdResDimens.dp_12)),
          // color: Colors.red,
          child: Row(
            spacing: TdResDimens.dp_4,
            children: [
              Icon(
                Icons.search_rounded,
                size: TdResDimens.dp_18,
                color: themeColors.onSurface,
              ),
              Text(
                historyItem,
                style: TdResTextStyles.caption.copyWith(
                  color: themeColors.onSurfaceHigh,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _widgetAppbar(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: TdResDimens.dp_12,
        children: [
          Icon(Icons.history, color: themeColors.onSurface),
          Text(
            "Recent Searches",
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TdResTextStyles.h5Medium,
          ),
        ],
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
          icon: Icon(Icons.clear, color: themeColors.onSurface),
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
