import 'dart:async';
import 'package:dharak_flutter/app/domain/verse/repo.dart';
import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/types/verse/verses.dart';
import 'package:dharak_flutter/app/types/verse/verse_prev_next_result.dart';
import 'package:dharak_flutter/app/types/verse/bookmarks/bookmark_toggle_result.dart';
import 'package:dharak_flutter/app/types/verse/bookmarks/bookmarks_result.dart';
import 'package:dharak_flutter/app/types/verse/language_pref.dart';
import 'package:dharak_flutter/app/types/search-history/result.dart';
import 'package:dharak_flutter/core/cache/smart_search_cache.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

/// Optimized Verse Service with smart caching and reactive streams
class VerseService extends Disposable {
  static final VerseService _instance = VerseService._internal();
  static VerseService get instance => _instance;
  VerseService._internal();

  final Logger _logger = Logger();
  final SmartSearchCache _cache = SmartSearchCache.instance;
  
  // Lazy injection - will be set by dependency injection
  VerseRepository? _repository;
  bool _isInitialized = false;
  
  VerseRepository get repository {
    if (_repository == null) {
      _repository = Modular.get<VerseRepository>();
      // Initialize the service when repository is first accessed
      if (!_isInitialized) {
        _isInitialized = true;
        initialize(); // Don't await to avoid blocking
      }
    }
    return _repository!;
  }

  // Reactive streams for real-time updates
  final BehaviorSubject<String> _currentSearchQuery = BehaviorSubject.seeded('');
  final BehaviorSubject<List<VerseRM>> _currentVerses = BehaviorSubject.seeded([]);
  final BehaviorSubject<bool> _isLoading = BehaviorSubject.seeded(false);
  final BehaviorSubject<String?> _error = BehaviorSubject.seeded(null);
  final BehaviorSubject<VersesLanguagePrefRM?> _languagePref = BehaviorSubject.seeded(null);
  
  // Individual verse streams for real-time updates (for interactive cards)
  final BehaviorSubject<Map<int, VerseRM>> _versesCache = BehaviorSubject.seeded({});
  final BehaviorSubject<Set<int>> _bookmarkedVerses = BehaviorSubject.seeded({});
  
  // Language change subscription
  StreamSubscription<VersesLanguagePrefRM?>? _languageChangeSubscription;

  // Public streams
  Stream<String> get searchQueryStream => _currentSearchQuery.stream;
  Stream<List<VerseRM>> get versesStream => _currentVerses.stream;
  Stream<bool> get isLoadingStream => _isLoading.stream;
  Stream<String?> get errorStream => _error.stream;
  Stream<VersesLanguagePrefRM?> get languagePrefStream => _languagePref.stream;
  Stream<Map<int, VerseRM>> get versesCacheStream => _versesCache.stream;
  Stream<Set<int>> get bookmarkedVersesStream => _bookmarkedVerses.stream;

  // Current values
  String get currentQuery => _currentSearchQuery.value;
  List<VerseRM> get currentVerses => _currentVerses.value;
  bool get isLoading => _isLoading.value;
  VersesLanguagePrefRM? get currentLanguagePref => _languagePref.value;

  @override
  void dispose() {
    _languageChangeSubscription?.cancel();
    _currentSearchQuery.close();
    _currentVerses.close();
    _isLoading.close();
    _error.close();
    _languagePref.close();
    _versesCache.close();
    _bookmarkedVerses.close();
  }

  /// Initialize service and load language preferences
  Future<void> initialize() async {
    try {
      final result = await repository.getlanguagePref();
      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        _languagePref.add(result.data);
      }
      _setupLanguageChangeListener();
    } catch (e) {
      // Language preferences initialization failed
    }
  }
  
  /// Setup listener for global language changes to refresh current verse results
  void _setupLanguageChangeListener() {
    try {
      _languageChangeSubscription = repository.mLanguagePrefObservable.listen((languagePref) {
        if (languagePref != null && _currentVerses.value.isNotEmpty) {
          // Language change detected
          // Refreshing verses for language change
          _refreshVersesForLanguageChange(languagePref);
        }
      });
    } catch (e) {
      // Language listener setup failed
    }
  }
  
  /// Silent refresh of current verses for language change by re-running original search
  Future<void> _refreshVersesForLanguageChange(VersesLanguagePrefRM languagePref) async {
    try {
      
      final currentVerses = _currentVerses.value;
      if (currentVerses.isEmpty) {
        return;
      }
      
      // Get the original search query instead of verse PKs
      final originalQuery = _currentSearchQuery.value;
      if (originalQuery.isEmpty) {
        print("🔄 PRASHNA TOOLS: No original query found, cannot refresh");
        return;
      }
      
      print("🔄 PRASHNA TOOLS: Re-running original query: '$originalQuery' with language: ${languagePref.output}");
      
      // Re-run the original search with new language preference
      // This will automatically use the current language preference from the repository
      final result = await repository.getVerses(inputStr: originalQuery);
      
      if (result.status == DomainResultStatus.SUCCESS && result.data?.verses != null) {
        final refreshedVerses = result.data!.verses;
        // Successfully fetched refreshed verses
        // Emitting updated verses with new language
        
        _currentVerses.add(refreshedVerses);
        _updateVersesCache(refreshedVerses);
        
        // Language successfully applied to verses
      } else {
        // Failed to refresh verses
      }
    } catch (e) {
      // Error refreshing verses with new language
    }
  }

  /// Search for verses with smart caching
  Future<void> searchVerses(String query, {bool forceRefresh = false}) async {
    if (query.trim().isEmpty) {
      _clearResults();
      return;
    }

    final trimmedQuery = query.trim();
    _currentSearchQuery.add(trimmedQuery);
    _error.add(null);

    // Check cache first for instant results (unless force refresh is requested)
    if (!forceRefresh) {
      final cached = _cache.getCachedVerses(trimmedQuery);
      if (cached != null) {
        // Using cached results
        _currentVerses.add(cached);
        _updateVersesCache(cached);
        _isLoading.add(false);
        return;
      }
    } else {
      // Force refresh - bypassing cache
    }

    // Cache miss - fetch from API
    _isLoading.add(true);
    
    try {
      final result = await repository.getVerses(inputStr: trimmedQuery);
      
      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        final verses = result.data!.verses;
        // Cache the result
        _cache.cacheVerses(trimmedQuery, verses);
        _currentVerses.add(verses);
        _updateVersesCache(verses);
        // Successfully fetched verses
      } else {
        final errorMessage = result.message ?? 'Failed to get verses';
        _error.add(errorMessage);
        // Error fetching verses
      }
    } catch (e) {
      final errorMessage = 'Search failed: $e';
      _error.add(errorMessage);
      // Exception during verse search
    } finally {
      _isLoading.add(false);
    }
  }

  /// Get specific verse by ID (for individual card updates)
  Stream<VerseRM?> getVerseStream(int versePk) {
    return _versesCache.stream.map((cache) => cache[versePk]);
  }

  /// Navigate to previous/next verse
  Future<void> navigateVerse(int versePk, bool isNext) async {
    try {
      final currentCache = _versesCache.value;
      final currentVerse = currentCache[versePk];
      
      if (currentVerse == null) {
        // Verse not found in cache
        return;
      }

      final result = isNext 
        ? await repository.getNextVerse(versePk: versePk.toString())
        : await repository.getPreviousVerse(versePk: versePk.toString());

      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        final newVerse = result.data!.getVerseData();
        if (newVerse != null) {
          // Add the new verse to cache (don't update the current one)
          final updatedCache = Map<int, VerseRM>.from(currentCache);
          updatedCache[newVerse.versePk] = newVerse; // Use new verse PK, not current
          _versesCache.add(updatedCache);
          
          // Update search results: Replace current verse with new verse
          final currentResults = _currentVerses.value;
          final updatedResults = currentResults.map((v) => 
            v.versePk == versePk ? newVerse : v // Replace current verse with new verse
          ).toList();
          _currentVerses.add(updatedResults.cast<VerseRM>());
          
          // Successfully navigated verse
        } else {
          // Navigate verse: API returned data but getVerseData() is null
        }
      } else {
        // Failed to navigate verse
      }
    } catch (e) {
      // Exception during verse navigation
    }
  }

  /// Toggle bookmark for a verse
  Future<void> toggleBookmark(int versePk) async {
    try {
      final currentCache = _versesCache.value;
      final currentVerse = currentCache[versePk];
      
      if (currentVerse == null) {
        // Verse not found in cache
        return;
      }

      final isCurrentlyBookmarked = currentVerse.isStarred ?? false;
      final result = await repository.toggleBookmark(
        versePk, 
        isToRemove: isCurrentlyBookmarked,
      );

      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        if (result.data!.success) {
          // Update bookmark status in verse
          final updatedVerse = VerseRM(
            versePk: currentVerse.versePk,
            verseRef: currentVerse.verseRef,
            verseText: currentVerse.verseText,
            verseLetText: currentVerse.verseLetText,
            verseLetOtherScripts: currentVerse.verseLetOtherScripts,
            verseOtherScripts: currentVerse.verseOtherScripts,
            verseLetPart: currentVerse.verseLetPart,
            isStarred: !isCurrentlyBookmarked,
            otherFields: currentVerse.otherFields,
            sourceTitle: currentVerse.sourceTitle,
            sourceName: currentVerse.sourceName,
            sourceUrl: currentVerse.sourceUrl,
            similarity: currentVerse.similarity,
          );

          // Update cache
          final updatedCache = Map<int, VerseRM>.from(currentCache);
          updatedCache[versePk] = updatedVerse;
          _versesCache.add(updatedCache);

          // Update search results
          final currentResults = _currentVerses.value;
          final updatedResults = currentResults.map((v) => 
            v.versePk == versePk ? updatedVerse : v
          ).toList();
          _currentVerses.add(updatedResults.cast<VerseRM>());

          // Update bookmarked verses set
          final bookmarked = _bookmarkedVerses.value;
          final updatedBookmarked = Set<int>.from(bookmarked);
          if (!isCurrentlyBookmarked) {
            updatedBookmarked.add(versePk);
          } else {
            updatedBookmarked.remove(versePk);
          }
          _bookmarkedVerses.add(updatedBookmarked);

          // Successfully toggled bookmark
        }
      } else {
        // Failed to toggle bookmark
      }
    } catch (e) {
      // Exception during bookmark toggle
    }
  }

  /// Get verse bookmarks
  Future<VerseBookmarksResultRM?> getBookmarks() async {
    try {
      final result = await repository.getVerseBookmarks();
      
      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        // Update bookmarked verses set
        final bookmarks = result.data!.verse.map((b) => b.pk).toSet();
        _bookmarkedVerses.add(bookmarks);
        return result.data;
      } else {
        // Failed to get bookmarks
        return null;
      }
    } catch (e) {
      // Exception getting bookmarks
      return null;
    }
  }

  /// Get search history
  Future<SearchHistoryResultRM?> getSearchHistory() async {
    try {
      final result = await repository.getSearchHistory();
      
      if (result.status == DomainResultStatus.SUCCESS) {
        return result.data;
      } else {
        // Failed to get search history
        return null;
      }
    } catch (e) {
      // Exception getting search history
      return null;
    }
  }

  /// Update language preference
  Future<void> updateLanguagePreference(String output) async {
    try {
      final result = await repository.getlanguagePref(output: output);
      
      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        _languagePref.add(result.data);
        
        // Clear cache to force refresh with new language
        _cache.clearVersesCache();
        
        // If there's a current query, re-search with new language
        if (_currentSearchQuery.value.isNotEmpty) {
          await searchVerses(_currentSearchQuery.value);
        }
        
        // Successfully updated language preference
      } else {
        // Failed to update language preference
      }
    } catch (e) {
      // Exception updating language preference
    }
  }

  /// Clear current search results
  void clearResults() {
    _clearResults();
  }

  void _clearResults() {
    _currentSearchQuery.add('');
    _currentVerses.add([]);
    _error.add(null);
    _isLoading.add(false);
  }

  /// Update verses cache with new verses
  void _updateVersesCache(List<VerseRM> verses) {
    final currentCache = _versesCache.value;
    final updatedCache = Map<int, VerseRM>.from(currentCache);
    
    for (final verse in verses) {
      updatedCache[verse.versePk] = verse;
    }
    
    _versesCache.add(updatedCache);
  }

  /// Add a single verse to cache (public method for external services)
  void addVerseToCache(VerseRM verse) {
    final currentCache = _versesCache.value;
    final updatedCache = Map<int, VerseRM>.from(currentCache);
    updatedCache[verse.versePk] = verse;
    _versesCache.add(updatedCache);
  }

  /// Get cached verses without triggering new search
  List<VerseRM>? getCachedVerses(String query) {
    return _cache.getCachedVerses(query.trim());
  }

  /// Check if query is cached
  bool hasCachedVerses(String query) {
    return _cache.hasVerses(query.trim());
  }

  /// Clear cache
  void clearCache() {
    _cache.clearVersesCache();
    // Verse cache cleared
  }

  /// Trigger search query event (for compatibility with existing code)
  void onNewSearchQuery(String? searchQuery) {
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      searchVerses(searchQuery.trim());
    } else {
      clearResults();
    }
  }
}
