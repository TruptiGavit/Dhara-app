import 'dart:developer';

import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/domain/verse/repo.dart';
import 'package:dharak_flutter/app/types/verse/bookmarks/bookmark_toggle_result.dart';
import 'package:dharak_flutter/app/types/verse/bookmarks/bookmarks_result.dart';
import 'package:dharak_flutter/app/types/verse/bookmarks/verse_bookmark.dart';
import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/app/ui/sections/verses/bookmarks/args.dart';
import 'package:dharak_flutter/app/ui/sections/verses/bookmarks/cubit_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class VerseBookmarksController extends Cubit<VerseBookmarksCubitState> {
  var mLogger = Logger();

  final VerseRepository mVerseRepository;
  VerseBookmarksController({required this.mVerseRepository})
    : super(VerseBookmarksCubitState(isLoading: true));

  @override
  Future<void> close() {
    return super.close();
  }

  Future<void> initData(VerseBookmarksArgsRequest args) async {
    emit(state.copyWith(isInitialized: false, isLoading: false));

    await _load();

    // _mEventRefresh.sink.add(true);
  }

  void setRunning(bool isRunning) {
    emit(state.copyWith(isLoading: isRunning));
  }

  Future<void> onBookmarkToggle(VerseBookmarkRM entity, bool isToRemove) async {
    var removedVersesIds = List<int>.from(
      state.removedVersesIds,
      growable: true,
    );
    var index = removedVersesIds.indexWhere((e) => e == entity.pk);
    print("onBookmarkToggle: 1. ${index} ${isToRemove}");

    if (index < 0 && isToRemove) {
      // print("onUpdatedCustomization index: ${index} qunatity:  ${addonsSelections[index].quantity} ${entity.quantity}");

      var isUpdated = await _toggleBookmark(
        entity.pk,
        isToRemove: isToRemove,
      );

      if (isUpdated) {
        removedVersesIds.add(entity.pk);
        print("onBookmarkToggle: 2");

        emit(state.copyWith(removedVersesIds: removedVersesIds));
      }
    } else if (index >= 0 && !isToRemove) {
      var isUpdated = await _toggleBookmark(
        entity.pk,
        isToRemove: isToRemove,
      );
      if (isUpdated) {
        removedVersesIds.removeAt(index);
        emit(state.copyWith(removedVersesIds: removedVersesIds));
      }

      print("onBookmarkToggle: 3");
    }

    // print("onBookmarkToggle: ")

    // inspect(removedVersesIds);
  }

  /* ***********************************************************************************
   *                                      domain
   */

  Future<void> _load() async {
    emit(state.copyWith(isLoading: true));
    var isLoaded = await _loadBookmarks();
    // var isUpdated = await _loadCategory();

    if (!isLoaded) {
      emit(state.copyWith(isLoading: false));

      return;
    }

    // await _loadCustomizations();

    // print("_load: done");

    emit(state.copyWith(isLoading: false, isInitialized: true));
  }

  Future<bool> _loadBookmarks() async {
    // for

    // var groupItemsOrderCounterMap = <String, int>{};

    var success = false;

    DomainResult<VerseBookmarksResultRM> domainResult =
        await mVerseRepository.getVerseBookmarks();
    if (domainResult.status == DomainResultStatus.SUCCESS &&
        domainResult.data != null) {
      success = true;

      emit(state.copyWith(verseBookmarks: domainResult.data?.verse));
    }

    return success;
  }

  Future<bool> _toggleBookmark(int id, {bool isToRemove = true}) async {
    // for

    // var groupItemsOrderCounterMap = <String, int>{};

    var success = false;

    DomainResult<VerseBookmarkToggleResultRM> domainResult =
        await mVerseRepository.toggleBookmark(id, isToRemove: isToRemove);
    if (domainResult.status == DomainResultStatus.SUCCESS &&
        domainResult.data != null) {
      return domainResult.data?.success ?? false;

      // emit(state.copyWith(verseBookmarks: domainResult.data?.verse));
    }

    return success;
  }

  /* *********************************************************************************************************
 *                                            response Args
 */

  void onSuccess() {
    // print("onSuccess : ${selections?.length} ${pSelections?.length}");
    emit(
      state.copyWith(
        result: VerseBookmarksArgsResult(
          resultCode: UiConstants.BundleArgs.resultSuccess,
        ),
      ),
    );
  }

  void onFailed(String message) {
    emit(
      state.copyWith(
        result: VerseBookmarksArgsResult(
          resultCode: UiConstants.BundleArgs.resultFailed,
          message: message,
        ),
      ),
    );
  }

  void onClose({int? purpose}) {
    emit(
      state.copyWith(
        result: VerseBookmarksArgsResult(
          purpose: purpose,
          resultCode: UiConstants.BundleArgs.resultCanceled,
          // refreshParent: state.refreshParent,
        ),
      ),
    );
  }
}
