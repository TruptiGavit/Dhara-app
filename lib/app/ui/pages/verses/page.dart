import 'dart:async';

import 'package:dharak_flutter/app/domain/auth/auth_account_repo.dart';
import 'package:dharak_flutter/app/tools/route/route_change_notifier.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/app/ui/pages/verses/args.dart';
import 'package:dharak_flutter/app/ui/pages/verses/controller.dart';
import 'package:dharak_flutter/app/ui/pages/verses/cubit_states.dart';
import 'package:dharak_flutter/app/ui/pages/verses/parts/item.dart';

import 'package:dharak_flutter/app/utils/util_color.dart';
import 'package:dharak_flutter/app/utils/util_string.dart';
import 'package:dharak_flutter/res/layouts/breakpoints.dart';
import 'package:dharak_flutter/res/layouts/containers.dart';
import 'package:dharak_flutter/res/styles/decorations.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:dharak_flutter/app/ui/widgets/aksharmukha_language_selector.dart';
import 'package:dharak_flutter/res/values/colors.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:dharak_flutter/app/data/services/supported_languages_service.dart';
import 'package:dharak_flutter/app/domain/verse/constants.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/controller.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/cubit_states.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class VersesPage extends StatefulWidget {
  final VersesArgsRequest mRequestArgs;
  final String title;
  const VersesPage({
    super.key,
    required this.mRequestArgs,
    this.title = 'VersesPage',
  });
  @override
  VersesPageState createState() => VersesPageState();
}

class VersesPageState extends State<VersesPage> {
  late AppThemeColors themeColors;
  late AppThemeDisplay appThemeDisplay;

  List<VerseRM> _mVerseList = List.empty(growable: true);

  // FocusNode _focusNode = FocusNode();

  final ScrollController _scrollController = ScrollController();
  VersesController mBloc = Modular.get<VersesController>();
  AuthAccountRepository mAuthAccountRepo = Modular.get<AuthAccountRepository>();

  StreamSubscription<bool>? _mLoginSubscription;
  final GlobalKey<SliverAnimatedListState> listKey =
      GlobalKey<SliverAnimatedListState>();
  @override
  void initState() {
    super.initState();
    // infoEdit.currentState.

    // mProgressDialog = ProgressDialog();

    // _scrollController.addListener(() => _scrollEventListen());

    // _setupListAdapter();
    _subscribeBloc();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // _fcmService.tryLog();
      // if (kIsWeb) {
      //   checkforAuth();

      // if (widget.tabName != null) {
      // UiConstants.Tabs.topics
      Provider.of<RouteChangeNotifier>(
        context,
        listen: false,
      ).updateTab(UiConstants.Tabs.verse);
      // }

      mBloc.initData(widget.mRequestArgs);
      // }
    });
  }

  _subscribeBloc() {
    // _mLoginSubscription = mAuthAccountRepo.accountChangedObservable
    //     .listen((onData) {
    //       if (onData) {
    //         // _getGoogleIdToken();

    //         // emit(
    //         //   state.copyWith(
    //         //     googleWebLoggedInCounter: state.googleWebLoggedInCounter + 1,
    //         //   ),
    //         // );

    //         Future.delayed(Duration(milliseconds: 500), () {

    //           try {
    //           if(mounted && context.mounted){
    //             print("operate====================");
    //           }
    //           } catch (e) {
    //             print("operate 2====================");

    //           }

    //         });
    //       }
    //     });
  }

  @override
  void dispose() {
    _mLoginSubscription?.cancel();
    mBloc?.stopPolling();
    super.dispose();
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
        BlocListener<VersesController, VersesCubitState>(
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
        BlocListener<VersesController, VersesCubitState>(
          bloc: mBloc,
          listenWhen:
              (previous, current) =>
                  previous.toastCounter != current.toastCounter,
          listener: (context, state) {
            _showToast(state.message ?? "");
          },
        ),

        BlocListener<VersesController, VersesCubitState>(
          bloc: mBloc,
          listenWhen:
              (previous, current) =>
                  previous.loginCounter != current.loginCounter,
          listener: (context, state) {
            print("operate====================");
            print("loginCounter: ${state.loginCounter}");
            // _showToast(state.message ?? "");
          },
        ),

        BlocListener<VersesController, VersesCubitState>(
          bloc: mBloc,

          listenWhen:
              (previous, current) =>
                  (previous.listReplacedCounter != current.listReplacedCounter),
          listener: (context, state) {
            if (state.verseList != null && state.listReplacedCounter > 0) {
              _mVerseList = state.verseList;
              print(
                "mEventVerseBookmarkStarred: listener, ${state.verseList.firstOrNull?.isStarred}",
              );

              // if(_mVerseList.length)
              listKey.currentState?.removeAllItems((
                BuildContext context,
                Animation<double> animation,
              ) {
                return Container();
              });

              // for (var i = 0; i < state.verseList.length; i++) {
              listKey.currentState?.insertAllItems(0, state.verseList.length);
              // }
            }
            if (state.isInitialized == true) {
              // _mListModelAdapter?.removeAt(index)
              // _mListModelAdapter?.invalidate(mBloc.nextPagingSource());
            }
          },
        ),

        BlocListener<VersesController, VersesCubitState>(
          bloc: mBloc,

          listenWhen:
              (previous, current) =>
                  (previous.listIndexInserted != current.listIndexInserted),
          listener: (context, state) {
            if (state.verseList.isNotEmpty) {
              _mVerseList = state.verseList;
              // print("listIndexInserted: , ${state.verseList.firstOrNull}");

              // if (state.listIndexInserted.$1 >= 0) {
              //   listKey.currentState?.setState(() {
              //     _mVerseList[state.listIndexInserted.$1] =
              //         state.activityList[state.listIndexInserted.$1];
              //   });
              // }
              listKey.currentState?.insertItem(state.listIndexInserted.$1);

              // _mListKey.currentState?.insertItem(0);
              // }
            }
          },
        ),

        BlocListener<VersesController, VersesCubitState>(
          bloc: mBloc,

          listenWhen:
              (previous, current) =>
                  (previous.listIndexUpdatedCounter !=
                      current.listIndexUpdatedCounter),
          listener: (context, state) {
            if (state.verseList != null) {
              print(
                "mEventVerseBookmarkStarred: listener, ${state.verseList.firstOrNull?.isStarred}",
              );

              if (state.listIndexUpdatedCounter.$1 >= 0) {
                listKey.currentState?.setState(() {
                  _mVerseList[state.listIndexUpdatedCounter.$1] =
                      state.verseList[state.listIndexUpdatedCounter.$1];

                  // state.verseList[state.listIndexUpdatedCounter.$1] =
                });
              }

              // }
            }
            if (state.isInitialized == true) {
              // _mListModelAdapter?.removeAt(index)
              // _mListModelAdapter?.invalidate(mBloc.nextPagingSource());
            }
          },
        ),
        // BlocListener<VersesController, VersesCubitState>(
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
    print("canLaunchUrl 1: ${urlLink}");
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
        themeColors.primaryHigh.withAlpha(0x12),
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
                  themeColors.primaryHigh.withAlpha(0x12),
                  themeColors.surface,
                ),
                surfaceTintColor: Color.alphaBlend(
                  themeColors.primaryHigh.withAlpha(0x12),
                  themeColors.surface,
                ),
                title: _widgetSearch(),
              ),

              // Aksharamukha bar (transcription credit + language selector)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: themeColors.primary.withAlpha(0x20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: themeColors.primary.withAlpha(0x1A), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      // Left side: Transcription credit (flexible to prevent overflow)
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.translate, size: 12, color: themeColors.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                "Transcription by Aksharamukha",
                                style: TdResTextStyles.caption.copyWith(
                                  color: themeColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            BlocBuilder<VersesController, VersesCubitState>(
                              bloc: mBloc,
                              buildWhen: (previous, current) => current.verseList != previous.verseList,
                              builder: (context, state) {
                                return Text(
                                  '${state.verseList.length} verses',
                                  style: TdResTextStyles.caption.copyWith(
                                    color: themeColors.onSurfaceMedium,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Right side: Language selector (fixed width)
                      _buildCompactLanguageSelector(),
                    ],
                  ),
                ),
              ),

              SliverAnimatedList(
                key: listKey,

                itemBuilder: (context, index, animation) {
                  if (index < _mVerseList.length) {
                    return VerseItemWidget(
                      appThemeDisplay: appThemeDisplay,
                      themeColors: themeColors,
                      entity: _mVerseList[index],

                      onAddToBookmark:
                          (entity, isToAdd) => {
                            mBloc.onBookmarkToggle(entity, !isToAdd),
                          },
                      onClickExternalUrl:
                          (urlLink) => launchExternalUrl(urlLink),
                      onClickCopy: (message) => copyToClipboard(message),
                      // New callbacks for Previous/Next verse navigation
                      onPreviousVerse: (versePk) => mBloc.onPreviousVerse(index, versePk),
                      onNextVerse: (versePk) => mBloc.onNextVerse(index, versePk),
                    );
                  }
                  return SizedBox.shrink();
                  // SizedBox(height: 200);
                },

                initialItemCount: _mVerseList.length,
              ),

              BlocBuilder<VersesController, VersesCubitState>(
                bloc: mBloc,
                buildWhen:
                    (previous, current) =>
                        current.isLoading != previous.isLoading ||
                        current.verseList != previous.verseList ||
                        current.searchCounter != previous.searchCounter,
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
                  } else if (state.verseList.isEmpty &&
                      state.searchCounter != 0) {
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
                  } else {
                    return SliverToBoxAdapter(child: const SizedBox.shrink());
                  }
                },
              ),
              // BlocBuilder<VersesController, VersesCubitState>(
              //   bloc: mBloc,
              //   buildWhen:
              //       (previous, current) =>
              //           current.verseList != previous.verseList,
              //   builder: (context, state) {
              //     return SliverAnimatedList(
              //       key: listKey,

              //       itemBuilder: (context, index, animation) {
              //         if (index < state.verseList.length) {
              //           return VerseItemWidget(
              //             appThemeDisplay: appThemeDisplay,
              //             themeColors: themeColors,
              //             entity: state.verseList[index],
              //             onAddToBookmark: (entity, isToAdd) => {
              //               mBloc.onBookmarkToggle(entity, !isToAdd)
              //             },
              //           );
              //         }
              //         return SizedBox.shrink();
              //         // SizedBox(height: 200);
              //       },

              //       initialItemCount: state.verseList.length,
              //     );
              //   },
              // ),
              SliverToBoxAdapter(child: SizedBox(height: 40)),
              // _widgetAnimatedlist(),
            ],
          ),
          // BlocBuilder<VersesController, VersesCubitState>(
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

  Widget _widgetTitle() {
    return BlocBuilder<VersesController, VersesCubitState>(
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
                    "Welcome to QuickVerse",
                    textAlign: TextAlign.center,
                    textScaler:TextScaler.linear(1.0), //fixed scaling to prevent distortion
                    style: (appThemeDisplay.isSamllHeight
                            ? TdResTextStyles.h1Bold
                            : TdResTextStyles.h0Bold)
                        .copyWith(
                          color: Color.alphaBlend(
                            themeColors.onSurface.withAlpha(0x42),
                            themeColors.primaryHigh,
                          ),
                          // UtilColor.darken(
                          //                     themeColors.secondaryColor,
                          //                     -0.4,
                          //                   ),
                        ),
                  ),
                  Text(
                    "Do you have a shloka, mantra, verse or a kriti humming in your mind? Search for it here. Just enter the parts you remember to get started!",
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
          color: themeColors.primaryHigh,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BlocBuilder<VersesController, VersesCubitState>(
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
                    // focusNode: _focusNode,

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
                      hintText: "Type Partial Verse to Search..",

                      prefixIcon: Icon(
                        Icons.search,
                        color: themeColors.onSurface.withAlpha(0xa6),
                      ),
                      suffixIcon:
                          UtilString.isStringsEmpty(state.formSearchText)
                              ? null
                              : IconButton(
                                padding: const EdgeInsets.symmetric(
                                  vertical: TdResDimens.dp_14,
                                ),

                                // alignment: Alignment.topCenter,
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
            //  _widgetSubmit(),
            //   TdResGaps.h_10,
          ],
        ),
      ),
    );
  }

  Widget _widgetSubmit() {
    return BlocBuilder<VersesController, VersesCubitState>(
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
            backgroundColor: themeColors.primary,
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
              Icon(
                Icons.search,
                color: state.isSubmitEnabled ? Colors.white : null,
              ),

              // Text(
              //   "Search",
              //   textAlign: TextAlign.center,
              //   style: TdResTextStyles.button,
              // ),
              TdResGaps.h_8,
              // Icon(CommonIcons.arrow_down_small, color: Colors.white),
            ],
          ),
        );
      },
    );
  }

  void _showToast(String message) {
    print("_showToast : verses ${message}");
    if (message.isEmpty) {
      return;
    }
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

  /// Compact language selector for the Aksharamukha bar - exactly like random folder
  Widget _buildCompactLanguageSelector() {
    final dashboardController = Modular.get<DashboardController>();

    return BlocBuilder<DashboardController, DashboardCubitState>(
      bloc: dashboardController,
      buildWhen: (previous, current) =>
          current.verseLanguagePref != previous.verseLanguagePref,
      builder: (context, state) {
        final currentLanguage = state.verseLanguagePref?.output ?? VersesConstants.LANGUAGE_DEFAULT;
        
        return PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: themeColors.primary,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getLanguageLabel(currentLanguage),
                  style: TdResTextStyles.caption.copyWith(
                    color: themeColors.surface,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 12,
                  color: themeColors.surface,
                ),
              ],
            ),
          ),
          onSelected: (String value) {
            final dashboardController = Modular.get<DashboardController>();
            dashboardController.onVerseLanguageChange(value);
          },
          itemBuilder: (context) => _getSupportedLanguages().entries.map<PopupMenuItem<String>>((entry) {
            return PopupMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: TdResTextStyles.buttonSmall.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Get language label from constants
  String _getLanguageLabel(String language) {
    return VersesConstants.LANGUAGE_LABELS_MAP[language] ?? language;
  }

  /// Get supported languages from service
  Map<String, String> _getSupportedLanguages() {
    try {
      return SupportedLanguagesService().getSupportedLanguages();
    } catch (e) {
      return VersesConstants.LANGUAGE_LABELS_MAP.map((k, v) => MapEntry(k, v ?? k));
    }
  }

  // @override
  // bool get wantKeepAlive => true;
}