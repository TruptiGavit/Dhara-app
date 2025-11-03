import 'dart:developer';

import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/domain/books/repo.dart';
import 'package:dharak_flutter/app/types/books/book_chunk.dart';
import 'package:dharak_flutter/app/types/books/book_bookmark_result.dart';
import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/app/ui/sections/books/bookmarks/args.dart';
import 'package:dharak_flutter/app/ui/sections/books/bookmarks/cubit_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class BookChunkBookmarksController extends Cubit<BookChunkBookmarksCubitState> {
  var mLogger = Logger();

  final BooksRepository mBooksRepository;
  BookChunkBookmarksController({required this.mBooksRepository})
    : super(const BookChunkBookmarksCubitState(isLoading: true));

  @override
  Future<void> close() {
    return super.close();
  }

  Future<void> initData(BookChunkBookmarksArgsRequest args) async {
    emit(state.copyWith(isInitialized: false, isLoading: false));

    await _load();

    // _mEventRefresh.sink.add(true);
  }

  void setRunning(bool isRunning) {
    emit(state.copyWith(isLoading: isRunning));
  }

  Future<void> onBookmarkToggle(BookChunkRM entity, bool isToRemove) async {
    var removedChunkIds = List<int>.from(
      state.removedChunkIds,
      growable: true,
    );
    var index = removedChunkIds.indexWhere((e) => e == entity.chunkRefId);
    print("onBookmarkToggle: 1. ${index} ${isToRemove}");

    if (index < 0 && isToRemove) {
      // print("onUpdatedCustomization index: ${index} qunatity:  ${addonsSelections[index].quantity} ${entity.quantity}");

      var isUpdated = await _toggleBookmark(
        entity.chunkRefId!,
        isToRemove: isToRemove,
      );

      if (isUpdated) {
        removedChunkIds.add(entity.chunkRefId!);
        print("onBookmarkToggle: 2");

        emit(state.copyWith(removedChunkIds: removedChunkIds));
      }
    } else if (index >= 0 && !isToRemove) {
      var isUpdated = await _toggleBookmark(
        entity.chunkRefId!,
        isToRemove: isToRemove,
      );
      if (isUpdated) {
        removedChunkIds.removeAt(index);
        emit(state.copyWith(removedChunkIds: removedChunkIds));
      }

      print("onBookmarkToggle: 3");
    }

    // print("onBookmarkToggle: ")

    // inspect(removedChunkIds);
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

    DomainResult<BookChunkStarredListResultRM> domainResult =
        await mBooksRepository.getStarredChunks();
    if (domainResult.status == DomainResultStatus.SUCCESS &&
        domainResult.data != null) {
      success = true;

      emit(state.copyWith(bookmarkedChunks: domainResult.data?.chunks));
    }

    return success;
  }

  Future<bool> _toggleBookmark(int chunkRefId, {bool isToRemove = true}) async {
    // for

    // var groupItemsOrderCounterMap = <String, int>{};

    var success = false;

    DomainResult<BookChunkBookmarkToggleResultRM> domainResult =
        await mBooksRepository.toggleBookmark(chunkRefId, isToRemove: isToRemove);
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
        result: BookChunkBookmarksArgsResult(
          resultCode: UiConstants.BundleArgs.resultSuccess,
        ),
      ),
    );
  }

  void onFailed(String message) {
    emit(
      state.copyWith(
        result: BookChunkBookmarksArgsResult(
          resultCode: UiConstants.BundleArgs.resultFailed,
          message: message,
        ),
      ),
    );
  }

  void onClose({int? purpose}) {
    emit(
      state.copyWith(
        result: BookChunkBookmarksArgsResult(
          purpose: purpose,
          resultCode: UiConstants.BundleArgs.resultCanceled,
          // refreshParent: state.refreshParent,
        ),
      ),
    );
  }
}
