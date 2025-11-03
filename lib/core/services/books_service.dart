import 'dart:async';
import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/domain/books/repo.dart';
import 'package:dharak_flutter/app/types/books/book_chunk.dart';
import 'package:dharak_flutter/app/types/books/book_chunks_result.dart' as book_chunks_result;
import 'package:dharak_flutter/app/types/books/book_chunk_nav_result.dart';
import 'package:dharak_flutter/core/cache/smart_search_cache.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:dio/dio.dart';

/// Optimized Books Service with smart caching and reactive streams
class BooksService extends Disposable {
  static final BooksService _instance = BooksService._internal();
  static BooksService get instance => _instance;
  
  BooksService._internal() {
    // Get the authenticated Dio instance from dependency injection
    _dio = Modular.get<Dio>();
    _repository = BooksRepositoryImpl(mDio: _dio);
  }

  final SmartSearchCache _cache = SmartSearchCache.instance;
  late final Dio _dio; // Will be initialized with authenticated Dio from Modular
  
  // Repository for API calls
  late final BooksRepository _repository;
  
  // Reactive streams for real-time updates
  final BehaviorSubject<List<BookChunkRM>> _currentBookChunks = BehaviorSubject.seeded([]);
  Stream<List<BookChunkRM>> get currentBookChunks => _currentBookChunks.stream;
  
  // Cache for chunk management (similar to verse service)
  final BehaviorSubject<Map<int, BookChunkRM>> _chunksCache = BehaviorSubject.seeded({});
  Stream<Map<int, BookChunkRM>> get chunksCache => _chunksCache.stream;

  /// Search for book chunks with smart caching
  Future<List<BookChunkRM>> searchBookChunks(String query) async {
    try {
      // Check cache first for instant results
      final cachedResult = _cache.getBookChunks(query);
      if (cachedResult != null) {
        _currentBookChunks.add(cachedResult);
        return cachedResult;
      }

      
      // Make API call
      final response = await _dio.get(
        'https://project.iith.ac.in/bheri/chunk/multivec/',
        queryParameters: {'inp_str': query},
        options: Options(
          headers: {'accept': '*/*'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final result = book_chunks_result.BookChunksResultRM.fromJson(response.data);
        
        if (result.success && result.data.isNotEmpty) {
          // Cache the result for future use
          _cache.setBookChunks(query, result.data);
          
          // Update reactive stream
          _currentBookChunks.add(result.data);
          
          // Also populate chunks cache for navigation
          final chunksMap = <int, BookChunkRM>{};
          for (final chunk in result.data) {
            if (chunk.chunkRefId != null) {
              chunksMap[chunk.chunkRefId!] = chunk;
            }
          }
          _chunksCache.add(chunksMap);
          
          return result.data;
        }
      }
      
      return [];
      
    } catch (e) {
      return [];
    }
  }

  /// Clear current book chunks
  void clearBookChunks() {
    _currentBookChunks.add([]);
  }

  /// Navigate to next/previous chunk - SIMPLIFIED WITHOUT CACHE DEPENDENCY
  Future<BookChunkRM?> navigateChunk(int chunkRefId, bool isNext) async {
    try {

      final result = isNext 
        ? await _repository.getNextChunk(chunkRefId: chunkRefId.toString())
        : await _repository.getPreviousChunk(chunkRefId: chunkRefId.toString());

      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        final newChunk = isNext 
          ? (result.data as BookChunkNextResultRM).getNextChunk()
          : (result.data as BookChunkPrevResultRM).getPrevChunk();
          
        if (newChunk != null) {
          // OPTIONAL: Add to cache if cache exists (for QuickSearch compatibility)
          final currentCache = _chunksCache.value;
          if (currentCache.isNotEmpty) {
            final updatedCache = Map<int, BookChunkRM>.from(currentCache);
            if (newChunk.chunkRefId != null) {
              updatedCache[newChunk.chunkRefId!] = newChunk;
            }
            _chunksCache.add(updatedCache);
            
            // Update search results ONLY if we have current results
            final currentResults = _currentBookChunks.value;
            if (currentResults.isNotEmpty) {
              final updatedResults = currentResults.map((c) => 
                c.chunkRefId == chunkRefId ? newChunk : c
              ).toList();
              _currentBookChunks.add(updatedResults);
            }
          }
          
          return newChunk; // Return the new chunk for local state updates
        } else {
        }
      } else {
      }
    } catch (e) {
    }
    return null; // Return null if navigation failed
  }

  /// Add chunk to cache (for external use)
  void addChunkToCache(BookChunkRM chunk) {
    if (chunk.chunkRefId != null) {
      final currentCache = _chunksCache.value;
      final updatedCache = Map<int, BookChunkRM>.from(currentCache);
      updatedCache[chunk.chunkRefId!] = chunk;
      _chunksCache.add(updatedCache);
    }
  }

  /// Toggle bookmark for a chunk (similar to VerseService.toggleBookmark)
  Future<void> toggleBookmark(int chunkRefId) async {
    try {
      final currentCache = _chunksCache.value;
      final currentChunk = currentCache[chunkRefId];
      
      // If chunk not in cache, still proceed with API call (common in modal contexts)
      final isCurrentlyBookmarked = currentChunk?.isStarred ?? false;
      
      if (currentChunk == null) {
      }
      final result = await _repository.toggleBookmark(
        chunkRefId, 
        isToRemove: isCurrentlyBookmarked,
      );

      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        // Handle nullable success field - if null, assume success based on API response
        final isSuccessful = result.data!.success ?? true;
        if (isSuccessful) {
          // Only update cache if chunk was originally in cache
          if (currentChunk != null) {
            // Update bookmark status in chunk
            final updatedChunk = currentChunk.copyWith(
              isStarred: !isCurrentlyBookmarked,
            );
            
            // Update cache
            final updatedCache = Map<int, BookChunkRM>.from(currentCache);
            updatedCache[chunkRefId] = updatedChunk;
            _chunksCache.add(updatedCache);
            
            // Update current search results if chunk is in them
            final currentResults = _currentBookChunks.value;
            if (currentResults.isNotEmpty) {
              final updatedResults = currentResults.map((c) => 
                c.chunkRefId == chunkRefId ? updatedChunk : c
              ).toList();
              _currentBookChunks.add(updatedResults);
            }
          }
          
        } else {
        }
      } else {
      }
    } catch (e) {
    }
  }

  /// Get starred/bookmarked chunks
  Future<List<BookChunkRM>> getStarredChunks() async {
    try {
      
      final result = await _repository.getStarredChunks();
      
      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        final starredChunks = result.data!.chunks;
        
        // Add starred chunks to cache
        final currentCache = _chunksCache.value;
        final updatedCache = Map<int, BookChunkRM>.from(currentCache);
        for (final chunk in starredChunks) {
          if (chunk.chunkRefId != null) {
            updatedCache[chunk.chunkRefId!] = chunk;
          }
        }
        _chunksCache.add(updatedCache);
        
        return starredChunks;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    _currentBookChunks.close();
    _chunksCache.close();
  }
}

