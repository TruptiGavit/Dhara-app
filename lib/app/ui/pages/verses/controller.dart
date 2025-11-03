import 'dart:async';

// import 'package:common/app/domain/base/domain_result.dart';

import 'package:dharak_flutter/app/domain/auth/auth_account_repo.dart';
import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/domain/verse/repo.dart';
import 'package:dharak_flutter/app/types/user/user.dart';
import 'package:dharak_flutter/app/types/verse/bookmarks/bookmark_toggle_result.dart';
import 'package:dharak_flutter/app/types/verse/language_pref.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/ui/pages/verses/args.dart';
import 'package:dharak_flutter/app/ui/pages/verses/cubit_states.dart';
import 'package:dharak_flutter/app/utils/util_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
// import 'package:common/app/types/account/account_common.dart';

class VersesController extends Cubit<VersesCubitState> {
  var mLogger = Logger();

  final TextEditingController mSearchController = TextEditingController();

  final VerseRepository mVersesRepo;

  final AuthAccountRepository mAuthAccountRepository;

  // StreamSubscription<UserRM?>? _mAccountCommonSubscription;

  // StoreRepository mStoreRepo = Modular.get<StoreRepository>();

  StreamSubscription<UserRM?>? _mAccountCommonSubscription;
  StreamSubscription<String>? _mSearchQuerySubscription;

  StreamSubscription<VersesLanguagePrefRM?>? _mLanguagePrefSubscription;

  StreamSubscription<(int, bool)>? _mVerseBookmarkSubscription;

  Timer? _mSearchDebounce;
  StreamSubscription<VersesLanguagePrefRM?>? _mVerseLanguagePrefSubscription;

  StreamSubscription<bool>? _mLoginSubscription;
  Timer? _searchPollingTimer;
  String? _lastSearchedText;
  String? _latestText;

  VersesController({
    required this.mVersesRepo,

    required this.mAuthAccountRepository,
  }) : super(
         VersesCubitState(
           // isLoading: true,
           // state: AuthRootUiConstants.STATE_DEFAULT,
           // purpose: AuthEmailUiConstants.STATE_DEFAULT
         ),
       ) {
    _formCreate();
  }

  @override
  Future<void> close() {
    
    stopPolling();
    _mAccountCommonSubscription?.cancel();
    _mVerseBookmarkSubscription?.cancel();
    _mSearchQuerySubscription?.cancel();
    _mVerseLanguagePrefSubscription?.cancel();
    _mLanguagePrefSubscription?.cancel();
    mSearchController.dispose();
    _mSearchDebounce?.cancel();
    _mLoginSubscription?.cancel();

    // _mSearchDebounce?.cancel();
    return super.close();
  }

  Future<void> initData(VersesArgsRequest args) async {
    _subscribeBloc();

    // _mEventRefresh.sink.add(true);
  }

  void _subscribeBloc() {
    _mLoginSubscription = mAuthAccountRepository.accountChangedObservable
        .listen((value) {
          // emit(state.copyWith(loginCounter: state.loginCounter??0+1));

          if (value) {
            retry();
          }
        });

    _mVerseBookmarkSubscription = mVersesRepo.mEventVerseBookmarkStarred.listen(
      (value) {
        var index = state.verseList.indexWhere((e) => e.versePk == value.$1);


        if (index >= 0) {
          print("mEventVerseBookmarkStarred: 2");
          var verses = List<VerseRM>.from(state.verseList);
          verses[index] = verses[index].copyWith(isStarred: value.$2);

          var indexUpdateCounter = state.listIndexUpdatedCounter.$2;

          emit(
            state.copyWith(
              verseList: verses,
              listIndexUpdatedCounter: (index, (indexUpdateCounter) + 1),
            ),
          );
        }
      },
    );

    _mSearchQuerySubscription = mVersesRepo.mEventSearchQuery.listen((value) {
      onSearchDirectQuery(value);
    });

    _mLanguagePrefSubscription = mVersesRepo.mEventLanguagePref.listen((value) {
      // state.searchQuery

      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        onSearchDirectQuery(state.searchQuery!);
      }
    });

    _mVerseLanguagePrefSubscription = mVersesRepo.mLanguagePrefObservable
        .listen((value) async {
          print("🌐 VersesController LANGUAGE CHANGE: ${value?.output}");
          print("🌐 Current state - formSearchText: '${state.formSearchText}', searchQuery: '${state.searchQuery}', verseList.length: ${state.verseList.length}");
          emit(state.copyWith(verseLanguagePref: value));
          
          // If we have verses displayed, refresh them with new language
          if (state.verseList.isNotEmpty) {
            print("🔄 VersesController: Refreshing ${state.verseList.length} verses for language: ${value?.output}");
            await _refreshAllVersesForLanguageChange();
          } else {
            print("⚠️ VersesController: Skipping refresh - no verses in list");
          }
        });
  }

  // Future<void> onClickLogout() async {
  //   await mAuthAccountRepository.logout();
  // }

  void startPolling() async {
    if (state.hasApiError == true) {
      emit(state.copyWith(hasApiError: false));
    }

    if (_searchPollingTimer != null) return;

        print("startPolling -----: ");

    _searchPollingTimer ??= Timer.periodic(Duration(milliseconds: 1200), (_) {
      if (_latestText == null || _latestText!.length <= 3) return;

      if (_latestText != _lastSearchedText) {
        _lastSearchedText = _latestText;
        print('Polling with: $_latestText');
        _loadListLineByLine(); // Your API call
      }
    });
  }

  void stopPolling() {

    print("stopPolling -----: ");
    _searchPollingTimer?.cancel();
    _searchPollingTimer = null;
  }

  Future<void> retry() async {
    if (state.hasApiError == true) {
      emit(state.copyWith(hasApiError: false));
      if (_latestText == null || _latestText!.length <= 3) return;

      if (_latestText != _lastSearchedText) {
        _lastSearchedText = _latestText;
      }
      print('_loadListLineByLine after login: $_latestText');
      await _loadListLineByLine(); // Your API call
    }
  }

  onFormSearchTextChanged(String? text) async {
    /*
    TODO debounce 
    
    if (_mSearchDebounce?.isActive ?? false) _mSearchDebounce?.cancel();

    if (text?.isNotEmpty == true && text!.length > 3) {
      // Set up a new timer
      _mSearchDebounce = Timer(const Duration(milliseconds: 500), () {
        // Perform your action here, e.g., API call
        print('Debounced Input: $text');
        // TODO call api;

        _loadListLineByLine();
      });
    }
    */

    if (text == null) {
      mSearchController.clear();
      _latestText = null;
      stopPolling();
    } else {
      _latestText = text;
      if (text.length > 3) {
        startPolling(); // Starts polling if not already started
      } else {
        stopPolling(); // Stop if text too short
      }
    }

    if (text == null) {
      mSearchController.clear();
    }

    emit(state.copyWith(formSearchText: text));
  }

  onSearchDirectQuery(String word) async {
    mSearchController.value = TextEditingValue(
      text: word,
      selection: TextSelection.fromPosition(TextPosition(offset: word.length)),
    );
    emit(state.copyWith(formSearchText: word));

    await _loadListLineByLine();
  }

  onFormSubmit() async {
    print("🎯 QUICKVERSE: onFormSubmit called - current text: '${state.formSearchText}'");
    // Reset the last searched text to allow repeated searches of the same query
    _lastSearchedText = null;
    print("🎯 QUICKVERSE: Reset _lastSearchedText, now calling _loadListLineByLine");
    // emit(state.copyWith(f))
    await _loadListLineByLine();
    print("🎯 QUICKVERSE: _loadListLineByLine completed");
    // formValidate();
  }

  /*          *************************************************************8
   *                      form
   */

  _formCreate() {
    print("_formCreate ....");

    stream.listen((value) {
      formValidate();
    });
  }

  formValidate() {
    // var controls = this._mFormGroup.values.toList();
    //mLogger.d("---------------------------------------------------------");

    var isValid = true;

    // print("form validate with state 2: $isValid ${state.details}");
    // if (!mFormControllerMedia.isValid()) {
    //   isValid = false;
    //   //mLogger.d("validate message: titleController");
    // }

    if (isValid) {
      isValid = formHasChanges();
      // print("form validate with state: $isValid ${state.store} ${state.name}");
    }

    emit(state.copyWith(isSubmitEnabled: isValid));

    // }

    // add(CommuneEditValidationBlocEvent(isValid));
  }

  bool formHasChanges() {
    // if (state.product?.categoryId != state.formCategory?.id) {

    // print("formHasChanges state: 3");
    var hasChanges = false;
    if (!UtilString.isStringsEmpty(state.formSearchText) &&
        !UtilString.areStringsEqualOrNull(
          state.searchQuery,
          state.formSearchText,
        )) {
      return true;
    }

    return hasChanges;

    // print("formHasChanges state: 3");
  }

  Future<void> onBookmarkToggle(VerseRM entity, bool isToRemove) async {
    // var removedVersesIds = List<int>.from(
    //   state.removedVersesIds,
    //   growable: true,
    // );
    // var index = removedVersesIds.indexWhere((e) => e == entity.pk);
    print("onBookmarkToggle: 1. ${entity.isStarred} ${isToRemove}");

    if ((entity.isStarred ?? false) && isToRemove) {
      // print("onUpdatedCustomization index: ${index} qunatity:  ${addonsSelections[index].quantity} ${entity.quantity}");

      var isUpdated = await _toggleBookmark(
        entity.versePk,
        isToRemove: isToRemove,
      );

      if (isUpdated) {
        print("onBookmarkToggle: 2");
      }
    } else if (!(entity.isStarred ?? false) && !isToRemove) {
      var isUpdated = await _toggleBookmark(
        entity.versePk,
        isToRemove: isToRemove,
      );
      // if (isUpdated) {
      //   removedVersesIds.removeAt(index);
      //   emit(state.copyWith(removedVersesIds: removedVersesIds));
      // }

      print("onBookmarkToggle: 3");
    }

    // print("onBookmarkToggle: ")

    // inspect(removedVersesIds);
  }

  /* **************************************************************************************
   *                                      domain 
   */

  _load() async {
    if (state.isInitialized == false) {
      emit(
        state.copyWith(
          // purpose: args.purpose,
          isInitialized: true,
          // state: uiState,
          isLoading: false,
        ),
      );
    }
  }

  Future<bool> _loadList() async {
    var searchQuery = state.formSearchText;

    if (searchQuery == null) {
      return false;
    }
    emit(state.copyWith(isLoading: true));

    var result = await this.mVersesRepo.getVerses(inputStr: searchQuery ?? "");

    emit(state.copyWith(isLoading: false));
    if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
      print("getVerses: ${result}");
      // emit(state.copyWith(order: result.data));
      // ;

      emit(
        state.copyWith(
          // versesResult: result.data,
          searchCounter: state.searchCounter + 1,
          verseList: result.data?.verses ?? [],
          listReplacedCounter: state.listReplacedCounter + 1,
          searchQuery: searchQuery,
        ),
      );

      // print("getVerses 2: ${result.data?.details.definitions}");
      return true;
    } else if (result.status == DomainResultStatus.ERROR) {
      // result.message
      emit(
        state.copyWith(
          message: result.message,
          toastCounter: (state.toastCounter ?? 0) + 1,
        ),
      );
      // print("getVerses 3: ${result.message}");
    }
    print("getVerses 4: ${result}");

    return false;
  }

  Future<bool> _loadListLineByLine() async {
    var searchQuery = state.formSearchText;
    print("🎯 QUICKVERSE: _loadListLineByLine called with searchQuery: '$searchQuery'");

    if (searchQuery == null) {
      print("🎯 QUICKVERSE: searchQuery is null, returning false");
      return false;
    }

    var searchSequestCounter = state.searchSequestCounter + 1;

    emit(
      state.copyWith(
        isLoading: true,
        searchSequestCounter: searchSequestCounter,
      ),
    );

    emit(
      state.copyWith(
        verseList: [],

        listReplacedCounter: state.listReplacedCounter + 1,
        // searchCounter: state.searchCounter + 1,
        // verseList: result.data?.verses ?? [],
        // listReplacedCounter: state.listReplacedCounter + 1,
        // searchQuery: searchQuery,
        // listReplacedCounter: state.listReplacedCounter + 1,
      ),
    );

    var result = await this.mVersesRepo.getVersesStream(
      inputStr: searchQuery ?? "",
      onItem: ({footer, header, item}) {
        if (searchSequestCounter != state.searchSequestCounter) {
          return;
        }
        if (header != null) {
          print("🎯 QUICKVERSE: _loadListLineByLine: header received ======================");
          emit(
            state.copyWith(
              verseList: [],

              searchCounter: state.searchCounter + 1,
              // verseList: result.data?.verses ?? [],
              // listReplacedCounter: state.listReplacedCounter + 1,
              searchQuery: searchQuery,
              // listReplacedCounter: state.listReplacedCounter + 1,
            ),
          );
        } else if (item != null) {
          print("🎯 QUICKVERSE: _loadListLineByLine: item received, adding to list");
          var list = List<VerseRM>.from(state.verseList, growable: true);
          list.add(
            item.copyWith(
              verseText:
                  item.verseOtherScripts?[state.verseLanguagePref?.output] ??
                  item.verseText,
              verseLetText:
                  item.verseLetOtherScripts?[state.verseLanguagePref?.output] ??
                  item.verseLetText,
            ),
          );
          var indexInsertedCounter = state.listIndexInserted.$2;

          emit(
            state.copyWith(
              verseList: list,

              listIndexInserted: (list.length - 1, (indexInsertedCounter) + 1),
            ),
          );
        }
      },
    );

    if (searchSequestCounter != state.searchSequestCounter) {
      return false;
    }

    emit(state.copyWith(isLoading: false));
    if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
      print("getVerses: ${result.status}");
      // emit(state.copyWith(order: result.data));
      // ;

      // emit(
      //   state.copyWith(
      //     // versesResult: result.data,
      //     searchCounter: state.searchCounter + 1,
      //     // verseList: result.data?.verses ?? [],
      //     // listReplacedCounter: state.listReplacedCounter + 1,
      //     searchQuery: searchQuery,
      //   ),
      // );

      // print("getVerses 2: ${result.data?.details.definitions}");
      return true;
    } else if (result.status == DomainResultStatus.ERROR) {
      // result.message
      // _lastSearchedText = null;
      print("_loadListLineByLine error: ");
      // print("Error: ${}")
      emit(
        state.copyWith(
          hasApiError: true,
          message: result.message,
          toastCounter: (state.toastCounter ?? 0) + 1,
        ),
      );
      // print("getVerses 3: ${result.message}");
    }
    print("getVerses 4: ${result}");

    return false;
  }

  Future<bool> _toggleBookmark(int id, {bool isToRemove = true}) async {
    // for

    // var groupItemsOrderCounterMap = <String, int>{};

    var success = false;

    DomainResult<VerseBookmarkToggleResultRM> domainResult = await mVersesRepo
        .toggleBookmark(id, isToRemove: isToRemove);
    if (domainResult.status == DomainResultStatus.SUCCESS &&
        domainResult.data != null) {
      return domainResult.data?.success ?? false;

      // emit(state.copyWith(verseBookmarks: domainResult.data?.verse));
    }

    return success;
  }

  void refreshList() {}

  // Navigate to previous verse - replaces current verse in the list at specified index
  // Maintains language preferences and handles null responses with error messages
  Future<void> onPreviousVerse(int listIndex, String versePk) async {
    emit(state.copyWith(isLoading: true));

    var result = await mVersesRepo.getPreviousVerse(versePk: versePk);
    
    emit(state.copyWith(isLoading: false));
    
    if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
      var responseData = result.data!;
      
      if (responseData.success == true && responseData.getVerseData() != null) {
        // Successfully got previous verse - replace current verse in list
        var updatedVerses = List<VerseRM>.from(state.verseList);
        var newVerse = responseData.getVerseData()!;
        
        // Apply current language preference to the new verse
        var processedVerse = newVerse.copyWith(
          verseText: newVerse.verseOtherScripts?[state.verseLanguagePref?.output] ?? 
                     newVerse.verseText,
          verseLetText: newVerse.verseLetOtherScripts?[state.verseLanguagePref?.output] ?? 
                        newVerse.verseLetText,
        );
        
        updatedVerses[listIndex] = processedVerse;
        
        var indexUpdateCounter = state.listIndexUpdatedCounter.$2;
        
        emit(state.copyWith(
          verseList: updatedVerses,
          listIndexUpdatedCounter: (listIndex, indexUpdateCounter + 1),
        ));
      } else {
        // Backend returned success=false or null verse data
        emit(state.copyWith(
          message: "No previous verse available",
          toastCounter: (state.toastCounter ?? 0) + 1,
        ));
      }
    } else {
      // API call failed or returned error
      emit(state.copyWith(
        message: result.message ?? "Failed to load previous verse",
        toastCounter: (state.toastCounter ?? 0) + 1,
      ));
    }
  }

  // Navigate to next verse - replaces current verse in the list at specified index  
  // Maintains language preferences and handles null responses with error messages
  Future<void> onNextVerse(int listIndex, String versePk) async {
    emit(state.copyWith(isLoading: true));

    var result = await mVersesRepo.getNextVerse(versePk: versePk);
    
    emit(state.copyWith(isLoading: false));
    
    if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
      var responseData = result.data!;
      
      if (responseData.success == true && responseData.getVerseData() != null) {
        // Successfully got next verse - replace current verse in list
        var updatedVerses = List<VerseRM>.from(state.verseList);
        var newVerse = responseData.getVerseData()!;
        
        // Apply current language preference to the new verse
        var processedVerse = newVerse.copyWith(
          verseText: newVerse.verseOtherScripts?[state.verseLanguagePref?.output] ?? 
                     newVerse.verseText,
          verseLetText: newVerse.verseLetOtherScripts?[state.verseLanguagePref?.output] ?? 
                        newVerse.verseLetText,
        );
        
        updatedVerses[listIndex] = processedVerse;
        
        var indexUpdateCounter = state.listIndexUpdatedCounter.$2;
        
        emit(state.copyWith(
          verseList: updatedVerses,
          listIndexUpdatedCounter: (listIndex, indexUpdateCounter + 1),
        ));
      } else {
        // Backend returned success=false or null verse data
        emit(state.copyWith(
          message: "No next verse available", 
          toastCounter: (state.toastCounter ?? 0) + 1,
        ));
      }
    } else {
      // API call failed or returned error
      emit(state.copyWith(
        message: result.message ?? "Failed to load next verse",
        toastCounter: (state.toastCounter ?? 0) + 1,
      ));
    }
  }

  /// Refresh all verses in the current list for language changes
  /// Simply reapplies the current language preference to existing verses
  Future<void> _refreshAllVersesForLanguageChange() async {
    try {
      print("🔄 _refreshAllVersesForLanguageChange: Applying new language to ${state.verseList.length} verses");
      print("🔄 _refreshAllVersesForLanguageChange: Target language: ${state.verseLanguagePref?.output}");
      
      // Create a copy of the current verse list and apply new language
      var updatedVerses = <VerseRM>[];
      
      for (int i = 0; i < state.verseList.length; i++) {
        final verse = state.verseList[i];
        
        // Apply current language preference (same logic as prev/next buttons)
        final newVerseText = _getOtherScriptText(verse.verseOtherScripts, state.verseLanguagePref?.output);
        final newVerseLetText = _getOtherScriptText(verse.verseLetOtherScripts, state.verseLanguagePref?.output);
        
        final updatedVerse = verse.copyWith(
          verseText: newVerseText ?? verse.verseText,
          verseLetText: newVerseLetText ?? verse.verseLetText,
        );
        
        updatedVerses.add(updatedVerse);
      }
      
      print("✅ _refreshAllVersesForLanguageChange: Applied new language to all ${updatedVerses.length} verses");
      
      // Update the state with refreshed verses
      emit(state.copyWith(
        verseList: updatedVerses,
        listReplacedCounter: state.listReplacedCounter + 1,
      ));
      
    } catch (e) {
      print("💥 _refreshAllVersesForLanguageChange: Exception occurred: $e");
    }
  }

  /// Helper method to get text in target language from other scripts map
  String? _getOtherScriptText(Map<String, String>? otherScripts, String? targetLanguage) {
    if (otherScripts == null || targetLanguage == null) return null;
    return otherScripts[targetLanguage];
  }

  /* *****************************************************************************
   *                              Form
   */
}