import 'dart:developer';

import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/domain/dictionary/repo.dart';
import 'package:dharak_flutter/app/domain/verse/repo.dart';
import 'package:dharak_flutter/app/types/search-history/result.dart';
import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/app/ui/sections/history/args.dart';
import 'package:dharak_flutter/app/ui/sections/history/cubit_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class SearchHistoryController extends Cubit<SearchHistoryCubitState> {
  var mLogger = Logger();

  final VerseRepository mVerseRepository;
  final DictionaryRepository mDictionaryRepository;
  SearchHistoryController({
    required this.mVerseRepository,
    required this.mDictionaryRepository,
  }) : super(SearchHistoryCubitState(isLoading: true));

  @override
  Future<void> close() {
    return super.close();
  }

  Future<void> initData(SearchHistoryArgsRequest args) async {
    emit(
      state.copyWith(
        isInitialized: false,
        isLoading: false,
        isForVerse: args.isForVerse,
      ),
    );

    await _load();

    // _mEventRefresh.sink.add(true);
  }

  void setRunning(bool isRunning) {
    emit(state.copyWith(isLoading: isRunning));
  }

  void onItemSelected(String searchItem) {
    onSuccess(searchItem);
  }

  /* ***********************************************************************************
   *                                      domain
   */

  Future<void> _load() async {
    emit(state.copyWith(isLoading: true));
    var isLoaded = await _loadHistory();
    // var isUpdated = await _loadCategory();

    if (!isLoaded) {
      emit(state.copyWith(isLoading: false));

      return;
    }

    // await _loadCustomizations();

    // print("_load: done");

    emit(state.copyWith(isLoading: false, isInitialized: true));
  }

  Future<bool> _loadHistory() async {
    // for

    // var groupItemsOrderCounterMap = <String, int>{};

    var success = false;

    DomainResult<SearchHistoryResultRM> domainResult =
        state.isForVerse
            ? await mVerseRepository.getSearchHistory()
            : await mDictionaryRepository.getSearchHistory();
    if (domainResult.status == DomainResultStatus.SUCCESS &&
        domainResult.data != null) {
      success = true;

      emit(state.copyWith(searchHistoryList: domainResult.data?.history));
    }

    return success;
  }

  /* *********************************************************************************************************
 *                                            response Args
 */

  void onSuccess(String? searchQuery) {
    // print("onSuccess : ${selections?.length} ${pSelections?.length}");
    emit(
      state.copyWith(
        result: SearchHistoryArgsResult(
          searchQuery: searchQuery,
          resultCode: UiConstants.BundleArgs.resultSuccess,
        ),
      ),
    );
  }

  void onFailed(String message) {
    emit(
      state.copyWith(
        result: SearchHistoryArgsResult(
          resultCode: UiConstants.BundleArgs.resultFailed,
          message: message,
        ),
      ),
    );
  }

  void onClose({int? purpose}) {
    emit(
      state.copyWith(
        result: SearchHistoryArgsResult(
          purpose: purpose,
          resultCode: UiConstants.BundleArgs.resultCanceled,
          // refreshParent: state.refreshParent,
        ),
      ),
    );
  }
}
