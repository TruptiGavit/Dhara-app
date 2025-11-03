import 'package:dharak_flutter/app/data/remote/api/base/dto/error_dto.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/verse/api.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/verse/dto/languages/get_dto.dart';
import 'package:dharak_flutter/app/domain/base/domain_helper.dart';
import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/types/search-history/result.dart';
import 'package:dharak_flutter/app/types/verse/bookmarks/bookmark_toggle_result.dart';
import 'package:dharak_flutter/app/types/verse/bookmarks/bookmarks_result.dart';
import 'package:dharak_flutter/app/types/verse/verse_prev_next_result.dart';
import 'package:dharak_flutter/app/types/verse/language_pref.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/types/verse/verse_foot.dart';
import 'package:dharak_flutter/app/types/verse/verse_head.dart';
import 'package:dharak_flutter/app/types/verse/verses.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

class VerseRepository extends Disposable {
  final VerseApiRepo mVerseApiRepo;

  final PublishSubject<(int, bool)> _mEventVerseBookmarkStarred =
      PublishSubject<(int, bool)>();
  PublishSubject<(int, bool)> get mEventVerseBookmarkStarred =>
      _mEventVerseBookmarkStarred;

  final PublishSubject<String> _mEventSearchQuery = PublishSubject<String>();
  PublishSubject<String> get mEventSearchQuery => _mEventSearchQuery;

  final PublishSubject<VersesLanguagePrefRM?> _mEventLanguagePref =
      PublishSubject<VersesLanguagePrefRM?>();
  PublishSubject<VersesLanguagePrefRM?> get mEventLanguagePref =>
      _mEventLanguagePref;

  final BehaviorSubject<VersesLanguagePrefRM?> _mSubjectLanguagePref = BehaviorSubject.seeded(
    null,
  );
  BehaviorSubject<VersesLanguagePrefRM?> get mLanguagePrefObservable => _mSubjectLanguagePref;

  VerseRepository({required this.mVerseApiRepo});

  @override
  void dispose() {
    _mEventVerseBookmarkStarred.close();
    _mEventSearchQuery.close();
    _mEventLanguagePref.close();
    _mSubjectLanguagePref.close();
  }

  void initData() {}

  void onNewSearchQuery(String? searchQuery) {
    if (searchQuery == null) return;

    _mEventSearchQuery.sink.add(searchQuery);
  }

  Future<DomainResult<VersesResultRM>> getVerses({
    required String inputStr,
  }) async {
    return await domainCallBeforeSave<
      VersesResultRM,
      VersesResultRM,
      ErrorDto,
      VersesResultRM
    >(
      networkCall: () async {
        return await mVerseApiRepo.getVerses(inputStr: inputStr);
        // if(apiResponse.)
      },
      saveCallResult: (remoteData) {
        return Future.value(remoteData);
      },
      finalResult: (savedData) => savedData,
    );
  }

  Future<DomainResult<bool>> getVersesStream({
    required String inputStr,
    required void Function({
      VerseRM? item,
      VerseFootRM? footer,
      VerseHeadRM? header,
    })
    onItem,
  }) async {
    return await domainCallBeforeSave<bool, bool, ErrorDto, bool>(
      networkCall: () async {
        return await mVerseApiRepo.getVersesByCallback(
          inputStr: inputStr,
          onItem: onItem,
        );
        // if(apiResponse.)
      },
      saveCallResult: (remoteData) {
        return Future.value(remoteData);
      },
      finalResult: (savedData) => savedData,
    );
  }

  Future<DomainResult<VerseBookmarksResultRM>> getVerseBookmarks() async {
    return await domainCallBeforeSave<
      VerseBookmarksResultRM,
      VerseBookmarksResultRM,
      ErrorDto,
      VerseBookmarksResultRM
    >(
      networkCall: () async {
        return await mVerseApiRepo.getBookmarks();
        // if(apiResponse.)
      },
      saveCallResult: (remoteData) {
        return Future.value(remoteData);
      },
      finalResult: (savedData) => savedData,
    );
  }

  Future<DomainResult<VerseBookmarkToggleResultRM>> toggleBookmark(
    int id, {
    bool isToRemove = true,
  }) async {
    return await domainCallBeforeSave<
      VerseBookmarkToggleResultRM,
      VerseBookmarkToggleResultRM,
      ErrorDto,
      VerseBookmarkToggleResultRM
    >(
      networkCall: () async {
        return await mVerseApiRepo.toggleBookmark(
          id.toString(),
          isToRemove: isToRemove,
        );
        // if(apiResponse.)
      },
      saveCallResult: (remoteData) {
        if (remoteData.success) {
          _mEventVerseBookmarkStarred.sink.add((id, !isToRemove));
        }
        return Future.value(remoteData);
      },
      finalResult: (savedData) => savedData,
    );
  }

  Future<DomainResult<VersesLanguagePrefRM>> getlanguagePref({
    String? output,
  }) async {
    return await domainCallBeforeSave<
      VersesLanguagePrefRM,
      VerseLanguagePrefGetResultDto,
      ErrorDto,
      VersesLanguagePrefRM
    >(
      networkCall: () async {
        return await mVerseApiRepo.getLanguagePref(output: output);
        // if(apiResponse.)
      },
      saveCallResult: (remoteData) {
        if (remoteData.success == true) {
          _mEventLanguagePref.sink.add((remoteData.langPref));
          _mSubjectLanguagePref.sink.add(remoteData.langPref);
        }
        return Future.value(remoteData.langPref);
      },
      finalResult: (savedData) => savedData,
    );
  }

  Future<DomainResult<SearchHistoryResultRM>> getSearchHistory() async {
    return await domainCallBeforeSave<
      SearchHistoryResultRM,
      SearchHistoryResultRM,
      ErrorDto,
      SearchHistoryResultRM
    >(
      networkCall: () async {
        return await mVerseApiRepo.getSearchHistory();
      },
      saveCallResult: (remoteData) {
        return Future.value(remoteData);
      },
      finalResult: (savedData) => savedData,
    );
  }

  // Get previous verse using verse_pk - follows existing domain pattern
  // Returns domain result with error handling for consistent UI response
  Future<DomainResult<VersePrevNextResultRM>> getPreviousVerse({
    required String versePk,
  }) async {
    return await domainCallBeforeSave<
      VersePrevNextResultRM,
      VersePrevNextResultRM,
      ErrorDto,
      VersePrevNextResultRM
    >(
      networkCall: () async {
        return await mVerseApiRepo.getPreviousVerse(versePk: versePk);
      },
      saveCallResult: (remoteData) {
        return Future.value(remoteData);
      },
      finalResult: (savedData) => savedData,
    );
  }

  // Get next verse using verse_pk - follows existing domain pattern
  // Returns domain result with error handling for consistent UI response
  Future<DomainResult<VersePrevNextResultRM>> getNextVerse({
    required String versePk,
  }) async {
    return await domainCallBeforeSave<
      VersePrevNextResultRM,
      VersePrevNextResultRM,
      ErrorDto,
      VersePrevNextResultRM
    >(
      networkCall: () async {
        return await mVerseApiRepo.getNextVerse(versePk: versePk);
      },
      saveCallResult: (remoteData) {
        return Future.value(remoteData);
      },
      finalResult: (savedData) => savedData,
    );
  }
}