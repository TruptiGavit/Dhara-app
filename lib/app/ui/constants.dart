

import 'package:dharak_flutter/flavors.dart';

class UiConstants {
  static const _Routes Routes = const _Routes();

  static const _Tabs Tabs = const _Tabs();
  static const _RequestCodes RequestCodes = const _RequestCodes();
  static const int REQUEST_CODE_DEFAULT = _RequestCodes.DEFAULT;
  static const _BundleArgs BundleArgs = const _BundleArgs();
}

class _Tabs {
  const _Tabs();


  final String wordDefine = '/word-define';
  final String verse = '/verse';
  final String quicksearch = '/quicksearch';
  final String unified = '/unified';
  final String prashna = '/prashna';

  final TABS_LABEL = const <String, String>{
    "/word-define": "WordDefine",
    "/verse": "QuickVerse", 
    "/quicksearch": "Shodh (शोध)",
    "/unified": "Unified",
    "/prashna": "Prashna (प्रश्न)"
  };

  // final String dashboradTopicCreate = '/dashboard/topics/create';
}

class _Routes {
  const _Routes();

  final String dashboardDefault = 'Dhara';
  final String splash = '/splash/';

  final String landing = '/landing/';


  final String verse = '/verses';
  final String wordDefine = '/word-define';
  final String quicksearch = '/quicksearch';
  final String unified = '/unified';
  final String prashna = '/prashna';

  // final String onboard = '/onboard/';

  
  // TODO remove in future
  // final String dashboradTopicCreate = '/dashboard/topics/create';
  // final String dashboradTopics = '/dashboard/topics';

  final String notifications = '/notifications/';

  // final String home = '/home/';
  // final String homeDetails = '/home/details/';
  // final String homeAnalysis = '/home/analysis/';
  // final String homeTransactions = '/home/transactions/';
  // final String homeAccount = '/home/account/';


  final String about = '/about/';

// PhoneLoginWidget

  final String dialogAuth = "/dialog/auth";

  

  final String dialogLoginEmail= "/dialog/login/email";

  final String dialogAlert = "/dialog/alert";
  final String dialogProgress = "/dialog/progress";

  final String labs = "/labs";
  final String labsDashboard = "/labs/dashboard";
  final String labsEditor = "/labs/editor";
  final String labsDashboardPage1 = "/page1";
  final String labsDashboardPage2 = "/page2";
  final String labsOnboard = "/labs/onboards";
  final String labsAuth = "/labs/auth";
  final String labsCommon = "/labs/common";
  final String labsAccount = "/labs/account";
  final String labsCommonMedia = "/labs/common/media";
  final String labsNotification = "/labs/notification";

  String getRoutePath(route) {
    var path = F.dashboardDefaultRoutePath;

    if (path.isNotEmpty) {
      var routePath = '/$path$route';
      print("getRoutePath: ${routePath}");
      return routePath;
    }

    var routePath = '/${dashboardDefault}$route';
      print("getRoutePath else: ${routePath}");
      return routePath;
  }

  //
  final String TRASH = '/trash';
}

class _RequestCodes {
  const _RequestCodes();

  static const int DEFAULT = 0;
  final int tagsSearch = 101;
}

class _BundleArgs {
  const _BundleArgs();
  final String argResultCode = 'resultCode';
  final String argRequestCode = 'requestCode';
  final String argData = 'data';
  final String argMessage = 'message';

  final int resultSuccess = 0x10;
  final int resultCanceled = 0x02;
  final int resultFailed = 0x01;
  // final String argDataChatThread = 'chatThread';

  // final String argDataIsChanged = 'isChanged';
  // final String argDataIsRemoved = 'isRemoved';

  // final String argDataPiece = 'piece';
  // final String argDataTitle = 'title';
  // final String argDataCollection = "collection";

  ///  used inside web
  // final String argDataPageUrl = "pageUrl";
  // final String argDataPageIsMinimal = "isMinimalUi";

  // final String argDataNotificationAction = "notificationAction";
}
