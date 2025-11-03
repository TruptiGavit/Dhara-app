// import 'package:agribot_flutter/common.dart';

import 'package:dharak_flutter/app/tools/route/route_change_notifier.dart';
import 'package:dharak_flutter/app/tools/route/route_observer_callback.dart';
import 'package:dharak_flutter/flavors.dart';
import 'package:dharak_flutter/res/theme/app_theme.dart';
import 'package:dharak_flutter/res/values/colors.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_modular/flutter_modular.dart';
import 'package:logger/logger.dart';
// import 'package:agribot_flutter/app/res/values/colors.dart';
// import 'package:agribot_flutter/flavors.dart';
// import 'app_controller.dart';
// import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:provider/provider.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({
    super.key,
    this.isTestMode = false,
  });

  final bool isTestMode;

  // const AppWidget({Key? key, this.title = "Home"}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Modular.get<FcmService>();

    // if(mPayload!=null){
    //   Modular.setArguments(mPayload);
    // Modular.setInitialRoute(UiConstants.Routes.home);//F.indexRoute);
    // }else{
    //       Modular.setInitialRoute(F.indexRoute);
    // }

    print("MyApp");
    // return
    // ChangeNotifierProvider<AppThemeProvider>(
    //     create: (_) =>
    //         AppThemeProvider(defaultColor: TdResColors.colorPrimary40),
    //     child: ChangeNotifierProvider<RouteChangeNotifier>(
    //         create: (_) => RouteChangeNotifier(), child: ThemedApp()));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppThemeProvider>(
            create: (_) => AppThemeProvider(
                defaultColor: TdResColors.colorPrimary40,
                defaultThemeMode: ThemeMode.light)),
        ChangeNotifierProvider<RouteChangeNotifier>(
            create: (_) => RouteChangeNotifier())
      ],
      child: ThemedApp(),
    );
  }
}

class ThemedApp extends StatelessWidget {
  // const

  // ThemedApp({super.key});
  // final _appRouter = AppRouter();

  ThemedApp({super.key});

  var mLogger = Logger();
  @override
  Widget build(BuildContext context) {
    final appThemeProvider = Provider.of<AppThemeProvider>(context);

    Modular.setInitialRoute(F.indexRoute);
    Modular.setObservers([
      RouteObserverWithCallback(
        onRouteChanged: (route, previousRoute) {
          // Notify the provider about the route change
          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              // print("setObserver route.settings.name: ${route.settings.name} ${previousRoute?.settings.name}");
              Provider.of<RouteChangeNotifier>(context, listen: false)
                  .updateRoute(route.settings.name ?? '');
            },
          );
        },
      )
    ]);

    // print(
    //     "appThemeProvider.seedColor: ${appThemeProvider.seedColor.computeLuminance()}");
    // WidgetsBinding.instance
    //     .addPostFrameCallback((_) => setState(() {}));
    // Modular
    // TODO bug for labs
    // mLogger.f("initState ThemedApp ${F.indexRoute} ${Modular.initialRoute}");
    return MaterialApp.router(
      routeInformationParser: Modular.routeInformationParser,

      // routeInformationProvider: Modular.pro,
      routerDelegate: Modular.routerDelegate,

      // routerConfig: Modular.routerConfig,
      title: 'Dhara',

      themeMode: appThemeProvider.themeMode,

      // localizationsDelegates: const [
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      // supportedLocales: const [
      //   Locale('en', ''),
      // ],
      theme: AppTheme.themeData(seedColor: appThemeProvider.seedColor)
          .copyWith(extensions: <ThemeExtension<dynamic>>[
        AppThemeColors.seedColor(
            seedColor: appThemeProvider.seedColor,
            secondaryLight: TdResColors.colorSecondary80,
            secondaryColor: TdResColors.colorSecondary70,
            isDark: false)
      ]),
      //appThemeProvider.seedColor
      darkTheme: AppTheme.themeData(
              seedColor: HSLColor.fromColor(appThemeProvider.seedColor)
                  .withLightness(0.4)
                  .toColor(),
              isDark: true)
          .copyWith(extensions: <ThemeExtension<dynamic>>[
        AppThemeColors.seedColor(
            seedColor: HSLColor.fromColor(appThemeProvider.seedColor)
                .withLightness(0.4)
                .toColor(), // appThemeProvider.seedColor,
            secondaryLight: TdResColors.colorSecondary20,
            secondaryColor: TdResColors.colorSecondary30,
            isDark: true)
      ]),
      // theme: AppTheme.lightThemeData
      //     .copyWith(platform: AppThemeOptions.of(context).platform),
      // darkTheme: AppTheme.darkThemeData.copyWith(
      //   platform: AppThemeOptions.of(context).platform,
      // ),
    );
  }
}