import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:dharak_flutter/app/bloc/state_bloc.dart';
import 'package:dharak_flutter/app/types/dictionary/definition.dart';
import 'package:dharak_flutter/app/types/dictionary/dict_word_detail.dart';
import 'package:dharak_flutter/app/types/dictionary/word_definitions.dart';
// import 'package:common/bloc/state_bloc.dart';
// import 'package:copy_with_extension/copy_with_extension.dart';

part 'cubit_states.g.dart';

@CopyWith()
class WordDefineCubitState extends BlocState {
  // final CommuneBankerBox? myCommuneBanker;

  final bool? isLoading;

  final bool? isInitialized;

  final bool? isEmpty;
  final int? retryCounter;
  final int? toastCounter;
  final String? message;
  final String? formSearchText;
  final String? searchQuery;
  final int searchCounter;
  final bool isSubmitEnabled;
  final DictWordDefinitionsRM? dictWordDefinitions;
  final DictWordDetailRM? wordDetails;
  final List<WordDefinitionRM> wordDefinitions;
  final List<String> similarWords;

  WordDefineCubitState({
    this.isLoading,
    this.isInitialized,
    this.retryCounter,
    this.toastCounter,
    this.isEmpty,
    this.message,
    this.formSearchText,
    this.searchQuery,
    this.searchCounter = 0,
    this.dictWordDefinitions,
    this.wordDetails,
    this.wordDefinitions = const [],
    this.similarWords = const [],
    this.isSubmitEnabled = false,
  });

  @override
  List<Object?> get props => [
    isLoading,
    isInitialized,
    retryCounter,
    toastCounter,
    isEmpty,
    formSearchText,
    searchQuery,
    searchCounter,
    wordDetails,
    dictWordDefinitions,
    wordDefinitions,
    similarWords,
    isSubmitEnabled,
  ];
}
