import 'package:dharak_flutter/app/core_module.dart';
import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/app/ui/labs/labs_module.dart';
import 'package:dharak_flutter/app/ui/pages/auth/login_page.dart';
import 'package:dharak_flutter/app/ui/pages/onboarding/onboarding_page.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/controller.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/dashboard_args.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/dashboard_page.dart';
import 'package:dharak_flutter/app/ui/pages/splash/splash_page.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/module.dart';
import 'package:dharak_flutter/app/ui/pages/verses/module.dart';
import 'package:dharak_flutter/app/ui/pages/words/module.dart';
import 'package:dharak_flutter/core/pages/enhanced_quicksearch_page.dart';
import 'package:dharak_flutter/core/pages/unified_page.dart';
import 'package:dharak_flutter/flavors.dart';
// import 'package:dio/dio.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:provider/provider.dart';
import 'package:dharak_flutter/app/ui/providers/active_section_provider.dart';
// import 'package:agribot_flutter/app/ui/labs/labs_module.dart';

class AppModule extends Module {
  @override
  void binds(i) {
    i.addSingleton(DashboardController.new);
    // UiAuthBinds.bindControllers(i);
    // i.addSingleton(() => SecureLocalData());
    // // i.addSingleton(() => DioCreator.new);
    // // i..

    // i.addSingleton(() => DioCreator(storage: i<SecureLocalData>()).getDio());
    // // i.addSingleton( i.get<DioCreator>().getDio);
    // i.addSingleton(() => AuthApiPoint(i<Dio>(), baseUrl: F.apiUrl));
    // i.addSingleton(() => AuthApiRepo(apiPoint: i<AuthApiPoint>()));

    // i.addSingleton(() => AuthAccountRepository(
    //     mAuthApiRepo: i<AuthApiRepo>(), mSecureStorage: i<SecureLocalData>()));

    // i.addSingleton(() => AudioWebSocketRepo(
    //     authApiRepo: i<AuthApiRepo>(),
    //     storage: i<SecureLocalData>(),
    //     baseUrl: F.webSocketUrl));
    // i.addSingleton(() => MicrophoneHandler());

    // // i.addSingleton( i.get<DioCreator>().getDio);
    // i.addSingleton(() => ChatMessageApiPoint(i<Dio>(), baseUrl: F.apiUrl));
    // i.addSingleton(
    //     () => ChatMessageApiRepo(apiPoint: i<ChatMessageApiPoint>()));

    // i.addSingleton(() => HistoryApiPoint(i<Dio>(), baseUrl: F.apiUrl));
    // i.addSingleton(() => HistoryApiRepo(apiPoint: i<HistoryApiPoint>()));

    // i.addSingleton(() => ChatRepository(
    //     mHistoryApiRepo: i<HistoryApiRepo>(),
    //     mChatMessageApiRepo: i<ChatMessageApiRepo>()));
    // i.addSingleton(
    //     () => TopicsRepository(mHistoryApiRepo: i<HistoryApiRepo>()));

    // i.addSingleton(constructor)
  }

  // @override
  // void exportedBinds(Injector i) {
  //   // TODO: implement exportedBinds
  //   super.exportedBinds(i);
  // }

  @override
  List<Module> get imports => [CoreModule()];

  @override
  void routes(r) {
    // r.child('/', child: (context) => AppDefaultPage());
    // r.child('/', child: (context) => LabsModule());

    var path = F.dashboardDefaultRoutePath;

    var dashboardPath = '/';
    // var topicPath = '/topics';
    if (F.APP_FLAVOR != Flavor.FINALE_RELEASE) {
      r.module('/labs', module: LabsModule());
    }

    // Onboarding route
    r.child('/onboarding', child: (context) => const OnboardingPage());
    
    // Login route
    r.child('/login', child: (context) => const LoginPage());
    
    if (path.isEmpty ) {
      dashboardPath = "/${UiConstants.Routes.dashboardDefault}"; //'/home';
      r.child('/',  child: (context) => const SplashPage());
    } else {
      // dashboardPath
      dashboardPath = '/$path';
      r.module('/', module: LabsModule());
    }

    print("dashboardPath:  ${dashboardPath}");
    // r.child('/', child: (context) => AppDefaultPage());

    r.child(
      dashboardPath,
      child: (context) => ChangeNotifierProvider<ActiveSectionProvider>(
        create: (_) => ActiveSectionProvider()..setActiveSection('unified'),
        child: DashboardPage(
          mRequestArgs: DashboardArgsRequest(default1: "default1"),
        ),
      ),
      children: [
        ChildRoute('/', child: (_) => const EnhancedQuickSearchPage()), // Default route to QuickSearch
        ChildRoute('/quicksearch', child: (_) => const EnhancedQuickSearchPage()),
        ModuleRoute('/prashna', module: PrashnaModule()),
        ChildRoute('/unified', child: (_) => const UnifiedPage()),
        ModuleRoute('/word-define', module: WordDefineModule()),
        ModuleRoute('/verses', module: VersesModule()),
      ],
    );
    // r.wildcard(child: child)
    // r.child(dashboardPath, child: (context) => DashboardPage(),
    // children: [
    //   // ChildRoute('/', child: (_) => AppDefaultPage()),
  }
}
