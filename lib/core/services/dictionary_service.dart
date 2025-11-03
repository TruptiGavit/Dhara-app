import 'dart:async';
import 'package:dharak_flutter/app/domain/dictionary/repo.dart';
import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/types/dictionary/word_definitions.dart';
import 'package:dharak_flutter/app/types/search-history/result.dart';
import 'package:dharak_flutter/core/cache/smart_search_cache.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

/// Optimized Dictionary Service with smart caching and reactive streams
class DictionaryService extends Disposable {
  static final DictionaryService _instance = DictionaryService._internal();
  static DictionaryService get instance => _instance;
  DictionaryService._internal();

  final SmartSearchCache _cache = SmartSearchCache.instance;
  
  // Lazy injection - will be set by dependency injection
  DictionaryRepository? _repository;
  DictionaryRepository get repository {
    _repository ??= Modular.get<DictionaryRepository>();
    return _repository!;
  }

  // Reactive streams for real-time updates
  final BehaviorSubject<String> _currentSearchQuery = BehaviorSubject.seeded('');
  final BehaviorSubject<DictWordDefinitionsRM?> _currentDefinitions = BehaviorSubject.seeded(null);
  final BehaviorSubject<bool> _isLoading = BehaviorSubject.seeded(false);
  final BehaviorSubject<String?> _error = BehaviorSubject.seeded(null);

  // Public streams
  Stream<String> get searchQueryStream => _currentSearchQuery.stream;
  Stream<DictWordDefinitionsRM?> get definitionsStream => _currentDefinitions.stream;
  Stream<bool> get isLoadingStream => _isLoading.stream;
  Stream<String?> get errorStream => _error.stream;

  // Current values
  String get currentQuery => _currentSearchQuery.value;
  DictWordDefinitionsRM? get currentDefinitions => _currentDefinitions.value;
  bool get isLoading => _isLoading.value;

  @override
  void dispose() {
    _currentSearchQuery.close();
    _currentDefinitions.close();
    _isLoading.close();
    _error.close();
  }

  /// Search for word definitions with smart caching
  Future<void> searchDefinitions(String word) async {
    if (word.trim().isEmpty) {
      _clearResults();
      return;
    }

    final trimmedWord = word.trim();
    _currentSearchQuery.add(trimmedWord);
    _error.add(null);

    // Check cache first for instant results
    final cached = _cache.getCachedDefinitions(trimmedWord);
    if (cached != null) {
      _currentDefinitions.add(cached);
      _isLoading.add(false);
      return;
    }

    // Cache miss - fetch from API
    _isLoading.add(true);
    
    try {
      final result = await repository.getDefinition(word: trimmedWord);
      
      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        // Cache the result
        _cache.cacheDefinitions(trimmedWord, result.data!);
        _currentDefinitions.add(result.data);
      } else {
        final errorMessage = result.message ?? 'Failed to get word definitions';
        _error.add(errorMessage);
      }
    } catch (e) {
      final errorMessage = 'Search failed: $e';
      _error.add(errorMessage);
    } finally {
      _isLoading.add(false);
    }
  }

  /// Get search history
  Future<SearchHistoryResultRM?> getSearchHistory() async {
    try {
      final result = await repository.getSearchHistory();
      
      if (result.status == DomainResultStatus.SUCCESS) {
        return result.data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Clear current search results
  void clearResults() {
    _clearResults();
  }

  void _clearResults() {
    _currentSearchQuery.add('');
    _currentDefinitions.add(null);
    _error.add(null);
    _isLoading.add(false);
  }

  /// Get cached result without triggering new search
  DictWordDefinitionsRM? getCachedDefinitions(String word) {
    return _cache.getCachedDefinitions(word.trim());
  }

  /// Check if word is cached
  bool hasCachedDefinitions(String word) {
    return _cache.hasDefinitions(word.trim());
  }

  /// Clear cache
  void clearCache() {
    _cache.clearDefinitionsCache();
  }

  /// Trigger search query event (for compatibility with existing code)
  void onNewSearchQuery(String? searchQuery) {
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      searchDefinitions(searchQuery.trim());
    } else {
      clearResults();
    }
  }
}

