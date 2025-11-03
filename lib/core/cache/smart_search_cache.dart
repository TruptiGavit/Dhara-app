import 'package:dharak_flutter/app/types/dictionary/word_definitions.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/types/books/book_chunk.dart';
import 'package:dharak_flutter/app/types/unified/unified_response.dart';

/// LRU Cache for optimized search results across different types
class SmartSearchCache {
  static final SmartSearchCache _instance = SmartSearchCache._internal();
  static SmartSearchCache get instance => _instance;
  SmartSearchCache._internal();

  // Cache size limits
  static const int _maxCacheSize = 10;

  // Dictionary cache
  final Map<String, DictWordDefinitionsRM> _dictCache = <String, DictWordDefinitionsRM>{};
  final List<String> _dictKeys = <String>[];

  // Verse cache
  final Map<String, List<VerseRM>> _versesCache = <String, List<VerseRM>>{};
  final List<String> _verseKeys = <String>[];

  // Books cache
  final Map<String, List<BookChunkRM>> _bookChunksCache = <String, List<BookChunkRM>>{};
  final List<String> _bookKeys = <String>[];

  // Unified cache
  final Map<String, UnifiedSearchResult> _unifiedCache = <String, UnifiedSearchResult>{};
  final List<String> _unifiedKeys = <String>[];

  // Dictionary methods
  void cacheDictionary(String query, DictWordDefinitionsRM result) {
    _addToCache(_dictCache, _dictKeys, query, result);
  }

  DictWordDefinitionsRM? getCachedDictionary(String query) {
    return _getFromCache(_dictCache, _dictKeys, query);
  }

  bool hasDictionary(String query) {
    return _dictCache.containsKey(query);
  }

  void clearDictionaryCache() {
    _dictCache.clear();
    _dictKeys.clear();
  }

  // Legacy method names for compatibility
  void cacheDefinitions(String query, DictWordDefinitionsRM result) {
    cacheDictionary(query, result);
  }

  DictWordDefinitionsRM? getCachedDefinitions(String query) {
    return getCachedDictionary(query);
  }

  bool hasDefinitions(String query) {
    return hasDictionary(query);
  }

  void clearDefinitionsCache() {
    clearDictionaryCache();
  }

  // Verse methods
  void cacheVerses(String query, List<VerseRM> verses) {
    _addToCache(_versesCache, _verseKeys, query, verses);
  }

  List<VerseRM>? getCachedVerses(String query) {
    return _getFromCache(_versesCache, _verseKeys, query);
  }

  bool hasVerses(String query) {
    return _versesCache.containsKey(query);
  }

  void clearVersesCache() {
    _versesCache.clear();
    _verseKeys.clear();
  }

  // Books methods
  void cacheBookChunks(String query, List<BookChunkRM> chunks) {
    _addToCache(_bookChunksCache, _bookKeys, query, chunks);
  }

  List<BookChunkRM>? getCachedBookChunks(String query) {
    return _getFromCache(_bookChunksCache, _bookKeys, query);
  }

  bool hasBookChunks(String query) {
    return _bookChunksCache.containsKey(query);
  }

  void clearBookChunksCache() {
    _bookChunksCache.clear();
    _bookKeys.clear();
  }

  // Legacy method names for compatibility
  List<BookChunkRM>? getBookChunks(String query) {
    return getCachedBookChunks(query);
  }

  void setBookChunks(String query, List<BookChunkRM> chunks) {
    cacheBookChunks(query, chunks);
  }

  // Unified methods
  void setUnifiedResult(String query, UnifiedSearchResult result) {
    _addToCache(_unifiedCache, _unifiedKeys, query, result);
  }

  UnifiedSearchResult? getUnifiedResult(String query) {
    return _getFromCache(_unifiedCache, _unifiedKeys, query);
  }

  bool hasUnifiedResult(String query) {
    return _unifiedCache.containsKey(query);
  }

  void clearUnifiedResult(String query) {
    _unifiedCache.remove(query);
    _unifiedKeys.remove(query);
  }

  void clearUnifiedCache() {
    _unifiedCache.clear();
    _unifiedKeys.clear();
  }

  // Generic LRU cache implementation
  void _addToCache<T>(Map<String, T> cache, List<String> keys, String key, T value) {
    // If key exists, remove it from its current position
    if (cache.containsKey(key)) {
      keys.remove(key);
    }
    // If cache is full, remove the least recently used item
    else if (cache.length >= _maxCacheSize) {
      final oldestKey = keys.removeAt(0);
      cache.remove(oldestKey);
    }

    // Add new item
    cache[key] = value;
    keys.add(key);
  }

  T? _getFromCache<T>(Map<String, T> cache, List<String> keys, String key) {
    if (!cache.containsKey(key)) return null;

    // Move to end (most recently used)
    keys.remove(key);
    keys.add(key);
    
    return cache[key];
  }

  // Clear all caches
  void clearAllCaches() {
    clearDictionaryCache();
    clearVersesCache();
    clearBookChunksCache();
    clearUnifiedCache();
  }

  // Get cache stats
  Map<String, int> getCacheStats() {
    return {
      'dictionary': _dictCache.length,
      'verses': _versesCache.length,
      'books': _bookChunksCache.length,
      'unified': _unifiedCache.length,
    };
  }
}