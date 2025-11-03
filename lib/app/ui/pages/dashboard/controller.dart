import 'dart:async';

// import 'package:common/app/domain/base/domain_result.dart';
// import 'package:common/app/domain/domain.dart';
// import 'package:common/app/types/types.dart';
import 'package:dharak_flutter/app/data/remote/api/interceptors/auth_interceptor.dart';
import 'package:dharak_flutter/app/domain/auth/auth_account_repo.dart';
import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/domain/dictionary/repo.dart';
import 'package:dharak_flutter/app/domain/verse/repo.dart';
import 'package:dharak_flutter/core/services/verse_service.dart';
import 'package:dharak_flutter/core/services/dictionary_service.dart';
import 'package:dharak_flutter/core/services/unified_service.dart';
import 'package:dharak_flutter/app/types/user/user.dart';
import 'package:dharak_flutter/app/types/verse/language_pref.dart';
import 'package:dharak_flutter/app/domain/verse/constants.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/cubit_states.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/dashboard_args.dart';
// import 'package:common/app/types/account/account_common.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
// import 'package:mithai_vendor/app/ui/pages/dashboard/cubit_states.dart';
// import 'package:mithai_vendor/app/ui/pages/dashboard/dashboard_args.dart';

class DashboardController extends Cubit<DashboardCubitState> {

  final VerseRepository mVersesRepo;

  final DictionaryRepository mDictionaryRepository;
  // final VendorsRepository mVendorsRepo;

  final AuthAccountRepository mAuthAccountRepository;
  final AuthInterceptor mAuthInterceptor;
  // StoreRepository mStoreRepo = Modular.get<StoreRepository>();

  StreamSubscription<bool>? _mLoginSubscription;
  StreamSubscription<UserRM?>? _mAccountCommonSubscription;

  StreamSubscription<VersesLanguagePrefRM?>? _mVerseLanguagePrefSubscription;
  DashboardController({
    required this.mAuthAccountRepository,
    required this.mVersesRepo,
    required this.mDictionaryRepository,
    required this.mAuthInterceptor,
  }) : super(
         DashboardCubitState(
           // isLoading: true,
           // state: AuthRootUiConstants.STATE_DEFAULT,
           // purpose: AuthEmailUiConstants.STATE_DEFAULT
         ),
       ) {
    // Immediately set up subscriptions and load language preference
    _subscribeBloc();
    _loadLanguagePreferenceImmediately();
  }

  @override
  Future<void> close() {
    _mAccountCommonSubscription?.cancel();

    _mVerseLanguagePrefSubscription?.cancel();
    try {
      _mLoginSubscription?.cancel();
      _mLoginSubscription = null;
    } catch (e) {
    }

    // _mSearchOnChange.close();
    // _mEventRefresh.close();
    // _mEventMessage.close();
    // _mEventActionProgress.close();
    // _mEventNewChatMessage.close();
    return super.close();
  }

  Future<void> initData(DashboardArgsRequest args) async {
    // mCommuneId = args.communeId;
    // // _onTalesDetail(args!.tale!);
    // var communeBanker = args.communeBanker ?? await _getMyCommuneBanker(emit);
    // if (communeBanker != null) {

    // }

    // var uiState = state.state;
    // if (args.purpose == AuthRootUiConstants.PURPOSE_JOIN) {
    //   uiState = AuthRootUiConstants.STATE_SELECTOR;
    // } else if (args.purpose == AuthRootUiConstants.PURPOSE_GOOGLE_REDIRECT ||
    //     args.purpose == AuthRootUiConstants.PURPOSE_NONE) {
    //   uiState = AuthRootUiConstants.STATE_DEFAULT;
    // } else {
    //   uiState = AuthRootUiConstants.STATE_MODAL;
    // }

    // initSetup();

    // Subscribe to streams FIRST, then load data
    _subscribeBloc();
    
    await _load();
    emit(
      state.copyWith(
        // purpose: args.purpose,
        isInitialized: true,
        // state: uiState,
        isLoading: false,
      ),
    );

    // _mEventRefresh.sink.add(true);
  }

  initSetup() {
    mAuthAccountRepository.initSetup();

    _mLoginSubscription = mAuthAccountRepository.onGoogleWebLoggedIn.listen((
      onData,
    ) {
      if (onData) {
        // _getGoogleIdToken();

        emit(
          state.copyWith(
            googleWebLoggedInCounter: state.googleWebLoggedInCounter + 1,
          ),
        );
      }
    });
  }

  void setAuthPopupState(bool authPopupOpen) {
    emit(state.copyWith(authPopupOpen: authPopupOpen));
  }

  void _subscribeBloc() {
    
    // Prevent double subscription
    if (_mVerseLanguagePrefSubscription != null) {
      return;
    }
    
    _mAccountCommonSubscription = mAuthAccountRepository.mAccountUserObservable
        .listen((value) {
          if (state.user != value) {
            emit(state.copyWith(user: value));
          }

          print("DashboardController _subscribeBloc: 3");
        });

    mAuthInterceptor.eventLoginNeeded.listen((value) {
      print("eventLoginNeeded:${value}");
      emit(state.copyWith(loginNeededCounter: state.loginNeededCounter + 1));
    });

    _mVerseLanguagePrefSubscription = mVersesRepo.mLanguagePrefObservable
        .listen((value) {
          print("🎯 DashboardController _subscribeBloc: Received language pref: ${value?.output}");
          print("🎯 DashboardController _subscribeBloc: Before emit - current state: ${state.verseLanguagePref?.output}");
          emit(state.copyWith(verseLanguagePref: value));
          print("🎯 DashboardController _subscribeBloc: After emit - new state: ${state.verseLanguagePref?.output}");
        });
  }

  void onTabChanged(String? currentTab) {
    emit(state.copyWith(currentTab: currentTab));
  }

  Future<void> onClickLogout() async {
    await mAuthAccountRepository.logout();
  }

  Future<void> onClickSwitchAccount() async {
    await mAuthAccountRepository.switchAccount();
    // Navigation will be handled by the BlocListener in DashboardPage
    // when the user state changes to null
  }

  void onNewSearchQuery(bool isForVerse, String? searchQuery) {
    if (isForVerse) {
      mVersesRepo.onNewSearchQuery(searchQuery);
    } else {
      mDictionaryRepository.onNewSearchQuery(searchQuery);
    }
  }

  Future<void> onVerseLanguageChange(String languageOutput) async {
    print("🎯 DashboardController onVerseLanguageChange: Changing language to $languageOutput");
    
    try {
      var result = await mVersesRepo.getlanguagePref(output: languageOutput);
      
      if (result.status == DomainResultStatus.SUCCESS) {
        print("✅ DashboardController onVerseLanguageChange: Language changed successfully to ${result.data?.output}");
        print("🎯 DashboardController onVerseLanguageChange: Repository will emit via stream, no manual emit needed");
        
        // Clear relevant caches to ensure fresh results
        _clearSearchCaches();
        
        // Note: State update will happen automatically via _mVerseLanguagePrefSubscription listener
        // This eliminates the race condition between manual emit and repository stream
        
      } else {
        print("❌ DashboardController onVerseLanguageChange: Failed to change language - ${result.message}");
      }
    } catch (e) {
      print("💥 DashboardController onVerseLanguageChange: Exception - $e");
    }
  }

  /// Clear search caches when language changes to ensure fresh results
  void _clearSearchCaches() {
    try {
      // Clear verse cache
      final verseService = VerseService.instance;
      verseService.clearCache();
      print("🗑️ DashboardController: Cleared verse cache for language change");
      
      // Clear dictionary cache
      final dictionaryService = DictionaryService.instance;
      dictionaryService.clearCache();
      print("🗑️ DashboardController: Cleared dictionary cache for language change");
      
      // Clear unified cache
      final unifiedService = UnifiedService.instance;
      unifiedService.clearCache();
      print("🗑️ DashboardController: Cleared unified cache for language change");
      
    } catch (e) {
      print("⚠️ DashboardController: Error clearing caches - $e");
    }
  }

  /* **************************************************************************************
   *                                      domain 
   */

  /// Immediate language preference loading (called from constructor)
  void _loadLanguagePreferenceImmediately() {
    print("🔥 DashboardController: _loadLanguagePreferenceImmediately called");
    
    // First check if repository already has a cached language preference
    try {
      if (mVersesRepo.mLanguagePrefObservable.hasValue && mVersesRepo.mLanguagePrefObservable.value != null) {
        final cachedPref = mVersesRepo.mLanguagePrefObservable.value!;
        print("🔥 DashboardController: Found cached language preference: ${cachedPref.output}");
        emit(state.copyWith(verseLanguagePref: cachedPref));
        return;
      }
    } catch (e) {
      print("⚠️ DashboardController: Error checking cached preference: $e");
    }
    
    // If no cached preference, load from API asynchronously
    print("🔥 DashboardController: No cached preference, loading from API...");
    _load().catchError((e) {
      print("💥 DashboardController: Error in immediate load: $e");
      // Set a default if loading fails
      _setDefaultLanguagePreference();
    });
  }

  /// Set default language preference if loading fails
  void _setDefaultLanguagePreference() {
    print("🔥 DashboardController: Setting default language preference to Devanagari");
    final defaultPref = VersesLanguagePrefRM(
      output: VersesConstants.LANGUAGE_DEFAULT,
      // Add other required fields if needed
    );
    emit(state.copyWith(verseLanguagePref: defaultPref));
  }

  _load() async {
    print("🎯 DashboardController _load: Loading initial language preference...");
    try {
      var result = await mVersesRepo.getlanguagePref();
      print("🎯 DashboardController _load: Initial language result: ${result.data?.output}");
      
      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        print("🎯 DashboardController _load: Setting initial language preference: ${result.data?.output}");
        emit(state.copyWith(verseLanguagePref: result.data));
      } else {
        print("❌ DashboardController _load: Failed to load initial language preference - ${result.message}");
        _setDefaultLanguagePreference();
      }
    } catch (e) {
      print("💥 DashboardController _load: Exception loading language preference: $e");
      _setDefaultLanguagePreference();
    }
  }

  /* *****************************************************************************
   *                              Form
   */
}
