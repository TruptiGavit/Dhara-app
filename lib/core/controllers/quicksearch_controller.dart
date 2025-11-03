import 'dart:async';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:dharak_flutter/app/bloc/state_bloc.dart';
import 'package:dharak_flutter/app/types/dictionary/word_definitions.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/types/books/book_chunk.dart';
import 'package:dharak_flutter/core/services/dictionary_service.dart';
import 'package:dharak_flutter/core/services/verse_service.dart';
import 'package:dharak_flutter/core/services/books_service.dart';
import 'package:dharak_flutter/core/cache/smart_search_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

part 'quicksearch_controller.g.dart';

/// Search types available in QuickSearch tab
enum SearchType { 
  wordDefine, 
  quickVerse,
  books, // Books search added
  unified, // Unified search added
}

/// State for QuickSearch tab with optimized rebuilds
@CopyWith()
class QuickSearchState extends BlocState {
  final SearchType currentSearchType;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final bool showClearButton;
  
  // Separate result caches for fast switching
  final DictWordDefinitionsRM? wordDefineResult;
  final List<VerseRM> verseResults;
  final List<BookChunkRM> bookResults;
  
  // UI state
  final int searchCounter;
  final int typeChangeCounter;

  QuickSearchState({
    this.currentSearchType = SearchType.wordDefine,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.showClearButton = false,
    this.wordDefineResult,
    this.verseResults = const [],
    this.bookResults = const [],
    this.searchCounter = 0,
    this.typeChangeCounter = 0,
  });

  factory QuickSearchState.initial() => QuickSearchState();

  @override
  List<Object?> get props => [
    currentSearchType,
    isLoading,
    error,
    searchQuery,
    showClearButton,
    wordDefineResult,
    verseResults,
    bookResults,
    searchCounter,
    typeChangeCounter,
  ];
}

/// Optimized controller for QuickSearch tab
/// Manages both WordDefine and QuickVerse search with smart caching
class QuickSearchController extends Cubit<QuickSearchState> {
  final Logger _logger = Logger();
  final DictionaryService _dictionaryService = DictionaryService.instance;
  final VerseService _verseService = VerseService.instance;
  final BooksService _booksService = BooksService.instance;
  
  Timer? _debounceTimer;
  String _lastSearchQuery = '';
  
  StreamSubscription<DictWordDefinitionsRM?>? _dictionarySubscription;
  StreamSubscription<List<VerseRM>>? _verseSubscription;
  StreamSubscription<List<BookChunkRM>>? _booksSubscription;
  StreamSubscription<bool>? _dictionaryLoadingSubscription;
  StreamSubscription<bool>? _verseLoadingSubscription;
  StreamSubscription<String?>? _dictionaryErrorSubscription;
  StreamSubscription<String?>? _verseErrorSubscription;

  QuickSearchController() : super(QuickSearchState.initial()) {
    _subscribeToServices();
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _dictionarySubscription?.cancel();
    _verseSubscription?.cancel();
    _booksSubscription?.cancel();
    _dictionaryLoadingSubscription?.cancel();
    _verseLoadingSubscription?.cancel();
    _dictionaryErrorSubscription?.cancel();
    _verseErrorSubscription?.cancel();
    return super.close();
  }

  /// Subscribe to service streams for reactive updates
  void _subscribeToServices() {
    // Dictionary service streams
    _dictionarySubscription = _dictionaryService.definitionsStream.listen((result) {
      if (state.currentSearchType == SearchType.wordDefine) {
        emit(state.copyWith(
          wordDefineResult: result,
          searchCounter: state.searchCounter + 1,
        ));
      }
    });

    _dictionaryLoadingSubscription = _dictionaryService.isLoadingStream.listen((loading) {
      if (state.currentSearchType == SearchType.wordDefine) {
        emit(state.copyWith(isLoading: loading));
      }
    });

    _dictionaryErrorSubscription = _dictionaryService.errorStream.listen((error) {
      if (state.currentSearchType == SearchType.wordDefine) {
        emit(state.copyWith(error: error));
      }
    });

    // Verse service streams
    _verseSubscription = _verseService.versesStream.listen((results) {
      if (state.currentSearchType == SearchType.quickVerse) {
        emit(state.copyWith(
          verseResults: results,
          searchCounter: state.searchCounter + 1,
        ));
      }
    });

    _verseLoadingSubscription = _verseService.isLoadingStream.listen((loading) {
      if (state.currentSearchType == SearchType.quickVerse) {
        emit(state.copyWith(isLoading: loading));
      }
    });

    _verseErrorSubscription = _verseService.errorStream.listen((error) {
      if (state.currentSearchType == SearchType.quickVerse) {
        emit(state.copyWith(error: error));
      }
    });

    // Books service streams
    _booksSubscription = _booksService.currentBookChunks.listen((results) {
      if (state.currentSearchType == SearchType.books) {
        emit(state.copyWith(
          bookResults: results,
          searchCounter: state.searchCounter + 1,
          isLoading: false,
        ));
      }
    });
  }

  /// Switch between search types (WordDefine, QuickVerse)
  void switchSearchType(SearchType type) {
    if (state.currentSearchType == type) return;

    
    // Clear search when switching types for better UX
    emit(state.copyWith(
      currentSearchType: type,
      typeChangeCounter: state.typeChangeCounter + 1,
      error: null,
      searchQuery: '', // Clear search query when switching
      wordDefineResult: null, // Clear previous results
      verseResults: const [], // Clear previous results
      showClearButton: false,
      isLoading: false,
    ));
    
    // Clear any ongoing search timers
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _lastSearchQuery = '';
  }

  /// Handle search input changes with debouncing
  void onSearchChanged(String query) {
    final trimmedQuery = query.trim();
    
    emit(state.copyWith(
      searchQuery: query,
      showClearButton: query.isNotEmpty,
      error: null,
    ));

    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (trimmedQuery.isEmpty) {
      _clearResults();
      return;
    }

    // Check if query changed significantly
    if (trimmedQuery == _lastSearchQuery) {
      return;
    }

    _lastSearchQuery = trimmedQuery;

    // Auto-search disabled for performance - use search button instead
    // _debounceTimer = Timer(const Duration(milliseconds: 300), () {
    //   _performSearchForCurrentType(trimmedQuery);
    // });
  }

  /// Perform manual search (triggered by search button or enter key)
  void performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    // Note: Removed the duplicate search check to allow repeated searches
    // This enables users to search the same query multiple times
    
    emit(state.copyWith(
      searchQuery: query,
      isLoading: true,
      error: null,
    ));
    
    _performSearchForCurrentType(query.trim(), forceRefresh: true);
  }

  /// Force search to allow same query (for language changes)
  void forceSearch(String query) {
    if (query.trim().isEmpty) return;
    
    // Clear last search query to allow repeat search
    _lastSearchQuery = '';
    
    emit(state.copyWith(
      searchQuery: query,
      isLoading: true,
      error: null,
    ));
    
    _performSearchForCurrentType(query.trim(), forceRefresh: true);
  }

  /// Clear search query and results
  void clearSearch() {
    _debounceTimer?.cancel();
    _lastSearchQuery = '';
    
    emit(state.copyWith(
      searchQuery: '',
      showClearButton: false,
      error: null,
    ));
    
    _clearResults();
  }

  /// Perform search based on current search type
  void _performSearchForCurrentType(String query, {bool forceRefresh = false}) {
    switch (state.currentSearchType) {
      case SearchType.wordDefine:
        _dictionaryService.searchDefinitions(query);
        break;
      case SearchType.quickVerse:
        _verseService.searchVerses(query, forceRefresh: forceRefresh);
        break;
      case SearchType.books:
        _searchBooks(query);
        break;
      case SearchType.unified:
        // Unified search is handled in separate page, no action needed here
        break;
    }
  }

  /// Update loading state when switching types
  void _updateLoadingStateForCurrentType() {
    bool loading = false;
    
    switch (state.currentSearchType) {
      case SearchType.wordDefine:
        loading = _dictionaryService.isLoading;
        break;
      case SearchType.quickVerse:
        loading = _verseService.isLoading;
        break;
      case SearchType.books:
        loading = false; // Books service handles loading internally
        break;
      case SearchType.unified:
        loading = false; // Unified search handled in separate page
        break;
    }
    
    emit(state.copyWith(isLoading: loading));
  }

  /// Clear results for current search type
  void _clearResults() {
    switch (state.currentSearchType) {
      case SearchType.wordDefine:
        _dictionaryService.clearResults();
        break;
      case SearchType.quickVerse:
        _verseService.clearResults();
        break;
      case SearchType.books:
        _booksService.clearBookChunks();
        break;
      case SearchType.unified:
        // Unified search handled in separate page
        break;
    }
  }

  /// Get current results based on search type
  bool get hasResults {
    switch (state.currentSearchType) {
      case SearchType.wordDefine:
        return state.wordDefineResult != null && 
               state.wordDefineResult!.details.definitions.isNotEmpty;
      case SearchType.quickVerse:
        return state.verseResults.isNotEmpty;
      case SearchType.books:
        return state.bookResults.isNotEmpty;
      case SearchType.unified:
        return false; // Unified search handled in separate page
    }
  }

  /// Get result count for current search type
  int get resultCount {
    switch (state.currentSearchType) {
      case SearchType.wordDefine:
        return state.wordDefineResult?.details.definitions.length ?? 0;
      case SearchType.quickVerse:
        return state.verseResults.length;
      case SearchType.books:
        return state.bookResults.length;
      case SearchType.unified:
        return 0; // Unified search handled in separate page
    }
  }

  /// Search for book chunks
  Future<void> _searchBooks(String query) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final results = await _booksService.searchBookChunks(query);
      
      if (state.currentSearchType == SearchType.books) {
        emit(state.copyWith(
          bookResults: results,
          isLoading: false,
          searchCounter: state.searchCounter + 1,
        ));
      }
    } catch (e) {
      if (state.currentSearchType == SearchType.books) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Failed to search books: $e',
        ));
      }
    }
  }

  /// Check if current query has cached results
  bool get hasCachedResults {
    if (state.searchQuery.isEmpty) return false;
    
    switch (state.currentSearchType) {
      case SearchType.wordDefine:
        return _dictionaryService.hasCachedDefinitions(state.searchQuery);
      case SearchType.quickVerse:
        return _verseService.hasCachedVerses(state.searchQuery);
      case SearchType.books:
        return SmartSearchCache.instance.hasBookChunks(state.searchQuery);
      case SearchType.unified:
        return false; // Unified search handled in separate page
    }
  }
}
