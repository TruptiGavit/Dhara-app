import 'dart:async';
import 'package:dharak_flutter/app/types/dictionary/word_definitions.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/types/books/book_chunk.dart';
import 'package:dharak_flutter/core/services/dictionary_service.dart';
import 'package:dharak_flutter/core/services/verse_service.dart';
import 'package:dharak_flutter/core/services/books_service.dart';
import 'package:logger/logger.dart';

/// Search orchestrator that provides unified access to all search services
/// This wrapper allows both QuickSearch and Prashna Tools to use the same logic
class SearchOrchestrator {
  static final Logger _logger = Logger();

  // Private constructor to prevent instantiation
  SearchOrchestrator._();

  /// Search dictionary definitions
  static Future<void> searchDictionary(String query) async {
    if (query.trim().isEmpty) return;
    
    await DictionaryService.instance.searchDefinitions(query);
  }

  /// Search verses
  static Future<void> searchVerses(String query, {bool forceRefresh = false}) async {
    if (query.trim().isEmpty) return;
    
    await VerseService.instance.searchVerses(query, forceRefresh: forceRefresh);
  }

  /// Search book chunks
  static Future<List<BookChunkRM>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];
    
    _logger.d('🔍 SearchOrchestrator: Searching books for "$query"');
    return await BooksService.instance.searchBookChunks(query);
  }

  /// Get dictionary results stream
  static Stream<DictWordDefinitionsRM?> get dictionaryResults =>
      DictionaryService.instance.definitionsStream;

  /// Get verses results stream
  static Stream<List<VerseRM>> get versesResults =>
      VerseService.instance.versesStream;

  /// Get books results stream
  static Stream<List<BookChunkRM>> get booksResults =>
      BooksService.instance.currentBookChunks;

  /// Get dictionary loading state
  static Stream<bool> get dictionaryLoading =>
      DictionaryService.instance.isLoadingStream;

  /// Get verses loading state
  static Stream<bool> get versesLoading =>
      VerseService.instance.isLoadingStream;

  /// Get dictionary error state
  static Stream<String?> get dictionaryError =>
      DictionaryService.instance.errorStream;

  /// Get verses error state
  static Stream<String?> get versesError =>
      VerseService.instance.errorStream;

  /// Clear dictionary results
  static void clearDictionaryResults() {
    DictionaryService.instance.clearResults();
  }

  /// Clear verses results
  static void clearVersesResults() {
    VerseService.instance.clearResults();
  }

  /// Clear books results
  static void clearBooksResults() {
    BooksService.instance.clearBookChunks();
  }

  /// Clear all search results
  static void clearAllResults() {
    clearDictionaryResults();
    clearVersesResults();
    clearBooksResults();
    _logger.d('🧹 SearchOrchestrator: Cleared all search results');
  }

  /// Get current dictionary word count
  static int get currentDictionaryWordCount {
    // Dictionary service doesn't expose current result directly
    // We'll implement this later if needed
    return 0;
  }

  /// Get current verses count
  static int get currentVersesCount {
    return VerseService.instance.currentVerses.length;
  }

  /// Get current books count  
  static int get currentBooksCount {
    // Books service uses streams, we'll get count via stream subscription if needed
    return 0;
  }

  /// Check if any search is currently loading
  static bool get isAnySearchLoading {
    return DictionaryService.instance.isLoading ||
           VerseService.instance.isLoading;
  }

  /// Get summary of current search state
  static Map<String, dynamic> get searchSummary {
    return {
      'dictionary': {
        'count': currentDictionaryWordCount,
        'loading': DictionaryService.instance.isLoading,
      },
      'verses': {
        'count': currentVersesCount,
        'loading': VerseService.instance.isLoading,
      },
      'books': {
        'count': currentBooksCount,
        'loading': false, // Books service handles loading internally
      },
    };
  }
}
