

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:dharak_flutter/app/bloc/state_bloc.dart';
import 'package:dharak_flutter/app/ui/sections/history/args.dart';

part 'cubit_states.g.dart';

@CopyWith()
class SearchHistoryCubitState extends BlocState {
  // final CommuneBankerBox? myCommuneBanker;

  final bool? isLoading;

  final bool? isInProgress;
  final bool? isInitialized;

  final SearchHistoryArgsResult? result;

  final bool? isEmpty;
  final int? retryCounter;
  final int? toastCounter;
  final String? message;

  final bool isForVerse;

  final List<String>? searchHistoryList;

// val state: Int = AuthUiConstants.STATE_DEFAULT,
  SearchHistoryCubitState(
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
      this.isForVerse =  true,
      this.searchHistoryList,});

  @override
  List<Object?> get props => [
        isLoading,
        isInitialized,
        retryCounter,
        toastCounter,
        isEmpty,
        // myCommuneBanker,
        result,
        isForVerse,
        searchHistoryList,
        isInProgress,
      ];
}
