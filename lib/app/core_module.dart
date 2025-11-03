import 'package:dharak_flutter/app/data/local/secure/secure_local_data.dart';
import 'package:dharak_flutter/app/data/remote/api/base/dio_creator.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/auth/api.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/dictionary/api.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/dictionary/api_point.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/verse/api.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/verse/api_point.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/citation/api.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/citation/api_point.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/share/api.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/share/api_point.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/prashna/api.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/prashna/api_point_simple.dart';
import 'package:dharak_flutter/app/domain/auth/auth_account_repo.dart';
import 'package:dharak_flutter/app/domain/prashna/repo.dart';
import 'package:dharak_flutter/app/data/services/developer_mode_service.dart';
import 'package:dharak_flutter/app/domain/dictionary/repo.dart';
import 'package:dharak_flutter/app/domain/verse/repo.dart';
import 'package:dharak_flutter/app/domain/books/repo.dart';
import 'package:dharak_flutter/app/providers/google/google_auth.dart';
import 'package:dharak_flutter/app/ui/sections/auth/auth.dart';
import 'package:dharak_flutter/app/ui/sections/history/ui_bind.dart';
import 'package:dharak_flutter/app/ui/sections/verses/ui_bind.dart';
import 'package:dharak_flutter/app/ui/sections/books/ui_bind.dart';
import 'package:dharak_flutter/core/cache/smart_search_cache.dart';
import 'package:dharak_flutter/core/controllers/quicksearch_controller.dart';
import 'package:dharak_flutter/core/controllers/unified_controller.dart';
import 'package:dharak_flutter/core/services/dictionary_service.dart';
import 'package:dharak_flutter/core/services/verse_service.dart';
import 'package:dharak_flutter/core/services/books_service.dart';
import 'package:dharak_flutter/core/services/unified_service.dart';
import 'package:dharak_flutter/app/data/services/citation_service.dart';
import 'package:dharak_flutter/app/data/services/share_service.dart';
import 'package:dharak_flutter/app/domain/citation/repo.dart';
import 'package:dharak_flutter/app/domain/share/repo.dart';
import 'package:dharak_flutter/core/services/citation_share_service.dart';
import 'package:dharak_flutter/flavors.dart';
import 'package:dio/dio.dart';
import 'package:flutter_modular/flutter_modular.dart';
// import 'package:agribot_flutter/app/ui/pages/landing/landing_module.dart';
// import 'package:agribot_flutter/app/ui/pages/store/module.dart';
// import 'package:storefront/ui/app/app_default_page.dart';
// import 'package:storefront/ui/labs/labs_page.dart';

// import 'modules/home/home_module.dart';

class CoreModule extends Module {
  @override
  void exportedBinds(i) {
    // UiAuthBinds.bindControllers(i);
    i.addSingleton(() => SecureLocalData());
    i.addSingleton(() => GoogleAuthService());

    i.addSingleton(DioCreator.new);
    i.addSingleton(() => i<DioCreator>().getDio());
    i.addSingleton(() => i<DioCreator>().getAuthInterceptor());

    // i.addSingleton(() => DioCreator(storage: i<SecureLocalData>(), fbAuthService: i<FbAuthService>()).getDio());
    // // i.addSingleton( i.get<DioCreator>().getDio);
    // i.addSingleton(() => AuthApiPoint(i<Dio>(), baseUrl: F.apiUrl));
    // i.addSingleton(() => AuthApiRepo(apiPoint: i<AuthApiPoint>()));

    // i.addSingleton(AuthAccountRepository.new);


    i.addSingleton(() => AuthApiPoint(i<Dio>(), baseUrl: F.apiUrl));
    i.addSingleton(() => AuthApiRepo(apiPoint: i<AuthApiPoint>()));

    i.addSingleton(() => DictionaryApiPoint(i<Dio>(), baseUrl: F.apiUrl));
    i.addSingleton(() => DictionaryApiRepo(apiPoint: i<DictionaryApiPoint>()));

    
    i.addSingleton(() => VerseApiPoint(i<Dio>(), baseUrl: F.apiUrl));
    i.addSingleton(() => VerseApiRepo(dio: i<Dio>(), baseUrl: F.apiUrl, apiPoint: i<VerseApiPoint>()));

    i.addSingleton(() => CitationApiPoint(i<Dio>(), baseUrl: F.apiUrl));
    i.addSingleton(() => CitationApiRepo(apiPoint: i<CitationApiPoint>()));

    i.addSingleton(() => ShareApiPoint(i<Dio>(), baseUrl: F.apiUrl));
    i.addSingleton(() => ShareApiRepo(apiPoint: i<ShareApiPoint>()));

    i.addSingleton(() => PrashnaApiPointSimple(dio: i<Dio>(), baseUrl: F.apiUrl));
    i.addSingleton(() => PrashnaApiRepo(apiPoint: i<PrashnaApiPointSimple>()));

    i.addSingleton(AuthAccountRepository.new);

    i.addSingleton(DictionaryRepository.new);
    i.addSingleton(VerseRepository.new);
    i.addSingleton(PrashnaRepository.new);
    
    // Books repository
    i.addSingleton(() => BooksRepositoryImpl(mDio: i<Dio>()));
    i.addSingleton<BooksRepository>(() => i<BooksRepositoryImpl>());

    // Initialize DeveloperModeService
    i.addSingleton(() => DeveloperModeService.instance);

    // New optimized services (singletons for global access)
    i.addSingleton(() => SmartSearchCache.instance);
    i.addSingleton(() => DictionaryService.instance);
    i.addSingleton(() => VerseService.instance);
    i.addSingleton(() => BooksService.instance);
    i.addSingleton(() => UnifiedService.instance);
    i.addSingleton(() => CitationService(i<CitationApiRepo>()));
    i.addSingleton(() => ShareService(shareApiRepo: i<ShareApiRepo>()));
    i.addSingleton(() => CitationRepository(i<CitationService>()));
    i.addSingleton(() => ShareRepository(shareApiRepo: i<ShareApiRepo>()));
    i.addSingleton(() => CitationShareService.instance);
    i.addSingleton(QuickSearchController.new);
    i.add(UnifiedController.new);

    UiAuthBinds.bindControllers(i);
    UiHistoryBinds.bindControllers(i);
    UiVerseBinds.bindControllers(i);
    UiBooksBinds.bindControllers(i);
    // i.addSingleton(constructor)
  }
}
