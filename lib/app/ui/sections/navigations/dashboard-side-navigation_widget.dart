// import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:dharak_flutter/app/domain/auth/auth_account_repo.dart';
import 'package:dharak_flutter/app/tools/route/route_change_notifier.dart';
import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';
import 'package:flutter_svg/svg.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
// import 'package:sidebarx/sidebarx.dart';

class DashboardSideNavigationWidget extends StatefulWidget {
  // int selectedNavigation;

  final bool isMobile;
  final List<DashboardDestination>? mainDestinations;
  final Function(int index) onDestinationSelected;
  const DashboardSideNavigationWidget({
    super.key,
    required this.onDestinationSelected,
    // this.selectedNavigation = 0,
    this.mainDestinations,
    required this.isMobile,
  });
  @override
  DashboardSideNavigationState createState() => DashboardSideNavigationState();
}

class DashboardSideNavigationState
    extends State<DashboardSideNavigationWidget> {
  static const String STORE_DESTINATION_ID = "store";
  List<DashboardDestination> mainDestinations = [];

  final List<DashboardDestination> defaultMainDestinations =
      <DashboardDestination>[
        DashboardDestination(
          label: 'Home',
          svgSelected: 'assets/svg/icons/dashboard.svg',
          svgDefault: 'assets/svg/icons/dashboard_outlined.svg',
          tabName: UiConstants.Tabs.wordDefine,
          routePath: UiConstants.Routes.getRoutePath(
            UiConstants.Routes.wordDefine,
          ),
        ),
        DashboardDestination(
          label: 'All Orders',
          svgSelected: 'assets/svg/icons/orders.svg',
          svgDefault: 'assets/svg/icons/orders_outlined.svg',
          tabName: UiConstants.Tabs.verse,
          routePath: UiConstants.Routes.getRoutePath(UiConstants.Routes.verse),
        ),
      ];

  List<DashboardDestination> setupDestinations = <DashboardDestination>[
    // DashboardDestination(
    //     id: STORE_DESTINATION_ID,
    //     label: 'Store',
    //     svgSelected: 'assets/svg/icons/shop.svg',
    //     svgDefault: 'assets/svg/icons/shop_outlined.svg',
    //     tabName: UiConstants.Tabs.store,
    //     routePath:
    //         UiConstants.Routes.getRoutePath(UiConstants.Routes.storeDetail)),
    // DashboardDestination(
    //     label: 'Products',
    //     svgSelected: 'assets/svg/icons/items.svg',
    //     svgDefault: 'assets/svg/icons/items_outlined.svg',
    //     tabName: UiConstants.Tabs.product,
    //     routePath: UiConstants.Routes.getRoutePath(UiConstants.Routes.products))
  ];

  final List<DashboardDestination> othersDestinations = <DashboardDestination>[
    // DashboardDestination(
    //     label: 'Settings',
    //     svgSelected: 'assets/svg/icons/setting.svg',
    //     svgDefault: 'assets/svg/icons/setting_outlined.svg',
    //     tabName: UiConstants.Tabs.setting,
    //     routePath: UiConstants.Routes.getRoutePath(UiConstants.Routes.settings))
  ];

  final mLogger = Logger();

  late AppThemeColors themeColors;

  late AppThemeDisplay appThemeDisplay;

  int selectedNavigation = 0;

  String? _mCurrentTab;

  RouteChangeNotifier? _mRouteChangeNotifier;
  // var sideMenuCtrl = SideMenuController();

  SideMenuController sideMenuController = SideMenuController();

  AuthAccountRepository mAuthAccountRepository =
      Modular.get<AuthAccountRepository>();

  @override
  void initState() {
    super.initState();
    // mainDestinations = widget.mainDestinations;
    mainDestinations = widget.mainDestinations ?? defaultMainDestinations;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _subscribeBloc();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // dependOnInheritedWidgetOfExactType();
    // Listen to the route changes and call setState when the route changes

    _mRouteChangeNotifier = Provider.of<RouteChangeNotifier>(context);

    _mRouteChangeNotifier?.addListener(_onRouteChanged);

    if (_mRouteChangeNotifier?.currentTab != null) {
      _onRouteChanged();
      // setState(() {

      // });
    }
    // Provider.of<RouteChangeNotifier>(context).addListener(_onRouteChanged);
  }

  @override
  void didUpdateWidget(covariant DashboardSideNavigationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mainDestinations != widget.mainDestinations) {
      // Re-fetch the image URL when the id changes
      // setState(() {
      //   isLoading = true;
      //   hasError = false;
      // });

      print("called 1 . . . . . . . . . . .  . . . . . . . . . . .");

      setState(() {
        mainDestinations = widget.mainDestinations ?? defaultMainDestinations;
      });
    } else if (mainDestinations.isEmpty &&
        (widget.mainDestinations?.length ?? 0) > 0) {
      print("called 2. . . . . . . . . . .  . . . . . . . . . . .");
      setState(() {
        mainDestinations = widget.mainDestinations ?? defaultMainDestinations;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    prepareTheme(context);
    return widget.isMobile
        ? _widgetNavigationDrawerDestinations()
        : _widgetNavigationRail();
    // : Container(color: Colors.amber,);
    //  Container(child: Text(title));
  }

  @override
  void dispose() {
    // Remove the listener when the widget is disposed
    print("#duplicate dispose() key check:");
    // Provider.of<RouteChangeNotifier>(context, listen: false)
    //     .removeListener(_onRouteChanged);

    try {
      _mRouteChangeNotifier?.removeListener(_onRouteChanged);
    } catch (e) {
      print("dashboard side nav state _mRouteChangeNotifier: remove err");
    }
    // _mRouteChangeNotifier?.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _subscribeBloc() {
    // TODO subscribe authAccount
    // _mTopicsSubscription = this._topicsRepository.topicsStateObservable.listen(
    //   (value) {
    //     var destinations = value
    //         .map((e) => DashboardDestination(
    //             label: e.messages.firstOrNull?.question ?? "", id: e.sessionId))
    //         .toList()
    //         .sublist(0, min(value.length, 5));

    //     setState(() {
    //       historyDestinations = destinations;
    //     });
    //   },
    // );
    // this._topicsRepository.getTopics().then((va) {});

    this.mAuthAccountRepository.mAccountUserObservable.listen((value) {
      if(mounted || !context.mounted){

      }
      // var found = setupDestinations.indexWhere((des) {
      //   return des.id == STORE_DESTINATION_ID;
      // });

      // if (found < 0) {
      //   return;
      // }

      // print("mAccountUserObservable: setupDestinations[found].routePath :${setupDestinations[found].routePath}");
    });
  }

  void _onRouteChanged() {
    if (!mounted || !context.mounted) {
      return;
    }
    var currentTab =
        Provider.of<RouteChangeNotifier>(context, listen: false).currentTab;

    print(
      "#duplicate _onRouteChanged key check: ${currentTab} ${selectedNavigation}",
    );
    // selectedNavigation
    var index =
        currentTab != null
            ? onCurrentTabSelected(currentTab) ?? selectedNavigation
            : selectedNavigation;
    setState(() {
      _mCurrentTab = currentTab;
      selectedNavigation = index;
    });
  }

  void _onDestinationSelected(int index) {
    print("_onDestinationSelected index: ${index}");

    // Let the parent handle navigation - don't do it here!
    widget.onDestinationSelected(index);
    
    setState(() {
      selectedNavigation = index;
    });
  }

  int? onCurrentTabSelected(String currentTab) {
    var i = mainDestinations.indexWhere((e) => e.tabName == currentTab);

    if (i < 0) {
      i = setupDestinations.indexWhere((e) => e.tabName == currentTab);

      if (i >= 0) {
        i = i + mainDestinations.length;
      }
    }

    if (i < 0) {
      i = othersDestinations.indexWhere((e) => e.tabName == currentTab);

      if (i >= 0) {
        i = i + mainDestinations.length + setupDestinations.length;
      }
    }

    if (i > 0) {
      return i;
    }
    return null;
  }

  /* **************************************************************************************
 *                                       Widgets
 */

  Widget _widgetNavigationDrawerDestinations() {
    print("crer ------ ${mainDestinations.length}");
    return NavigationDrawer(
      selectedIndex: selectedNavigation,
      onDestinationSelected: (int index) {
        // setState(() {
        //   screenIndex = index;
        // });
        _onDestinationSelected(index);
      },
      children: [
        _header(isDrawer: true),
        // SideMenuItemDataTitle(
        //         title: 'Setup',
        //         titleStyle: TdResTextStyles.h6
        //             .copyWith(color: themeColors.onSurfaceMedium),
        //         padding: EdgeInsetsDirectional.symmetric(
        //             horizontal: TdResDimens.dp_24, vertical: appThemeDisplay.isSamllHeight == false ? TdResDimens.dp_16 : TdResDimens.dp_8),
        //       ),
        Container(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: TdResDimens.dp_24,
            vertical:
                appThemeDisplay.isSamllHeight == false
                    ? TdResDimens.dp_16
                    : TdResDimens.dp_8,
          ),
          child: Text(
            "Main",
            style: TdResTextStyles.h6.copyWith(
              color: themeColors.onSurfaceMedium,
            ),
          ),
        ),
        ...(mainDestinations.map((DashboardDestination destination) {
          return _widgetNavigationDrawerDestinationItem(
            destination: destination,
          );
        }).toList()),

        TdResGaps.line,

        //  SideMenuItemDataTitle(
        //         title: 'Setup',
        //         titleStyle: TdResTextStyles.h6
        //             .copyWith(color: themeColors.onSurfaceMedium),
        //         padding: EdgeInsetsDirectional.symmetric(
        //             horizontal: TdResDimens.dp_24, vertical: appThemeDisplay.isSamllHeight == false ? TdResDimens.dp_16 : TdResDimens.dp_8),
        //       ),
        if (setupDestinations.isNotEmpty)
          Container(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: TdResDimens.dp_24,
              vertical:
                  appThemeDisplay.isSamllHeight == false
                      ? TdResDimens.dp_16
                      : TdResDimens.dp_8,
            ),
            child: Text(
              "Setup",
              style: TdResTextStyles.h6.copyWith(
                color: themeColors.onSurfaceMedium,
              ),
            ),
          ),

        if (setupDestinations.isNotEmpty)
          ...(setupDestinations.map((DashboardDestination destination) {
            return _widgetNavigationDrawerDestinationItem(
              destination: destination,
            );
          }).toList()),

        if (othersDestinations.isNotEmpty) TdResGaps.line,
        if (othersDestinations.isNotEmpty)
          ...(othersDestinations.map((DashboardDestination destination) {
            return _widgetNavigationDrawerDestinationItem(
              destination: destination,
            );
          }).toList()),
      ],
    );
  }

  NavigationDrawerDestination _widgetNavigationDrawerDestinationItem({
    required DashboardDestination destination,
  }) {
    return NavigationDrawerDestination(
      label: Text(destination.label, style: TdResTextStyles.button),
      icon:
          destination.icon != null
              ? Icon(destination.icon, size: TdResDimens.dp_24)
              : SvgPicture.asset(destination.svgDefault),
      selectedIcon:
          destination.selectedIcon != null
              ? Icon(destination.selectedIcon, size: TdResDimens.dp_24)
              : SvgPicture.asset(destination.svgSelected),
    );
  }

  Widget _widgetNavigationRail() {
    var selectedItemColor = Color.alphaBlend(
      themeColors.secondaryColor.withAlpha(0x80),
      themeColors.onSurface,
    );
    var unselectedItemColor = Color.alphaBlend(
      themeColors.secondaryColor.withAlpha(0x60),
      themeColors.onSurfaceMedium,
    );

    return SideMenu(
      controller: sideMenuController,
      mode: SideMenuMode.open,
      minWidth: TdResDimens.dp_72,

resizerData: ResizerData(
resizerWidth: 2,
  resizerHoverColor: Colors.blue,
  resizerColor: themeColors.secondaryColor.withAlpha(0x89)
),


      // backgroundColor: Colors.transparent,
      backgroundColor: Color.alphaBlend(
                  themeColors.secondaryColor.withAlpha(0x32),
                  themeColors.surface,
                ),
      builder: (data) {
        return SideMenuData(
          header: _header(isDrawer: false),
          

          // header: appThemeDisplay.isSamllHeight == false
          //     ? TdResGaps.v_44
          //     : TdResGaps.v_12,
          // spacerAfterItems: Spacer(
          //   flex: 1,
          // ),
          items: [
            SideMenuItemDataTitle(
              title: 'Main',
              titleStyle: TdResTextStyles.h6.copyWith(
                color: themeColors.onSurfaceMedium,
              ),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: TdResDimens.dp_24,
                vertical:
                    appThemeDisplay.isSamllHeight == false
                        ? TdResDimens.dp_16
                        : TdResDimens.dp_8,
              ),
            ),
            ...(mainDestinations
                .asMap()
                .map<int, SideMenuItemDataTile>((index, destination) {
                  return MapEntry(
                    index,
                    _widgetNavigationRailSwitch(
                      0,
                      index,
                      destination,
                      selectedItemColor: selectedItemColor,
                      unselectedItemColor: unselectedItemColor,
                    ),
                  );
                })
                .values
                .toList()),
            if (setupDestinations.isNotEmpty)
              SideMenuItemDataDivider(
                divider: TdResGaps.line,
                padding: EdgeInsetsDirectional.symmetric(
                  vertical:
                      appThemeDisplay.isSamllHeight == false
                          ? TdResDimens.dp_36
                          : TdResDimens.dp_12,
                  horizontal: TdResDimens.dp_4,
                ),
              ),
            if (setupDestinations.isNotEmpty)
              SideMenuItemDataTitle(
                title: 'Setup',
                titleStyle: TdResTextStyles.h6.copyWith(
                  color: themeColors.onSurfaceMedium,
                ),
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: TdResDimens.dp_24,
                  vertical:
                      appThemeDisplay.isSamllHeight == false
                          ? TdResDimens.dp_16
                          : TdResDimens.dp_8,
                ),
              ),
            if (setupDestinations.isNotEmpty)
              ...(setupDestinations
                  .asMap()
                  .map<int, SideMenuItemDataTile>((index, destination) {
                    return MapEntry(
                      index,
                      _widgetNavigationRailSwitch(
                        mainDestinations.length,
                        index,
                        destination,
                        selectedItemColor: selectedItemColor,
                        unselectedItemColor: unselectedItemColor,
                      ),
                    );
                  })
                  .values
                  .toList()),

            // SideMenuItemDataTitle(title: 'Main', titleStyle: TdResTextStyles.h6),
            // SideMenuItemDataDivider(divider: TdResGaps.line),
            if (othersDestinations.isNotEmpty)
              SideMenuItemDataDivider(
                divider: TdResGaps.line,
                padding: EdgeInsetsDirectional.symmetric(
                  vertical:
                      appThemeDisplay.isSamllHeight == false
                          ? TdResDimens.dp_36
                          : TdResDimens.dp_12,
                  horizontal: TdResDimens.dp_4,
                ),
              ),

            if (othersDestinations.isNotEmpty)
              ...(othersDestinations
                  .asMap()
                  .map<int, SideMenuItemDataTile>((index, destination) {
                    return MapEntry(
                      index,
                      _widgetNavigationRailSwitch(
                        mainDestinations.length + setupDestinations.length,
                        index,
                        destination,
                        selectedItemColor: selectedItemColor,
                        unselectedItemColor: unselectedItemColor,
                      ),
                    );
                  })
                  .values
                  .toList()),
          ],
        );
      },
    );
  }

  SideMenuItemDataTile _widgetNavigationRailSwitch(
    int offsetIndex,
    int index,
    DashboardDestination destination, {

    Color selectedItemColor = Colors.red,
    //   = Color.alphaBlend(
    //   themeColors.secondaryColor.withAlpha(0x80),
    //   themeColors.onSurface,
    // ),
    Color unselectedItemColor = Colors.black54,
  }) {
    return SideMenuItemDataTile(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TdResDimens.dp_24),
        color:
            (selectedNavigation - offsetIndex) == index
                ? themeColors.secondaryColor.withAlpha(0x22)
                : null,
      ),

      borderRadius: BorderRadius.circular(TdResDimens.dp_24),
      // label: Text(destination.label),
      isSelected:
          destination.tabName != null && _mCurrentTab != null
              ? _mCurrentTab == destination.tabName
              : (selectedNavigation - offsetIndex) == index,
      icon: Container(
        alignment: Alignment.center,
        child:
            destination.selectedIcon != null
                ? Icon(
                  destination.icon,
                  size: TdResDimens.dp_24,

                  color: unselectedItemColor,
                )
                : SvgPicture.asset(
                  destination.svgDefault,
                  colorFilter: ColorFilter.mode(
                    unselectedItemColor,
                    BlendMode.srcIn,
                  ),
                  width: TdResDimens.dp_24,
                ),
      ),
      selectedIcon: Container(
        alignment: Alignment.center,
        child:
            destination.selectedIcon != null
                ? Icon(
                  destination.selectedIcon,
                  color: selectedItemColor,
                  size: TdResDimens.dp_24,
                )
                : SvgPicture.asset(
                  colorFilter: ColorFilter.mode(
                    selectedItemColor,
                    BlendMode.srcIn,
                  ),
                  // color: themeColors.primaryHigh,
                  destination.svgSelected,
                  width: TdResDimens.dp_24,
                ),
      ),

      title: destination.label,
      titleStyle: TdResTextStyles.h5.copyWith(color: unselectedItemColor),

      selectedTitleStyle: TdResTextStyles.button.copyWith(color: selectedItemColor),
      hasSelectedLine: false,
      itemHeight: TdResDimens.dp_44,
      margin: EdgeInsetsDirectional.symmetric(
        vertical:
            appThemeDisplay.isSamllHeight == false
                ? TdResDimens.dp_8
                : TdResDimens.dp_4,
        horizontal: TdResDimens.dp_6,
      ),

      onTap: () {
        _onDestinationSelected(index + offsetIndex);
        // widget.onDestinationSelected(index + offsetIndex);
      },
    );
  }

  Widget _header({bool isDrawer = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        isDrawer
            ? appThemeDisplay.isSamllHeight == false
                ? TdResGaps.v_44
                : TdResGaps.v_12
            : SizedBox.shrink(),
        isDrawer
            ? Container(
              margin: const EdgeInsets.symmetric(
                horizontal: TdResDimens.dp_24,
                vertical: TdResDimens.dp_12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 40,
                    // width: 120,
                    alignment: Alignment.centerLeft,

                    constraints: BoxConstraints(maxWidth: 120),
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      // borderRadius: BorderRadius.circular(16.0),
                      // color: themeColors.onSurface.withAlpha(0x06),
                      image: DecorationImage(
                        image: AssetImage("assets/img/Dhara.png"),
                        fit: BoxFit.fitHeight,
                        alignment: Alignment.centerLeft,

                        colorFilter: ColorFilter.mode(
                          themeColors.secondaryColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),

                    // ),
                  ),
                  // Container(
                  //   height: 48,
                  //   width: 48,
                  //   margin: const EdgeInsets.all(12),
                  //   padding: const EdgeInsets.all(6),
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(16.0),
                  //     color: themeColors.onSurface.withOpacity(0.04),
                  //   ),
                  //   child: SvgPicture.asset(
                  //     "assets/svg/logo/meal_relay_colored.svg",
                  //   ),
                  //   // ),
                  // ),
                  // // Container(
                  // //   height: TdResDimens.dp_48,
                  // //   child: Image.asset("assets/img/pic_onboard.png"),
                  // // ),
                  TdResGaps.h_16,
                  Expanded(
                    flex: 1,
                    child: Text(
                      "",
                      maxLines: 1,
                      textAlign: TextAlign.start,
                      style: TdResTextStyles.h3,
                    ),
                  ),

                  // Flex(direction: direction)
                ],
              ),
            )
            : const SizedBox.square(),
        appThemeDisplay.isSamllHeight == false
            ? TdResGaps.v_24
            : TdResGaps.v_12,
      ],
    );
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
}

class DashboardDestination {
  DashboardDestination({
    required this.label,
    this.svgSelected = "",
    this.svgDefault = "",
    this.selectedIcon,
    this.icon,
    this.routePath,
    this.id,
    this.tabName,
  });

  final String? id;

  String? routePath;
  final String? tabName;

  final String label;
  final IconData? icon;
  final String svgSelected;
  final String svgDefault;
  final IconData? selectedIcon;
}
