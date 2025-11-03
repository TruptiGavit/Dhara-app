

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:dharak_flutter/app/bloc/state_bloc.dart';
import 'package:dharak_flutter/app/types/verse/bookmarks/verse_bookmark.dart';
import 'package:dharak_flutter/app/ui/sections/verses/bookmarks/args.dart';

part 'cubit_states.g.dart';

@CopyWith()
class VerseBookmarksCubitState extends BlocState {
  // final CommuneBankerBox? myCommuneBanker;

  final bool? isLoading;

  final bool? isInProgress;
  final bool? isInitialized;

  final VerseBookmarksArgsResult? result;

  final bool? isEmpty;
  final int? retryCounter;
  final int? toastCounter;
  final String? message;

  final List<VerseBookmarkRM>? verseBookmarks;
  final List<int> removedVersesIds;

// val state: Int = AuthUiConstants.STATE_DEFAULT,
  VerseBookmarksCubitState(
      {
      // this.myCommuneBanker,
      this.isLoading,
      this.isInitialized,
      this.result,
      this.retryCounter,
      this.toastCounter,
      this.isEmpty,
      this.message,
      this.isInProgress,
      this.verseBookmarks,
      this.removedVersesIds = const []});

  @override
  List<Object?> get props => [
        isLoading,
        isInitialized,
        retryCounter,
        toastCounter,
        isEmpty,
        // myCommuneBanker,
        result,
        verseBookmarks,
        isInProgress,
        removedVersesIds
      ];
}
