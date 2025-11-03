import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:dharak_flutter/app/bloc/state_bloc.dart';
import 'package:dharak_flutter/app/types/books/chunk.dart';

part 'cubit_states.g.dart';

@CopyWith()
class BooksCubitState extends BlocState {
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
  final BookChunksResponseRM? booksResponse;
  final List<BookChunkRM> bookChunks;

  BooksCubitState({
    this.isLoading,
    this.isInitialized,
    this.retryCounter,
    this.toastCounter,
    this.isEmpty,
    this.message,
    this.formSearchText,
    this.searchQuery,
    this.searchCounter = 0,
    this.booksResponse,
    this.bookChunks = const [],
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
        booksResponse,
        bookChunks,
        isSubmitEnabled,
      ];
}


