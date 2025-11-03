import 'package:dharak_flutter/app/types/books/book_chunk.dart';
import 'package:dharak_flutter/app/ui/sections/books/bookmarks/args.dart';
import 'package:equatable/equatable.dart';

class BookChunkBookmarksCubitState extends Equatable {
  final bool isLoading;
  final bool isInitialized;
  final List<BookChunkRM>? bookmarkedChunks;
  final List<int> removedChunkIds;
  final BookChunkBookmarksArgsResult? result;

  const BookChunkBookmarksCubitState({
    this.isLoading = false,
    this.isInitialized = false,
    this.bookmarkedChunks,
    this.removedChunkIds = const [],
    this.result,
  });

  BookChunkBookmarksCubitState copyWith({
    bool? isLoading,
    bool? isInitialized,
    List<BookChunkRM>? bookmarkedChunks,
    List<int>? removedChunkIds,
    BookChunkBookmarksArgsResult? result,
  }) {
    return BookChunkBookmarksCubitState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      bookmarkedChunks: bookmarkedChunks ?? this.bookmarkedChunks,
      removedChunkIds: removedChunkIds ?? this.removedChunkIds,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isInitialized,
    bookmarkedChunks,
    removedChunkIds,
    result,
  ];
}



