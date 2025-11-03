import 'package:dharak_flutter/app/tools/route/route_change_notifier.dart';
import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/app/ui/pages/words/args.dart';
import 'package:dharak_flutter/app/ui/pages/words/controller.dart';
import 'package:dharak_flutter/app/ui/pages/words/cubit_states.dart';
import 'package:dharak_flutter/app/ui/pages/words/parts/item.dart';
import 'package:dharak_flutter/app/ui/pages/words/parts/similar_words.dart';
import 'package:dharak_flutter/app/ui/pages/words/parts/word_special_script.dart';
import 'package:dharak_flutter/app/ui/widgets/code_wrapper.dart';
import 'package:dharak_flutter/app/utils/util_string.dart';
import 'package:dharak_flutter/res/layouts/breakpoints.dart';
import 'package:dharak_flutter/res/layouts/containers.dart';
import 'package:dharak_flutter/res/styles/decorations.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:dharak_flutter/res/values/colors.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:logger/logger.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:markdown_widget/widget/blocks/leaf/code_block.dart';
import 'package:markdown_widget/widget/markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class WordDefinePage extends StatefulWidget {
  final WordDefineArgsRequest mRequestArgs;
  final String title;
  const WordDefinePage({
    super.key,
    required this.mRequestArgs,
    this.title = 'WordDefinePage',
  });
  @override
  WordDefinePageState createState() => WordDefinePageState();
}

class WordDefinePageState extends State<WordDefinePage> {
  late AppThemeColors themeColors;
  late AppThemeDisplay appThemeDisplay;

  FocusNode _focusNode = FocusNode();

  final ScrollController _scrollController = ScrollController();
  WordDefineController mBloc = Modular.get<WordDefineController>();

  final GlobalKey<SliverAnimatedListState> listKey =
      GlobalKey<SliverAnimatedListState>();
  @override
  void initState() {
    super.initState();
    // infoEdit.currentState.

    // mProgressDialog = ProgressDialog();

    // _scrollController.addListener(() => _scrollEventListen());

    // _setupListAdapter();
    // _subscribeBloc();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // _fcmService.tryLog();
      // if (kIsWeb) {
      //   checkforAuth();

      // if (widget.tabName != null) {
      // UiConstants.Tabs.topics
      Provider.of<RouteChangeNotifier>(
        context,
        listen: false,
      ).updateTab(UiConstants.Tabs.wordDefine);
      // }

      mBloc.initData(widget.mRequestArgs);
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    // double screenWidth = MediaQuery.of(context).size.width;
    // // double screenHeight = MediaQuery.of(context).size.height;
    // themeColors = Theme.of(context).extension<AppThemeColors>() ??
    //     AppThemeColors.seedColor(seedColor: Color(0xFF6CE18D), isDark: false);
    // appThemeDisplay = TdThemeHelper.prepareThemeDisplay(context);
    prepareTheme(context);

    // return  Column(
    //       children: <Widget>[

    //       ],
    //     );

    return MultiBlocListener(
      listeners: [
        BlocListener<WordDefineController, WordDefineCubitState>(
          bloc: mBloc,
          listenWhen:
              (previous, current) =>
                  (previous.isInitialized != current.isInitialized),
          listener: (context, state) {
            if (state.isInitialized == true) {
              // _mListModelAdapter?.removeAt(index)
              // _mListModelAdapter?.invalidate(mBloc.nextPagingSource());
            }
          },
        ),

        BlocListener<WordDefineController, WordDefineCubitState>(
          bloc: mBloc,
          listenWhen:
              (previous, current) =>
                  previous.toastCounter != current.toastCounter,
          listener: (context, state) {
            _showToast(state.message ?? "");
          },
        ),
        BlocListener<WordDefineController, WordDefineCubitState>(
          bloc: mBloc,

          listenWhen:
              (previous, current) =>
                  (previous.wordDefinitions != current.wordDefinitions),
          listener: (context, state) {
            if (state.wordDefinitions != null) {
              listKey.currentState?.removeAllItems((
                BuildContext context,
                Animation<double> animation,
              ) {
                return Container();
              });

              // for (var i = 0; i < state.wordDefinitions.length; i++) {
              listKey.currentState?.insertAllItems(
                0,
                state.wordDefinitions.length,
              );
              // }
            }
            if (state.isInitialized == true) {
              // _mListModelAdapter?.removeAt(index)
              // _mListModelAdapter?.invalidate(mBloc.nextPagingSource());
            }
          },
        ),
        // BlocListener<WordDefineController, WordDefineCubitState>(
        //     bloc: mBloc,
        //     listenWhen: (previous, current) =>
        //         (previous.eventRefresh != current.eventRefresh),
        //     listener: (context, state) {
        //       if (state.eventRefresh != null) {
        //         // _mListModelAdapter?.removeAt(index)
        //         _mListModelAdapter?.invalidate(mBloc.nextPagingSource());
        //       }
        //     }),
      ],
      child: _widgetContents(context),
    );
  }

  void copyToClipboard(String message) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Copied to clipboard!",
          style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
        ),
      ),
    );
  }

  void launchExternalUrl(String? urlLink) {
    if (urlLink != null) {
      var uriLinkUri = Uri.parse(urlLink!);
      launchUrl(uriLinkUri);
      // canLaunchUrl(uriLinkUri).then((onValue) async {
      //    print("canLaunchUrl: ${onValue} ${uriLinkUri}");
      //   if (onValue) {
      //     var urlLaunched = await launchUrl(uriLinkUri);
      //     print("canLaunchUrl: ${urlLaunched}");
      //   }
      // });
    }
  }

  /* ******************************************************************************
   *                                      Widgets
   */

  Widget _widgetContents(BuildContext context) {
    return Container(
      color: Color.alphaBlend(
        themeColors.secondaryColor.withAlpha(0x12),
        themeColors.surface,
      ),
      child: Stack(
        children: <Widget>[
          // ScrollbarFix(
          //   scrollController: _scrollController,
          //   child: SingleChildScrollView(
          //     controller: _scrollController,
          //     child: Column(
          //       // mainAxisSize: MainAxisSize.min,
          //       children: [Text("Word Defines")],
          //     ),
          //   ),
          // ),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _widgetTitle(),
              SliverAppBar(
                pinned: true,
                leadingWidth: 0,
                actionsPadding: EdgeInsets.all(0),
                floating: true,
                backgroundColor: Color.alphaBlend(
                  themeColors.secondaryColor.withAlpha(0x12),
                  themeColors.surface,
                ),
                surfaceTintColor: Color.alphaBlend(
                  themeColors.secondaryColor.withAlpha(0x12),
                  themeColors.surface,
                ),
                title: _widgetSearch(),
              ),
              _widgetWordOverview(),
              BlocBuilder<WordDefineController, WordDefineCubitState>(
                bloc: mBloc,
                buildWhen:
                    (previous, current) =>
                        current.isLoading != previous.isLoading ||
                        current.wordDefinitions != previous.wordDefinitions,
                builder: (context, state) {
                  if (state.isLoading==true || state.wordDefinitions.isEmpty) {
                    return SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: CommonContainer(
                      appThemeDisplay: appThemeDisplay,

                      child: Container(
                        margin: EdgeInsets.only(top: TdResDimens.dp_24),

                        height: TdResDimens.dp_48,
                        child: Row(
                          children: [
                            Flexible(
                              flex: 1,
                              fit: FlexFit.tight,
                              child: Text(
                                "Definitions",
                                textAlign: TextAlign.start,
                                style: TdResTextStyles.h4Medium.copyWith(
                                  color: themeColors.onSurface.withAlpha(0xb6),
                                ),
                              ),
                            ),

                            TextButton.icon(
                              onPressed: () {
                                copyToClipboard(mBloc.getAllText());
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: themeColors.secondaryLight
                                    .withAlpha(0x22),
                              ),
                              label: Text(
                                "Copy All",
                                textAlign: TextAlign.start,
                                style: TdResTextStyles.buttonSmall.copyWith(
                                  color: Color.alphaBlend(
                                    themeColors?.onSurface.withAlpha(0x96) ??
                                        Colors.black38,
                                    themeColors?.secondaryLight ?? Colors.red,
                                  ),
                                ),
                              ),
                              icon: Icon(
                                Icons.copy_all,
                                color: Color.alphaBlend(
                                  themeColors?.onSurface.withAlpha(0x96) ??
                                      Colors.black38,
                                  themeColors?.secondaryLight ?? Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              BlocBuilder<WordDefineController, WordDefineCubitState>(
                bloc: mBloc,
                buildWhen:
                    (previous, current) =>
                        current.isLoading != previous.isLoading ||
                        current.wordDefinitions != previous.wordDefinitions ||
                        current.searchCounter != previous.searchCounter ||
                        current.similarWords != previous.similarWords,
                builder: (context, state) {
                  if (state.isLoading == true) {
                    return SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: TdResDimens.dp_12,
                        ),
                        // color: themeColors.onSurface.withOpacity(0.02),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    );
                  } else if (state.wordDefinitions.isEmpty &&
                      state.searchCounter != 0 &&
                      state.similarWords.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 200,
                          minHeight: 100,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "No result found",
                          style: TdResTextStyles.h3.copyWith(
                            color: themeColors.onSurfaceDisable,
                          ),
                        ),
                      ),
                    );
                  } else if (state.wordDefinitions.isNotEmpty) {
                    return SliverToBoxAdapter(
                      child: const SizedBox(height: 12),
                    );
                  } else {
                    return SliverToBoxAdapter(child: const SizedBox.shrink());
                  }
                },
              ),
              BlocBuilder<WordDefineController, WordDefineCubitState>(
                bloc: mBloc,
                buildWhen:
                    (previous, current) =>
                       
                        current.isLoading != previous.isLoading || current.wordDefinitions != previous.wordDefinitions,
                builder: (context, state) {
                   if (state.isLoading == true) {
                    return SliverToBoxAdapter(
                      child: Container(
                        
                      ),
                    );
                  }
                  return SliverAnimatedList(
                    key: listKey,

                    itemBuilder: (context, index, animation) {
                      if (index < state.wordDefinitions.length) {
                        return WordDefinitionItemWidget(
                          appThemeDisplay: appThemeDisplay,
                          themeColors: themeColors,
                          entity: state.wordDefinitions[index]!,
                          onClickCopy: (message) => copyToClipboard(message),
                          onClickExternalUrl:
                              (urlLink) => launchExternalUrl(urlLink),
                        );
                      }
                      return SizedBox.shrink();
                      // SizedBox(height: 200);
                    },
                    initialItemCount: state.wordDefinitions.length,
                  );
                },
              ),

              _widgetSimilarWordsOverview(),
              SliverToBoxAdapter(child: SizedBox(height: 40)),

              // _widgetAnimatedlist(),
            ],
          ),
          // BlocBuilder<WordDefineController, WordDefineCubitState>(
          //   bloc: mBloc,
          //   buildWhen:
          //       (previous, current) => current.isLoading != previous.isLoading,
          //   builder: (context, state) {
          //     if (state.isLoading == true) {
          //       return Container(
          //         color: themeColors.onSurface.withOpacity(0.02),
          //         child: const Center(child: CircularProgressIndicator()),
          //       );
          //     } else {
          //       return const SizedBox.shrink();
          //     }
          //   },
          // ),
          // _widgetInputBox(),
        ],
      ),
    );
  }

  Widget _widgetSimilarWordsOverview() {
    return BlocBuilder<WordDefineController, WordDefineCubitState>(
      bloc: mBloc,
      buildWhen:
          (previous, current) =>
              current.dictWordDefinitions != previous.dictWordDefinitions,
      builder: (context, state) {
        if (state.similarWords.isEmpty) {
          return SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: WordSimilarWordsWidget(
            appThemeDisplay: appThemeDisplay,
            themeColors: themeColors,
            similarWords: state.similarWords,
            onSearchClick: (e) => mBloc.onSearchDirectQuery(e),
          ),
        );
      },
    );
  }

  Widget _widgetWordOverview() {
    return BlocBuilder<WordDefineController, WordDefineCubitState>(
      bloc: mBloc,
      buildWhen:
          (previous, current) =>
              current.dictWordDefinitions != previous.dictWordDefinitions ||
              current.isLoading != previous.isLoading,
      builder: (context, state) {
        if (state.isLoading == true ||
            state.dictWordDefinitions?.details == null ||
            (state.dictWordDefinitions?.details.word == null &&
                state.dictWordDefinitions?.details.llmDef == null)) {
          return SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: CommonContainer(
            appThemeDisplay: appThemeDisplay,

            child: Container(
              width: double.maxFinite,
              child: Column(
                spacing: TdResDimens.dp_18,
                // crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TdResGaps.empty,

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      state.dictWordDefinitions?.details.word ?? "",
                      textAlign: TextAlign.left,
                      style: TdResTextStyles.h4Medium.copyWith(
                        color: themeColors.onSurface,
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: WordSpecialScriptWidget(
                      appThemeDisplay: appThemeDisplay,
                      themeColors: themeColors,
                      otherScripts:
                          state.dictWordDefinitions?.details.otherScripts,
                    ),
                  ),

                  if (state.dictWordDefinitions?.details.llmDef != null)
                    Container(
                      decoration: TdResDecorations.decorationCardOutlined(
                        Color.alphaBlend(
                          themeColors.secondaryColor.withAlpha(0x12),
                          themeColors.onSurfaceLowest,
                        ),
                        themeColors.onSurface.withAlpha(0x06),
                        isElevated: false,
                      ).copyWith(
                        borderRadius: BorderRadius.circular(TdResDimens.dp_12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: TdResDimens.dp_16,
                        vertical: TdResDimens.dp_16,
                      ),
                      child: Column(
                        children: [
                          Row(
                            spacing: TdResDimens.dp_16,
                            children: [
                              Container(
                                height: TdResDimens.dp_36,
                                width: TdResDimens.dp_36,
                                decoration: BoxDecoration(
                                  // color: ,
                                  borderRadius: BorderRadius.circular(
                                    TdResDimens.dp_12,
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color.alphaBlend(
                                        themeColors.secondaryColor.withAlpha(
                                          0xa0,
                                        ),
                                        themeColors.surface,
                                      ),
                                      Color.alphaBlend(
                                        themeColors.secondaryColor.withAlpha(
                                          0x64,
                                        ),
                                        themeColors.surface,
                                      ),
                                    ],
                                  ),
                                ),
                                child: Icon(Icons.chat_bubble_outline),
                              ),
                              Text(
                                "LLM Summary",
                                textAlign: TextAlign.start,
                                style: TdResTextStyles.h4Medium.copyWith(
                                  color: themeColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          _widgetmarkdown(
                            state.dictWordDefinitions!.details.llmDef!,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  //  Widget _widgetmarkdown(String message) {

  //    return Text(message, style: TdResTextStyles.h5,);
  //  }

  Widget _widgetmarkdown(String message) {
    final config =
        themeColors.isDark
            ? MarkdownConfig.darkConfig
            : MarkdownConfig.defaultConfig;
    codeWrapper(child, text, language) =>
        MarkdownCodeWrapperWidget(child, text, language);
    return MarkdownWidget(
      data: message,
      shrinkWrap: true,
      selectable: true,
      config: config.copy(
        configs: [
          themeColors.isDark
              ? PreConfig.darkConfig.copy(wrapper: codeWrapper)
              : PreConfig().copy(wrapper: codeWrapper),
              //  PConfig(
              //   textStyle: TdResTextStyles.p1
              // )
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
    )
    
    ;
  }

  Widget _widgetTitle() {
    return BlocBuilder<WordDefineController, WordDefineCubitState>(
      bloc: mBloc,
      buildWhen:
          (previous, current) =>
              current.searchCounter != previous.searchCounter,
      builder: (context, state) {
        if (state.searchCounter != 0) {
          return SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: CommonContainer(
            appThemeDisplay: appThemeDisplay,

            child: Container(
              constraints: BoxConstraints(maxWidth: 700),
              child: Column(
                spacing:
                    appThemeDisplay.isSamllHeight
                        ? TdResDimens.dp_24
                        : TdResDimens.dp_64,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TdResGaps.empty,
                  Text(
                    "Welcome to WORDefine",
                    textAlign: TextAlign.center,
                    textScaler:TextScaler.linear(1.0), //fixed scaling to prevent distortion
                   
                    style: (appThemeDisplay.isSamllHeight
                            ? TdResTextStyles.h1Bold
                            : TdResTextStyles.h0Bold)
                        .copyWith(
                          color: Color.alphaBlend(
                            themeColors.onSurface.withAlpha(0x42),
                            themeColors.secondaryColor,
                          ),

                          //  UtilColor.darken(
                          //   themeColors.secondaryColor,
                          //   0.4,
                          // ),
                        ),
                  ),
                  Text(
                    "Explore names, words, places or concepts. Enter a single word & discover the world of Indic Knowledge with our smart AI word lookup.",
                    textAlign: TextAlign.center,
                    textScaler:TextScaler.linear(1.0), //fixed scaling to prevent distortion
                   
                    style: (appThemeDisplay.isSamllHeight
                            ? TdResTextStyles.h4Medium
                            : TdResTextStyles.h3Medium)
                        .copyWith(color: themeColors.onSurfaceHigh),
                  ),
                  TdResGaps.empty,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _widgetSearch() {
    return CommonContainer(
      appThemeDisplay: appThemeDisplay,
      defaultPadding: 2,

      child: Container(
        constraints: BoxConstraints(maxWidth: 700),
        // constraints: appThemeDisplay.breakpointType ==
        //         BreakpointType.sm
        //     ? const BoxConstraints(maxWidth: TdResDimens.dp_132)
        //     : appThemeDisplay.breakpointType == BreakpointType.md
        //         ? const BoxConstraints(maxWidth: TdResDimens.dp_132)
        //         : const BoxConstraints(maxWidth: TdResDimens.dp_220),
        padding: EdgeInsets.only(bottom: 1),
        decoration: TdResDecorations.inputSmallDecorationOuter(
          themeColors,
          radius: TdResDimens.dp_12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BlocBuilder<WordDefineController, WordDefineCubitState>(
              bloc: mBloc,
              buildWhen:
                  (previous, current) =>
                      current.formSearchText != previous.formSearchText,
              builder: (context, state) {
                return Flexible(
                  flex: 1,
                  child: TextFormField(
                    controller: mBloc.mSearchController,
                    textAlignVertical: TextAlignVertical.center,
                    style: TdResTextStyles.h5.merge(
                      TextStyle(
                        color: Color.alphaBlend(
                          TdResColors.colorInput.withOpacity(0.2),
                          themeColors.onSurface,
                        ),
                      ),
                    ),
                    focusNode: _focusNode,

                    // autofocus: true,
                    maxLines: 1,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    // inputFormatters: [DecimalTextInputFormatter(decimalRange: 0)],
                    keyboardType: TextInputType.text,
                    onChanged: (String value) {
                      // print("_widgetForm");
                      mBloc.onFormSearchTextChanged(value);
                    },
                    onSaved: (value) {
                      // print("onSaved: ${value}");
                      // _mFormTitle = value;
                    },
                    onFieldSubmitted: (term) {
                      // FocusScope.of(context).requestFocus(lname);
                    },

                    decoration: TdResDecorations.inputSmallDecorationInner(
                      themeColors,
                    ).copyWith(
                      hintText: "Type a word to search..",
                      // prefixIcon: Icon(
                      //   Icons.search,
                      //   color: themeColors.onSurface.withAlpha(0xa6),
                      // ),
                      suffixIcon:
                          UtilString.isStringsEmpty(state.formSearchText)
                              ? null
                              : IconButton(
                                padding: const EdgeInsets.symmetric(
                                  vertical: TdResDimens.dp_14,
                                ),
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  // mBloc.changePasswordVisibility();
                                  mBloc.onFormSearchTextChanged(null);
                                },
                                color: themeColors.onSurfaceMedium,
                                // size: 24.0,
                                // semanticLabel: 'Text to announce in accessibility modes',
                              ),
                    ),
                  ),
                );
              },
            ),

            // Container(
            //   padding: EdgeInsets.only(
            //     top: TdResDimens.dp_12,
            //     bottom: TdResDimens.dp_12,
            //     right: TdResDimens.dp_12,
            //     left: TdResDimens.dp_12
            //   ),
            //   child:
            BlocBuilder<WordDefineController, WordDefineCubitState>(
              bloc: mBloc,
              buildWhen:
                  (previous, current) =>
                      current.isSubmitEnabled != previous.isSubmitEnabled,
              builder: (context, state) {
                return ElevatedButton(
                  onPressed:
                      state.isSubmitEnabled
                          ? () {
                            // onClick();
                            FocusScope.of(context).unfocus();
                            mBloc.onFormSubmit();
                          }
                          : null,
                  clipBehavior: Clip.hardEdge,

                  style: ElevatedButton.styleFrom(
                    // elevation: 2,
                    shadowColor: themeColors?.onSurface.withOpacity(0.4),
                    // visualDensity: VisualDensity.compact,
                    // minimumSize: const Size(TdResDimens.dp_108, 36),
                    backgroundColor: themeColors.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: TdResDimens.dp_12,
                      vertical: TdResDimens.dp_8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      // side: BorderSide()
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // SvgPicture.asset(
                      //   'assets/svg/google_icon.svg',
                      //   width: TdResDimens.dp_20,
                      // ),
                      // TdResGaps.h_8,
                      // Icon(CommonIcons.location, color: Colors.white),
                      TdResGaps.h_8,

                      // Text(
                      //   "Search",
                      //   textAlign: TextAlign.center,
                      //   style: TdResTextStyles.button,
                      // ),
                      Icon(
                        Icons.search,
                        color: state.isSubmitEnabled ? Colors.white : null,
                      ),
                      TdResGaps.h_8,
                      // Icon(CommonIcons.arrow_down_small, color: Colors.white),
                    ],
                  ),
                );
              },
            ),
            TdResGaps.h_10,
          ],
        ),
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
        ),
      ),
    );
  }

  /* **************************************************************************************
 *                                  prepareTheme
 */

  prepareTheme(BuildContext context) {
    themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: Color(0xFF6CE18D), isDark: false);
    appThemeDisplay = TdThemeHelper.prepareThemeDisplay(context);
    // mLogger.d("prepareTheme: $themeColors.surface");
  }

  @override
  bool get wantKeepAlive => true;
}
