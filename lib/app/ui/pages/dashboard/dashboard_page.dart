import 'package:dharak_flutter/app/domain/verse/constants.dart';
import 'package:dharak_flutter/app/providers/google/signin-button/index.dart';
import 'package:dharak_flutter/app/tools/route/route_change_notifier.dart';
import 'package:dharak_flutter/app/types/verse/language_pref.dart';
import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/controller.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/cubit_states.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/dashboard_args.dart';
import 'package:dharak_flutter/app/ui/sections/auth/constants.dart';
import 'package:dharak_flutter/app/ui/sections/history/args.dart';
import 'package:dharak_flutter/app/ui/sections/history/modal.dart';
import 'package:dharak_flutter/app/ui/sections/navigations/dashboard-side-navigation_widget.dart';
import 'package:dharak_flutter/app/ui/shared/common/error/error_dialog.dart';
import 'package:dharak_flutter/res/layouts/breakpoints.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:dharak_flutter/app/ui/sections/verses/bookmarks/args.dart';
import 'package:dharak_flutter/app/ui/sections/verses/bookmarks/modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:dharak_flutter/res/theme/app_theme_provider.dart';
import 'package:dharak_flutter/app/ui/utils/tab_colors.dart';
import 'package:dharak_flutter/app/ui/providers/active_section_provider.dart';
import 'package:dharak_flutter/app/ui/widgets/beta_badge.dart';
import 'package:dharak_flutter/app/ui/widgets/beta_floating_button.dart';
import 'package:dharak_flutter/app/ui/widgets/beta_welcome_dialog.dart';
import 'package:dharak_flutter/app/ui/widgets/bug_report_service.dart';

class DashboardPage extends StatefulWidget {
  final DashboardArgsRequest mRequestArgs;

  const DashboardPage({super.key, required this.mRequestArgs});

  @override
  State<DashboardPage> createState() => _AppRootState();
}

class _AppRootState extends State<DashboardPage> {
  final List<DashboardDestination> defaultMainDestinations =
      <DashboardDestination>[
        DashboardDestination(
          label: UiConstants.Tabs.TABS_LABEL[UiConstants.Tabs.quicksearch] ?? "",
          icon: Icons.electric_bolt,
          selectedIcon: Icons.electric_bolt,
          tabName: UiConstants.Tabs.quicksearch,
          routePath: UiConstants.Routes.getRoutePath(UiConstants.Routes.quicksearch),
        ),
        DashboardDestination(
          label: UiConstants.Tabs.TABS_LABEL[UiConstants.Tabs.prashna] ?? "",
          icon: Icons.chat_bubble_outline,
          selectedIcon: Icons.chat_bubble_outline,
          tabName: UiConstants.Tabs.prashna,
          routePath: UiConstants.Routes.getRoutePath(UiConstants.Routes.prashna),
        ),
      ];

  // Legacy destinations for dropdown menu
  final List<DashboardDestination> legacyDestinations =
      <DashboardDestination>[
        DashboardDestination(
          label: UiConstants.Tabs.TABS_LABEL[UiConstants.Tabs.wordDefine] ?? "",
          icon: Icons.local_library_outlined,
          selectedIcon: Icons.local_library_outlined,
          tabName: UiConstants.Tabs.wordDefine,
          routePath: UiConstants.Routes.getRoutePath(
            UiConstants.Routes.wordDefine,
          ),
        ),
        DashboardDestination(
          label: UiConstants.Tabs.TABS_LABEL[UiConstants.Tabs.verse] ?? "",
          icon: Icons.keyboard_command_key,
          selectedIcon: Icons.keyboard_command_key,
          tabName: UiConstants.Tabs.verse,
          routePath: UiConstants.Routes.getRoutePath(UiConstants.Routes.verse),
        ),
      ];

  int screenIndex = 0;

  // int selectecIndex = 0;

  late AppThemeColors themeColors;
  late AppThemeDisplay appThemeDisplay;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Removed auth root modal - using new login system

  ErrorDialog? mErrorDialog;
  DashboardController mBloc = Modular.get<DashboardController>();
  RouteChangeNotifier? _mRouteChangeNotifier;

  int _mCurrentTabIndexState = 0;

  @override
  void initState() {
    super.initState();


    mBloc.initSetup();

    mErrorDialog = ErrorDialog();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {

      mBloc.initData(widget.mRequestArgs);
      _subscribeBloc();
      
      // Log current route for debugging
      final currentRoute = Modular.to.path;
      
      // Beta welcome dialog is now integrated into onboarding flow

      // this.authAccountRepository.loadDisplayName();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    prepareTheme(context);
    if (_mRouteChangeNotifier != null) {
      try {
        _mRouteChangeNotifier?.removeListener(_onRouteChanged);
      } catch (e) {
        print("dashboard app state _mRouteChangeNotifier: remove err");
      }
      _mRouteChangeNotifier = null;
    }
    _mRouteChangeNotifier = Provider.of<RouteChangeNotifier>(context);
    _mRouteChangeNotifier?.addListener(_onRouteChanged);
  }

  /// Get dynamic color based on current tab and active section
  Color _getDynamicTabColor(String? currentTab, BuildContext context) {
    print('🎨 Dashboard: _getDynamicTabColor called with currentTab = $currentTab');
    print('🎨 Dashboard: Expected QuickSearch tab constant = ${UiConstants.Tabs.quicksearch}');
    
    if (currentTab == null) {
      print('🎨 Dashboard: currentTab is null, returning unified color');
      return TabColors.unifiedColor;
    }
    
    // For QuickSearch tab, get color based on active section
    if (currentTab == UiConstants.Tabs.quicksearch) {
      try {
        final provider = Provider.of<ActiveSectionProvider>(context, listen: true);
        final activeSection = provider.activeSection;
        final color = TabColors.getQuickSearchSectionColor(activeSection);
        print('🎨 Dashboard: ✅ QuickSearch tab detected! - section = $activeSection, color = $color');
        return color;
      } catch (e) {
        print('🚨 Dashboard: Provider error = $e');
        return TabColors.unifiedColor; // Fallback to unified color
      }
    }
    
    // For other tabs, get their specific color
    final color = TabColors.getMainTabColor(currentTab);
    print('🎨 Dashboard: Other tab ($currentTab) color = $color');
    print('🎨 Dashboard: Tab comparison: "$currentTab" == "${UiConstants.Tabs.quicksearch}" = ${currentTab == UiConstants.Tabs.quicksearch}');
    return color;
  }

  void _onDestinationSelected(int index) {
    print("_onDestinationSelected index: ${index}");

    if (index < defaultMainDestinations.length &&
        defaultMainDestinations[index].routePath != null) {
      final routePath = defaultMainDestinations[index].routePath!;
      final tabName = defaultMainDestinations[index].tabName;
      
      print("_onDestinationSelected routePath: ${routePath}, tabName: ${tabName}");

      // Prevent rapid successive tab switches
      if (mBloc.state.currentTab == tabName) {
        print("🚫 Dashboard: Tab already selected, ignoring");
        return;
      }

      // Update the BLoC state directly
      print("🔧 Dashboard: Force updating tab to: ${tabName}");
      mBloc.onTabChanged(tabName);
      print("🔧 Dashboard: After force update, state.currentTab = ${mBloc.state.currentTab}");

      // Use pushNamed instead of pushReplacementNamed to avoid navigation conflicts
      Modular.to.pushNamed(routePath);
    }
  }

  void _onRouteChanged() {
    if (!mounted || !context.mounted) {
      return;
    }
    var currentTab =
        Provider.of<RouteChangeNotifier>(context, listen: false).currentTab;
    var currentRoute =
        Provider.of<RouteChangeNotifier>(context, listen: false).currentRoute;

    print(
      "#DashboardPage _onRouteChanged: tab=${currentTab}, route=${currentRoute}",
    );
    print(
      "🔄 Dashboard: About to call mBloc.onTabChanged with: ${currentTab}",
    );

    mBloc.onTabChanged(currentTab);
    
    print(
      "🔄 Dashboard: After onTabChanged, state.currentTab = ${mBloc.state.currentTab}",
    );
    // selectedNavigation
    // var index = currentTab != null
    //     ? onCurrentTabSelected(currentTab) ?? selectedNavigation
    //     : selectedNavigation;
    // setState(() {
    //   _mCurrentTab = currentTab;
    //   selectedNavigation = index;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = ActiveSectionProvider();
        // Initialize with 'unified' as default
        provider.setActiveSection('unified');
        return provider;
      },
      child: _buildDashboard(context),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    prepareTheme(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<DashboardController, DashboardCubitState>(
          bloc: mBloc,
          listenWhen:
              (previous, current) =>
                  previous.toastCounter != current.toastCounter,
          listener: (context, state) {
            _showToast(state.message ?? "");
          },
        ),
        BlocListener<DashboardController, DashboardCubitState>(
          bloc: mBloc,
          listenWhen:
              (previous, current) =>
                  previous.retryCounter != current.retryCounter,
          listener: (context, state) {
            _showError(message: state.message);
          },
        ),
        BlocListener<DashboardController, DashboardCubitState>(
          bloc: mBloc,
          listenWhen: (previous, current) => previous.user != current.user,
          listener: (context, state) {
            if (state.user == null) {
              // TODO _navigateToLanding();
            }
          },
        ),

        BlocListener<DashboardController, DashboardCubitState>(
          bloc: mBloc,
          listenWhen:
              (previous, current) => previous.currentTab != current.currentTab,
          listener: (context, state) {
            var currentIndex = defaultMainDestinations.indexWhere(
              (e) => e.tabName == state.currentTab,
            );
            
            // If currentTab is not found in main destinations (e.g., legacy tabs), default to first tab
            if (currentIndex == -1) {
              currentIndex = 0;
            }
            
            setState(() {
              _mCurrentTabIndexState = currentIndex;
            });

            print("setState _mCurrentTabIndexState working property");
          },
        ),
        BlocListener<DashboardController, DashboardCubitState>(
          bloc: mBloc,
          listenWhen:
              (previous, current) =>
                  previous.loginNeededCounter != current.loginNeededCounter &&
                  !current.authPopupOpen,
          listener: (context, state) {
            if (state.loginNeededCounter != 0) {
              FocusScope.of(context).unfocus();
              // Navigate to login page
              Modular.to.pushNamed('/login');
            }
          },
        ),

        BlocListener<DashboardController, DashboardCubitState>(
          bloc: mBloc,
          listenWhen:
              (previous, current) =>
                  previous.googleWebLoggedInCounter !=
                  current.googleWebLoggedInCounter,
          listener: (context, state) {
            if (state.googleWebLoggedInCounter != 0) {
              // _modalAuth(AuthUiConstants.PURPOSE_GOOGLE_LOGIN);
              // TODO _navigateToLanding();
              // User logged in via web, continue with app
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ],
      child: _widgetContent(),
    );
  }

  @override
  void dispose() {
    try {
      _mRouteChangeNotifier?.removeListener(_onRouteChanged);
    } catch (e) {
      print("dashboard app state _mRouteChangeNotifier: remove err");
    }
    super.dispose();
  }

  _subscribeBloc() {
    // _DisplayNameSubscription =
    //     authAccountRepository.mDisplayNameObservable.listen((onData) {
    //   setState(() {
    //     _mDisplayName = onData;
    //   });
    // }, onError: (e) {
    //   print("_subscribeBloc: error: $e");
    // });

    // authAccountRepository.accountChangedObservable.listen((onData) {
    //   if (onData) {
    //     _navigateToHome();
    //   }
    // });
  }

  void _navigateToLanding() {
    Modular.to.navigate(UiConstants.Routes.landing);
  }

  /* *******************************************************************************
   *                                          Widget
   */

  Widget _widgetContent() {
    // var max = maxWidth();

    var isMobile = _isMobile();
    return Stack(
      children: [
        Scaffold(
            key: _scaffoldKey,
            appBar: _widgetAppbar(context, isMobile: isMobile),
            // bot
            bottomNavigationBar:
                isMobile ? _widgetRouterOutletBottomAppBar(context) : null,
            body: Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
              children: [
                if (!isMobile)
                  DashboardSideNavigationWidget(
                    isMobile: false,

                    // selectedNavigation: screenIndex,
                    onDestinationSelected: _onDestinationSelected,  // ✅ Use the proper navigation function
                    mainDestinations: defaultMainDestinations,
                  ),
                const Flexible(flex: 1, child: RouterOutlet()),
              ],
            ),
            // drawer: isMobile
            //     ? DashboardSideNavigationWidget(
            //         isMobile: true,
            //         mainDestinations: defaultMainDestinations,
            //         // selectedNavigation: screenIndex,
            //         onDestinationSelected: (int index) {
            //           setState(() {
            //             screenIndex = index;
            //           });
            //         },
            //       )
            //     : null,
          ),
          
          // Floating Bug Report Button positioned over bottom navbar
          if (_isMobile())
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20, // Avoid gesture bar + navbar
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: _showBugReportOptions,
                    backgroundColor: Colors.red.shade600,
                    elevation: 8,
                    mini: false,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.attach_email_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 28,
                        ),
                        // Small beta indicator
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
    );
  }

  Widget _widgetSectionHeader() {
    return BlocBuilder<DashboardController, DashboardCubitState>(
      bloc: mBloc,
      buildWhen:
          (previous, current) => current.currentTab != previous.currentTab,
      builder: (context, state) {
        return Wrap(
          children: [
            if (state.currentTab != null)
              Text(
                UiConstants.Tabs.TABS_LABEL[state.currentTab] ?? "",
                style: TdResTextStyles.h4,
              ),
          ],
        );
      },
    );
  }

  Widget _widgetRouterOutletBottomAppBar(BuildContext context) {
    // themeColors.secondaryColor.withAlpha(0x90);
    return BlocBuilder<DashboardController, DashboardCubitState>(
      bloc: mBloc,
      buildWhen:
          (previous, current) => current.currentTab != previous.currentTab,
      builder: (context, state) {
        // Default to first tab if currentTab is null
        var currentTab = state.currentTab ?? defaultMainDestinations.first.tabName;
        
        var currentIndex = defaultMainDestinations.indexWhere(
          (e) => e.tabName == currentTab,
        );
        
        // If currentTab is not found in main destinations (e.g., legacy tabs), default to first tab
        if (currentIndex == -1) {
          currentIndex = 0;
          currentTab = defaultMainDestinations.first.tabName;
        }

        // Wrap in Consumer to listen to ActiveSectionProvider changes
        return Consumer<ActiveSectionProvider>(
          builder: (context, activeProvider, child) {
            // Get dynamic color based on active tab and section
            var seedColor = _getDynamicTabColor(currentTab, context);
            print('🎨 Dashboard: Building bottom nav with seedColor = $seedColor');
            
            return _buildBottomNavigationBar(state, currentIndex, seedColor);
          },
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(DashboardCubitState state, int currentIndex, Color seedColor) {
    var selectedItemColor = Color.alphaBlend(
      seedColor.withAlpha(0x80),
      themeColors.onSurface,
    );
    var unselectedItemColor = Color.alphaBlend(
      seedColor.withAlpha(0x60),
      themeColors.onSurfaceMedium,
    );

    return Container(
          decoration: BoxDecoration(
            // borderRadius: const BorderRadius.only(
            //   topRight: Radius.circular(24),
            //   topLeft: Radius.circular(24),
            // ),
            boxShadow: [
              BoxShadow(
                color: seedColor.withAlpha(0x12),
                spreadRadius: 0,
                blurRadius: 8,
              ),
            ],
          ),
          child: ClipRRect(
            // borderRadius: const BorderRadius.only(
            //   topLeft: Radius.circular(24.0),
            //   topRight: Radius.circular(24.0),
            // ),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: seedColor ?? Colors.amber),
                ),
              ),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,

                showSelectedLabels: true,
                showUnselectedLabels: true,
                unselectedIconTheme: IconThemeData(color: unselectedItemColor),
                selectedIconTheme: IconThemeData(color: selectedItemColor),
                unselectedItemColor: unselectedItemColor,
                unselectedLabelStyle: TdResTextStyles.h5,
                selectedLabelStyle: TdResTextStyles.h5,
                selectedItemColor: selectedItemColor,
                elevation: 6,
                backgroundColor: Color.alphaBlend(
                  seedColor.withAlpha(0x32),
                  themeColors.surface,
                ),
                onTap: (id) {
                  _onDestinationSelected(id);
                  // if (id == 0) {
                  //   setState(() {
                  //     // Modular.to.navigate(UiConstants.Routes.homeDetails);
                  //     Modular.to.pushNamedAndRemoveUntil(
                  //       UiConstants.Routes.wordDefine,
                  //       (p0) {
                  //         var isTrue = true;
                  //         // TODO implement here
                  //         //if (p0.settings.name == UiConstants.Routes.r1 ||
                  //         //     p0.settings.name ==
                  //         //         UiConstants.Routes.r2) {
                  //         //   isTrue = false;
                  //         // }
                  //         // mLogger.d("_widgetRouterOutletBottomAppBar 0: $isTrue ");
                  //         return isTrue;
                  //       },
                  //     );
                  //     // TODO _mPageIndex = 0;
                  //     // Modular.to.navigate(UiConstants.Routes.homeDetails);
                  //   });
                  // } else if (id == 1) {
                  //   setState(() {
                  //     // Modular.to.navigate(UiConstants.Routes.homeAnalysis);
                  //     Modular.to.pushNamedAndRemoveUntil(UiConstants.Routes.verse, (
                  //       p0,
                  //     ) {
                  //       var isTrue = true;
                  //       // TODO implement here
                  //       // if (p0.settings.name == UiConstants.Routes.homeDetails ||
                  //       //     p0.settings.name ==
                  //       //         UiConstants.Routes.homeAccount) {
                  //       //   isTrue = false;
                  //       // }
                  //       // mLogger.d("_widgetRouterOutletBottomAppBar 1: $isTrue");

                  //       // inspect(p0);
                  //       return isTrue;
                  //     });
                  //     // TODO _mPageIndex = 1;
                  //   });
                  // }
                },
                currentIndex: () {
                  var index = defaultMainDestinations.indexWhere(
                    (e) => e.tabName == state.currentTab,
                  );
                  return index == -1 ? 0 : index; // Default to first tab if not found
                }(),
                items:
                    defaultMainDestinations
                        .map(
                          (e) => BottomNavigationBarItem(
                            icon: Icon(e.icon),
                            activeIcon: Icon(e.selectedIcon),
                            label: e.label,
                            tooltip: e.label,
                          ),
                        )
                        .toList(),

                //  const [
                //   BottomNavigationBarItem(
                //       icon: Icon(Icons.book), tooltip: 'Home', label: 'Home'),
                //   BottomNavigationBarItem(
                //       icon: Icon(Icons.format_quote),
                //       tooltip: 'Transaction',
                //       label: 'Transaction'),
                // ],
              ),
            ),
          ),
        );
  }

  PreferredSizeWidget _widgetAppbar(
    BuildContext context, {
    bool isMobile = false,
  }) {
    // print(_mCollection);

    // inspect(_mCollection);

    // var primaryColor = Theme.of(context).colorScheme

    var seedColor =
        _mCurrentTabIndexState == 1
            ? themeColors.primaryHigh
            : themeColors.secondaryColor;

    return AppBar(
      elevation: 1,
      toolbarHeight: 64,
      leadingWidth: 64,
      shadowColor: seedColor,
      backgroundColor: Color.alphaBlend(
        seedColor.withAlpha(0x02),
        themeColors.surface,
      ),
      //  themeColors.back,
      centerTitle: false,
      // shape: const RoundedRectangleBorder(
      //   borderRadius: BorderRadius.only(
      //     topLeft: Radius.circular(0),
      //     topRight: Radius.circular(0),
      //     bottomRight: Radius.circular(TdResDimens.dp_32),
      //     bottomLeft: Radius.circular(TdResDimens.dp_32),
      //   ),
      // ),
      automaticallyImplyLeading: isMobile,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 40,
            // width: 120,
            alignment: Alignment.centerLeft,

            constraints: BoxConstraints( maxHeight: 44),
            margin: const EdgeInsets.only(right: 12),
            // padding: const EdgeInsets.all(6),
            // decoration: BoxDecoration(
            //   // borderRadius: BorderRadius.circular(16.0),
            //   // color: themeColors.onSurface.withAlpha(0x06),
            //   image: DecorationImage(

            //     image: AssetImage("assets/img/Dhara.png"),

            //     fit: BoxFit.fitHeight,
            //     alignment: Alignment.centerLeft,

            //     colorFilter: ColorFilter.mode(
            //       Color.alphaBlend(
            //         themeColors.onSurface.withAlpha(0x22),
            //         seedColor,
            //       ),
            //       BlendMode.srcIn,
            //     ),
            //   ),
            // ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              // crossAxisAlignment: CrossAxisAlignment.,
              spacing: TdResDimens.dp_4,
              children: [
                SvgPicture.asset(

                  'assets/svg/Dhara_vector.svg',

                  width: TdResDimens.dp_32,
                  height: TdResDimens.dp_28,
                  


                  // colorFilter: ,
                  // height: TdResDimens.dp_40,
                ),

                Text("Dhārā", style: TdResTextStyles.h3.copyWith(color: themeColors.onSurface?.withAlpha(0xed))),
                const SizedBox(width: 8),
                const BetaBadge(showFloating: false),
              ],
            ),

            // ),
          ),

          Flexible(
            flex: 1,
            fit: FlexFit.loose,
            child:
            // isMobile
            //     ? _widgetSectionHeader()
            //     :
            Text(
              "",
              textAlign: TextAlign.start,
              overflow: TextOverflow.ellipsis,
              style: TdResTextStyles.h4,
            ),
          ),
        ],
      ),
      leading: null,
      // isMobile
      //     ? null
      //     :
      // Padding(
      //   padding: EdgeInsets.symmetric( horizontal: TdResDimens.dp_8),
      //   child:
      actions: [
        BlocBuilder<DashboardController, DashboardCubitState>(
          bloc: mBloc,
          buildWhen:
              (previous, current) =>
                  current.user != previous.user ||
                  current.currentTab != previous.currentTab,
          builder: (context, state) {
            if (!context.mounted) {
              return SizedBox.shrink();
            }

            if (state.user != null) {
              var avatarUrl = state.user?.picture;
              return Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (avatarUrl != null)
                    Container(
                      height: TdResDimens.dp_40,
                      width: TdResDimens.dp_40,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        // color: themeColors.onSurface.withOpacity(0.04),
                      ),
                      child: Image.network(avatarUrl,fit: BoxFit.cover,),

                      // ),
                    ),
                  Text(state.user?.name ?? "", style: TdResTextStyles.h6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: PopupMenuButton<void>(
                      // key: Key(
                      //   "mainMenu-${state.verseLanguagePref?.output ?? ""}",
                      // ),
                      color: themeColors.surface,

                      itemBuilder:
                          (context2) => [
                            ..._widgetAppBarActions(
                              context2,
                              mBloc.state.currentTab,
                            ),
                            PopupMenuItem(
                              child: Consumer<AppThemeProvider>(
                                builder: (context, themeProvider, child) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    spacing: TdResDimens.dp_12,
                                    children: [
                                      Icon(
                                        themeProvider.isDarkMode 
                                            ? Icons.light_mode 
                                            : Icons.dark_mode,
                                        color: themeColors.onSurface,
                                      ),
                                      Text(
                                        themeProvider.isDarkMode 
                                            ? 'Light Mode' 
                                            : 'Dark Mode',
                                        style: TdResTextStyles.button.copyWith(
                                          color: themeColors.onSurface,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              onTap: () {
                                Provider.of<AppThemeProvider>(context, listen: false)
                                    .toggleThemeMode();
                              },
                            ),
                            PopupMenuItem(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: TdResDimens.dp_12,
                                children: [
                                  Icon(
                                    Icons.switch_account,
                                    color: themeColors.onSurface,
                                  ),
                                  Text(
                                    'Switch Account',
                                    style: TdResTextStyles.button.copyWith(
                                      color: themeColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Future.delayed(Duration(milliseconds: 400), () {
                                  mBloc.onClickSwitchAccount().then((onValue) {});
                                });
                                // Switch account logic
                              },
                            ),
                          ],
                      child: Icon(
                        Icons.more_vert,

                        color: themeColors.onSurfaceMedium,
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return googleSignInButton(
                isDense: true,
                themeColors: themeColors,
                appThemeDisplay: appThemeDisplay,
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  // Navigate to login page
                  Modular.to.pushNamed('/login');
                },
              );
            }
          },
        ),

        // Align(
        //     alignment: Alignment.center,
        //     child: _mDisplayName.isEmpty
        //         ? TdButtonWidget(
        //             widthType: TdButtonWidget.WIDTH_WRAP,
        //             isSecondary: false,
        //             isCompact: true,
        //             mTxt: "Login",
        //             themeColors: themeColors,
        //             // mIconData: Icons.keyboard_arrow_down_rounded,
        //             isRtl: true,
        //             mOnClicked: () {
        //               // _showFilterMenu(context);
        //               // _modalAuth(AuthUiConstants.PURPOSE_EMAIL_LOGIN);
        //             },
        //           )
        //         : Text(
        //             _mDisplayName,
        //             style: TdResTextStyles.h5Medium,
        //           )),
        // IconButton(
        //   splashRadius: 22,
        //   icon: Icon(
        //     Icons.notifications_rounded,
        //     color: themeColors.onSurface,
        //   ),
        // ),
        TdResGaps.h_10,
      ],
    );
  }

  List<PopupMenuItem> _widgetAppBarActions(
    BuildContext context2,
    String? currentTab,
  ) {
    if (!context2.mounted || !mounted) {
      return [];
    }
    if (currentTab == UiConstants.Tabs.verse) {
      return [
        PopupMenuItem(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            spacing: TdResDimens.dp_12,
            children: [
              Icon(Icons.bookmarks, color: themeColors.onSurface),
              Text(
                'Bookmarks',
                style: TdResTextStyles.buttonSmall.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
            ],
          ),
          onTap: () {
            _modalBookmarks(context);
            // mBloc.onClickLogout();
            // Sign out logic
          },
        ),
        PopupMenuItem(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            spacing: TdResDimens.dp_12,
            children: [
              Icon(Icons.history, color: themeColors.onSurface),
              Text(
                'Search History',
                style: TdResTextStyles.buttonSmall.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
            ],
          ),
          onTap: () {
            _modalSearchHistory(context, true);
            // mBloc.onClickLogout();
            // Sign out logic
          },
        ),
        _widgetActionVerseLanguage(),
      ];
    } else if (currentTab == UiConstants.Tabs.wordDefine) {
      return [
        PopupMenuItem(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            spacing: TdResDimens.dp_12,
            children: [
              Icon(Icons.history, color: themeColors.onSurface),
              Text(
                'Search History',
                style: TdResTextStyles.buttonSmall.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
            ],
          ),
          onTap: () {
            _modalSearchHistory(context, false);
            // mBloc.onClickLogout();
            // Sign out logic
          },
        ),
      ];
    }

    return [];
  }

  PopupMenuItem _widgetActionVerseLanguage() {
    return PopupMenuItem(
      child: BlocBuilder<DashboardController, DashboardCubitState>(
        bloc: mBloc,
        buildWhen:
            (previous, current) =>
                current.verseLanguagePref != previous.verseLanguagePref,
        builder: (context, state) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            spacing: TdResDimens.dp_12,
            children: [
              Icon(Icons.translate_outlined, color: themeColors.onSurface),

              Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(TdResDimens.dp_12),
                    border: Border.all(color: themeColors.onSurfaceDisable),
                  ),

                  // width: double.maxFinite,
                  child: DropdownButton<String>(
                    key: ValueKey('dashboard_language_dropdown_${state.verseLanguagePref?.output ?? VersesConstants.LANGUAGE_HINDI}'), // Force rebuild on language change
                    value:
                        state.verseLanguagePref?.output ??
                        VersesConstants.LANGUAGE_HINDI,
                    // menuWidth: TdResDimens.dp_120,

                    // menuWidth: double.maxFinite,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    elevation: 16,
                    style: TdResTextStyles.h5.copyWith(
                      color: themeColors.onSurface,
                    ),
                    underline: Container(color: Colors.transparent),

                    // underline: Container(height: 2, color: Colors.deepPurpleAccent),
                    onChanged: (String? value) {
                      // This is called when the user selects an item.
                      // setState(() {
                      //   dropdownValue = value!;
                      // });

                      if (value != null) {
                        print("🎯 DASHBOARD: User selected language '$value' from dropdown");
                        mBloc.onVerseLanguageChange(value);
                      }
                    },

                    isExpanded: true,
                    // selectedItemBuilder:
                    //     (context) =>
                    //         <String>["English", "Hindi"].map<Widget>((
                    //           String value,
                    //         ) {
                    //           return Flexible(
                    //             flex: 1,
                    //             fit: FlexFit.tight,
                    //             child: Text(
                    //               value,
                    //               style: TdResTextStyles.h5.copyWith(
                    //                 color: themeColors.onSurface,
                    //               ),
                    //             ),
                    //           );
                    //           // return DropdownMenuItem<String>(
                    //           //   value: value,
                    //           //   alignment: Alignment.center,

                    //           //   child: Text(value, style: TdResTextStyles.h5.copyWith(color: themeColors.onSurface),),
                    //           // );
                    //         }).toList(),
                    items:
                        VersesConstants.LANGUAGE_LABELS_MAP.entries
                            .map<DropdownMenuItem<String>>((
                              MapEntry<String, String?> entry,
                            ) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                alignment: Alignment.center,

                                child: Text(
                                  entry.value ?? "all",
                                  style: TdResTextStyles.h5.copyWith(
                                    color: themeColors.onSurface,
                                  ),
                                ),
                              );
                            })
                            .toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /* *****************************************************************************
   *                      modal
   */

  /* **********************************************************************************
   *                                      dialog
   * 
   */

  Future<bool> _modalSearchHistory(
    BuildContext context,
    bool isForVerse,
  ) async {
    showDialog<SearchHistoryArgsResult>(
      context: context,
      // routeSettings:
      //     RouteSettings(name: UiConstants.Routes.dialogLoginEmail),
      builder:
          (BuildContext context) => SearchHistoryModal(
            mRequestArgs: SearchHistoryArgsRequest(isForVerse: isForVerse),
          ),
    ).then((value) {
      // print("_modalBookmarks result: ${value}");
      // inspect(value);
      // if (kDebugMode) {
      //   print("_modalBookmarks: $value");
      // }
      if (value != null &&
          value.resultCode == UiConstants.BundleArgs.resultSuccess) {
        // print("_modalBookmarks : resultSuccess");

        if (value.searchQuery != null) {
          mBloc.onNewSearchQuery(isForVerse, value.searchQuery);
        }

        // mBloc
        //     .refreshVerseList();

        // mBlocCustomization.onUpdatedAddons(value.);
      } else {
        // print("_modalBookmarks canceled");

        // mBloc.cancel();
        // mBloc.
      }
    });

    return false;
  }

  Future<bool> _modalBookmarks(BuildContext context) async {
    showDialog<VerseBookmarksArgsResult>(
      context: context,
      // routeSettings:
      //     RouteSettings(name: UiConstants.Routes.dialogLoginEmail),
      builder:
          (BuildContext context) =>
              VerseBookmarksModal(mRequestArgs: VerseBookmarksArgsRequest()),
    ).then((value) {
      // print("_modalBookmarks result: ${value}");
      // inspect(value);
      // if (kDebugMode) {
      //   print("_modalBookmarks: $value");
      // }
      if (value != null &&
          value.resultCode == UiConstants.BundleArgs.resultSuccess) {
        // print("_modalBookmarks : resultSuccess");

        // mBloc
        //     .refreshVerseList();

        // mBlocCustomization.onUpdatedAddons(value.);
      } else {
        // print("_modalBookmarks canceled");

        // mBloc.cancel();
        // mBloc.
      }
    });

    return false;
  }

  // Auth modal method removed - using new login system
  _modalAuth(int purpose, [String value = '']) {
    // Redirect to login page instead
    Modular.to.pushNamed('/login');
 }

  /* *****************************************************************************
   *                              error
   */

  _showError({String? message}) {
    mErrorDialog?.start(context, message, () {
      // TODO  mBloc.add(const CommuneBankerDetailRetryBlocEvent());
    });
  }

  void _showToast(String message) {
    print("_showToast : Dashboard ${message}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
        ),
      ),
    );
  }

  void _showBetaWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const BetaWelcomeDialog(),
    );
  }

  void _showBugReportOptions() {
    BugReportService.instance.showBugReportOptions(context);
  }


  /* *********************************************************************************
 *                                      theme
 */

  prepareTheme(BuildContext context) {
    themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: Color(0xFF6CE18D), isDark: false);
    appThemeDisplay = TdThemeHelper.prepareThemeDisplay(context);
    // mLogger.d("prepareTheme: $themeColors.surface");
  }

  int? maxWidth() {
    if (appThemeDisplay.breakpointType == BreakpointType.lg) {
      return Breakpoints.BREAKPOINTS_VALUES[BreakpointType.md];
    } else if (appThemeDisplay.breakpointType == BreakpointType.xl) {
      return Breakpoints.BREAKPOINTS_VALUES[BreakpointType.md];
    } else if (appThemeDisplay.breakpointType == BreakpointType.xxl) {
      return Breakpoints.BREAKPOINTS_VALUES[BreakpointType.md];
    } else if (appThemeDisplay.breakpointType == BreakpointType.xxxl) {
      return Breakpoints.BREAKPOINTS_VALUES[BreakpointType.md];
    } else {
      return null;
    }
  }

  bool _isMobile() {
    if (appThemeDisplay.breakpointType == BreakpointType.sm) {
      return true;
    } else if (appThemeDisplay.breakpointType == BreakpointType.md) {
      return true;
    } else if (appThemeDisplay.breakpointType == BreakpointType.lg) {
      return true;
    }
    return false;
  }
}

class ExampleDestination {
  const ExampleDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}