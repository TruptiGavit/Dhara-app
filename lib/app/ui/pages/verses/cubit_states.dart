import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:dharak_flutter/app/bloc/state_bloc.dart';
import 'package:dharak_flutter/app/types/verse/language_pref.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
// import 'package:common/bloc/state_bloc.dart';
// import 'package:copy_with_extension/copy_with_extension.dart';

part 'cubit_states.g.dart';

@CopyWith()
class VersesCubitState extends BlocState {
  // final CommuneBankerBox? myCommuneBanker;

  final bool? isLoading;

  final bool? isInitialized;

  // final DashboardArgsResult? result;

  final bool? isEmpty;
  final int? retryCounter;
  final int? toastCounter;
  final bool? hasApiError;
  final String? message;
  final String? formSearchText;
  final String? searchQuery;
  final int? loginCounter;
  final int searchCounter;
  final int searchSequestCounter;
  final bool isSubmitEnabled;
  // final VersesResultRM? versesResult;
  final List<VerseRM> verseList;

  final int listReplacedCounter;

  final (int, int) listIndexUpdatedCounter;

  final (int, int) listIndexInserted;
  final VersesLanguagePrefRM? verseLanguagePref;
  // final AccountCommonModel? accountCommon;

  VersesCubitState({
    // this.myCommuneBanker,
    this.isLoading,
    this.isInitialized,
    this.retryCounter,
    this.toastCounter,
    this.hasApiError,
    this.isEmpty,
    this.message,
    this.formSearchText,
    this.searchQuery,
    this.loginCounter = 0,
    this.searchCounter = 0,
    this.searchSequestCounter = 0,

    // this.versesResult,
    this.verseList = const [],
    this.isSubmitEnabled = false,
    this.listReplacedCounter = 0,
    this.listIndexUpdatedCounter = (-1, 0),

    this.listIndexInserted = (-1, 0),
    this.verseLanguagePref,

    // this.accountCommon,
    // required this.state ,
    // required this.purpose,
    // this.isAuthorized = false
  });

  @override
  List<Object?> get props => [
    isLoading,
    isInitialized,
    retryCounter,
    toastCounter,
    hasApiError,
    isEmpty,
    formSearchText,
    searchQuery, loginCounter,
    searchCounter,
    searchSequestCounter,
    // versesResult,
    verseList,
    isSubmitEnabled,
    listReplacedCounter,
    listIndexUpdatedCounter,
    listIndexInserted,
    verseLanguagePref,
    // accountCommon
    // state,
    // purpose,
    // isAuthorized
  ];
}
