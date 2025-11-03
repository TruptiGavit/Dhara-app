

import 'package:dharak_flutter/config/env.dart';
import 'package:dharak_flutter/config/environments/development.dart';
import 'package:dharak_flutter/config/environments/development_n.dart';
import 'package:dharak_flutter/config/environments/final_release.dart';

enum Flavor {
  DEVELOPMENT,
  DEVELOPMENT_N,
  DEVELOPMENT_R,
  FINALE_RELEASE,
}

class F {
  static Env ENV = EnvFinalRelase();
  static Flavor _sAppFlavor = Flavor.DEVELOPMENT;

  static Flavor get APP_FLAVOR => _sAppFlavor;
  static set appFlavor(Flavor flavor) {
    _sAppFlavor = flavor;
    if (flavor == Flavor.DEVELOPMENT) {
      ENV = EnvDevelopment();
    } else if (flavor == Flavor.FINALE_RELEASE) {
      ENV = EnvFinalRelase();
    } else {
      ENV = EnvDevelopmentN();
    }
    print("ENV: $ENV");
  }

  static String get indexRoute {
    return ENV.indexRoute;
  }

  static String get title {
    return ENV.title;
  }

  static String get apiUrl {
    return ENV.apiUrl;
  }

  static String get dashboardDefaultRoutePath {
    return ENV.dashboardDefaultPath;
  }

  static String get googleSignInClientIdAndroid {
    return ENV.googleSignInClientIdAndroid;
  }
  // static String get imagekitPublicKey => ENV.imagekitPublicKey;

  // static String get imagekitRootFolder => ENV.imagekitRootFolder;
}
