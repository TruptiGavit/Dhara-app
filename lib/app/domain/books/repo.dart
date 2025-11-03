import 'dart:async';

import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/types/books/chunk.dart';
import 'package:dharak_flutter/app/types/books/book_chunk_nav_result.dart';
import 'package:dharak_flutter/app/types/books/book_chunk_augmentation.dart';
import 'package:dharak_flutter/app/types/books/book_bookmark_result.dart';
import 'package:dharak_flutter/app/types/books/book_citation.dart';
import 'package:dharak_flutter/app/data/remote/api/constants.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/subjects.dart';

abstract class BooksRepository {
  Future<DomainResult<BookChunksResponseRM>> searchChunks({required String query});
  
  // Navigation methods
  Future<DomainResult<BookChunkNextResultRM>> getNextChunk({required String chunkRefId});
  Future<DomainResult<BookChunkPrevResultRM>> getPreviousChunk({required String chunkRefId});
  
  // 🆕 Augmentation methods
  Future<DomainResult<BookChunkAugmentationListRM>> getAugmentationList({required String chunkRefId});
  Future<DomainResult<BookChunkAugmentedRM>> getAugmentedChunk({required String text});
  Future<DomainResult<BookChunkOriginalRM>> getOriginalChunk({required String chunkRefId});
  
  // 🔖 Bookmark methods (similar to verse repository)
  Future<DomainResult<BookChunkBookmarkToggleResultRM>> toggleBookmark(int chunkRefId, {bool isToRemove = true});
  Future<DomainResult<BookChunkStarredListResultRM>> getStarredChunks();
  
  // 📝 Citation methods (similar to verse repository)
  Future<DomainResult<BookChunkCitationRM>> getChunkCitation({required int chunkRefId});
  
  // 📤 Share methods (similar to verse repository)
  Future<DomainResult<String>> shareChunkAsText({required int chunkRefId});
  Future<DomainResult<String>> shareChunkAsImage({required int chunkRefId});
  
  // Event streams for cache management
  BehaviorSubject<String> get mCurrentSearchWordObservable;
  BehaviorSubject<BookChunksResponseRM?> get mChunkResultsObservable;
  BehaviorSubject<String> get mEventSearchQuery;
}

class BooksRepositoryImpl implements BooksRepository {
  final Dio mDio;

  // Event streams for cache management and communication
  final BehaviorSubject<String> _mCurrentSearchWord = BehaviorSubject<String>.seeded('');
  final BehaviorSubject<BookChunksResponseRM?> _mChunkResults = BehaviorSubject<BookChunksResponseRM?>.seeded(null);
  final BehaviorSubject<String> _mEventSearchQuery = BehaviorSubject<String>();
  
  // 🚀 PERFORMANCE: Smart caching like WordDefine
  String? _lastSearchQuery;
  DateTime? _lastSearchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 15); // 15-minute TTL like WordDefine

  BooksRepositoryImpl({required this.mDio});

  @override
  BehaviorSubject<String> get mCurrentSearchWordObservable => _mCurrentSearchWord;

  @override
  BehaviorSubject<BookChunksResponseRM?> get mChunkResultsObservable => _mChunkResults;

  @override
  BehaviorSubject<String> get mEventSearchQuery => _mEventSearchQuery;

  // 🚀 PERFORMANCE: Cache validation methods (like WordDefine)
  bool _isCacheValid(String query) {
    if (_lastSearchQuery != query) return false;
    if (_lastSearchTime == null) return false;
    
    final timeSinceLastSearch = DateTime.now().difference(_lastSearchTime!);
    return timeSinceLastSearch < _cacheValidDuration;
  }
  
  BookChunksResponseRM? _getCachedResult(String query) {
    if (!_isCacheValid(query)) return null;
    return _mChunkResults.valueOrNull;
  }
  
  void _updateCache(String query, BookChunksResponseRM result) {
    _lastSearchQuery = query;
    _lastSearchTime = DateTime.now();
    _mChunkResults.add(result);
    _mCurrentSearchWord.add(query);
  }

  @override
  Future<DomainResult<BookChunksResponseRM>> searchChunks({required String query}) async {
    try {
      // 🚀 PERFORMANCE: Check cache first (like WordDefine)
      final cachedResult = _getCachedResult(query);
      if (cachedResult != null) {
        return DomainResult<BookChunksResponseRM>(
          DomainResultStatus.SUCCESS,
          data: cachedResult,
        );
      }
      
      // Update current search word for cache
      _mCurrentSearchWord.add(query);
      
      final response = await mDio.get(
        'https://project.iith.ac.in/bheri/chunk/multivec/',
        queryParameters: {'inp_str': query},
      );

      if (response.statusCode == 200) {
        final booksResponse = BookChunksResponseRM.fromJson(response.data);
        
        // 🚀 PERFORMANCE: Update cache with smart TTL
        _updateCache(query, booksResponse);
        
        return DomainResult<BookChunksResponseRM>(
          DomainResultStatus.SUCCESS,
          data: booksResponse,
        );
      } else {
        return DomainResult<BookChunksResponseRM>(
          DomainResultStatus.ERROR,
          message: 'Failed to search books: ${response.statusCode}',
        );
      }
    } catch (e) {
      return DomainResult<BookChunksResponseRM>(
        DomainResultStatus.ERROR,
        message: 'Error searching books: ${e.toString()}',
      );
    }
  }

  @override
  Future<DomainResult<BookChunkNextResultRM>> getNextChunk({required String chunkRefId}) async {
    try {
      
      final response = await mDio.get(
        'https://project.iith.ac.in/bheri/chunk/next/$chunkRefId/',
        options: Options(
          headers: {
            'accept': '*/*',
            ApiConstants.HEADER_REQUIRE_TOKEN: true, // Signal auth interceptor to add authentication
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final nextResult = BookChunkNextResultRM.fromJson(response.data);
        
        
        return DomainResult<BookChunkNextResultRM>(
          DomainResultStatus.SUCCESS,
          data: nextResult,
        );
      } else {
        return DomainResult<BookChunkNextResultRM>(
          DomainResultStatus.ERROR,
          message: 'Failed to get next chunk: ${response.statusCode}',
        );
      }
    } catch (e) {
      return DomainResult<BookChunkNextResultRM>(
        DomainResultStatus.ERROR,
        message: 'Error getting next chunk: ${e.toString()}',
      );
    }
  }

  @override
  Future<DomainResult<BookChunkPrevResultRM>> getPreviousChunk({required String chunkRefId}) async {
    try {
      
      final response = await mDio.get(
        'https://project.iith.ac.in/bheri/chunk/prev/$chunkRefId/',
        options: Options(
          headers: {
            'accept': '*/*',
            ApiConstants.HEADER_REQUIRE_TOKEN: true, // Signal auth interceptor to add authentication
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final prevResult = BookChunkPrevResultRM.fromJson(response.data);
        
        
        return DomainResult<BookChunkPrevResultRM>(
          DomainResultStatus.SUCCESS,
          data: prevResult,
        );
      } else {
        return DomainResult<BookChunkPrevResultRM>(
          DomainResultStatus.ERROR,
          message: 'Failed to get previous chunk: ${response.statusCode}',
        );
      }
    } catch (e) {
      return DomainResult<BookChunkPrevResultRM>(
        DomainResultStatus.ERROR,
        message: 'Error getting previous chunk: ${e.toString()}',
      );
    }
  }

  @override
  Future<DomainResult<BookChunkAugmentationListRM>> getAugmentationList({required String chunkRefId}) async {
    try {
      
      final response = await mDio.get(
        'https://project.iith.ac.in/bheri/chunk/auglist/$chunkRefId/',
        options: Options(
          headers: {
            'accept': '*/*',
            ApiConstants.HEADER_REQUIRE_TOKEN: true, // Authentication required
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final augmentationResult = BookChunkAugmentationListRM.fromJson(response.data);
        
        
        return DomainResult<BookChunkAugmentationListRM>(
          DomainResultStatus.SUCCESS,
          data: augmentationResult,
        );
      } else {
        return DomainResult<BookChunkAugmentationListRM>(
          DomainResultStatus.ERROR,
          message: 'Failed to get augmentation list: ${response.statusCode} - ${response.statusMessage}',
        );
      }
    } catch (e) {
      
      String errorMessage = 'Error getting augmentation list';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          errorMessage = 'Authentication failed - please login again';
        } else if (e.response?.statusCode == 400) {
          errorMessage = 'Invalid chunk ID - this chunk may not be a merged augmentation';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Chunk not found';
        } else {
          errorMessage = 'Network error: ${e.response?.statusCode ?? 'Unknown'}';
        }
      }
      
      return DomainResult<BookChunkAugmentationListRM>(
        DomainResultStatus.ERROR,
        message: errorMessage,
      );
    }
  }

  @override
  Future<DomainResult<BookChunkAugmentedRM>> getAugmentedChunk({required String text}) async {
    try {
      
      final response = await mDio.get(
        'https://project.iith.ac.in/bheri/chunk/get_aug/',
        queryParameters: {'text': text},
        options: Options(
          headers: {
            'accept': '*/*',
            ApiConstants.HEADER_REQUIRE_TOKEN: true, // Authentication required
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final augmentedResult = BookChunkAugmentedRM.fromJson(response.data);
        
        
        return DomainResult<BookChunkAugmentedRM>(
          DomainResultStatus.SUCCESS,
          data: augmentedResult,
        );
      } else {
        return DomainResult<BookChunkAugmentedRM>(
          DomainResultStatus.ERROR,
          message: 'Failed to get augmented chunk: ${response.statusCode}',
        );
      }
    } catch (e) {
      
      String errorMessage = 'Unable to load augmented content';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          errorMessage = 'Please login to view this content';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Content not found';
        } else if (e.response?.statusCode == 500) {
          errorMessage = 'Server error. Please try again later';
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
          errorMessage = 'Connection failed. Please check your internet';
        }
      }
      
      return DomainResult<BookChunkAugmentedRM>(
        DomainResultStatus.ERROR,
        message: errorMessage,
      );
    }
  }

  @override
  Future<DomainResult<BookChunkOriginalRM>> getOriginalChunk({required String chunkRefId}) async {
    try {
      
      final response = await mDio.get(
        'https://project.iith.ac.in/bheri/chunk/get_orig/$chunkRefId/',
        options: Options(
          headers: {
            'accept': '*/*',
            ApiConstants.HEADER_REQUIRE_TOKEN: true, // Authentication required
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final originalResult = BookChunkOriginalRM.fromJson(response.data);
        
        
        return DomainResult<BookChunkOriginalRM>(
          DomainResultStatus.SUCCESS,
          data: originalResult,
        );
      } else if (response.statusCode == 403) {
        return DomainResult<BookChunkOriginalRM>(
          DomainResultStatus.ERROR,
          message: 'This content does not have an original source available',
        );
      } else if (response.statusCode == 404) {
        return DomainResult<BookChunkOriginalRM>(
          DomainResultStatus.ERROR,
          message: 'Original source not found for this content',
        );
      } else {
        return DomainResult<BookChunkOriginalRM>(
          DomainResultStatus.ERROR,
          message: 'Failed to get original source: ${response.statusCode}',
        );
      }
    } catch (e) {
      
      String errorMessage = 'Unable to load original source';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          errorMessage = 'Please login to view this content';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Original source not found';
        } else if (e.response?.statusCode == 500) {
          errorMessage = 'Server error. Please try again later';
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
          errorMessage = 'Connection failed. Please check your internet';
        }
      }
      
      return DomainResult<BookChunkOriginalRM>(
        DomainResultStatus.ERROR,
        message: errorMessage,
      );
    }
  }

  @override
  Future<DomainResult<BookChunkBookmarkToggleResultRM>> toggleBookmark(int chunkRefId, {bool isToRemove = true}) async {
    try {
      
      final endpoint = isToRemove 
        ? 'https://project.iith.ac.in/bheri/chunk/unstar/$chunkRefId/'
        : 'https://project.iith.ac.in/bheri/chunk/star/$chunkRefId/';
      
      final response = await mDio.get(
        endpoint,
        options: Options(
          headers: {
            'accept': '*/*',
            ApiConstants.HEADER_REQUIRE_TOKEN: true, // Authentication required
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final bookmarkResult = BookChunkBookmarkToggleResultRM.fromJson(response.data);
        
        
        return DomainResult<BookChunkBookmarkToggleResultRM>(
          DomainResultStatus.SUCCESS,
          data: bookmarkResult,
        );
      } else if (response.statusCode == 400) {
        // Handle "already bookmarked" case
        final bookmarkResult = BookChunkBookmarkToggleResultRM.fromJson(response.data);
        
        return DomainResult<BookChunkBookmarkToggleResultRM>(
          DomainResultStatus.SUCCESS, // Still treat as success but with message
          data: bookmarkResult,
        );
      } else if (response.statusCode == 404) {
        return DomainResult<BookChunkBookmarkToggleResultRM>(
          DomainResultStatus.ERROR,
          message: 'Chunk not found',
        );
      } else {
        return DomainResult<BookChunkBookmarkToggleResultRM>(
          DomainResultStatus.ERROR,
          message: 'Failed to toggle bookmark: ${response.statusCode}',
        );
      }
    } catch (e) {
      
      String errorMessage = 'Error toggling bookmark';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          errorMessage = 'Authentication failed - please login again';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Chunk not found';
        } else {
          errorMessage = 'Network error: ${e.response?.statusCode ?? 'Unknown'}';
        }
      }
      
      return DomainResult<BookChunkBookmarkToggleResultRM>(
        DomainResultStatus.ERROR,
        message: errorMessage,
      );
    }
  }

  @override
  Future<DomainResult<BookChunkStarredListResultRM>> getStarredChunks() async {
    try {
      
      final response = await mDio.get(
        'https://project.iith.ac.in/bheri/chunk/get_starred/',
        options: Options(
          headers: {
            'accept': '*/*',
            ApiConstants.HEADER_REQUIRE_TOKEN: true, // Authentication required
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final starredResult = BookChunkStarredListResultRM.fromJson(response.data);
        
        
        return DomainResult<BookChunkStarredListResultRM>(
          DomainResultStatus.SUCCESS,
          data: starredResult,
        );
      } else {
        return DomainResult<BookChunkStarredListResultRM>(
          DomainResultStatus.ERROR,
          message: 'Failed to get starred chunks: ${response.statusCode}',
        );
      }
    } catch (e) {
      
      String errorMessage = 'Error getting starred chunks';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          errorMessage = 'Authentication failed - please login again';
        } else {
          errorMessage = 'Network error: ${e.response?.statusCode ?? 'Unknown'}';
        }
      }
      
      return DomainResult<BookChunkStarredListResultRM>(
        DomainResultStatus.ERROR,
        message: errorMessage,
      );
    }
  }

  @override
  Future<DomainResult<BookChunkCitationRM>> getChunkCitation({required int chunkRefId}) async {
    try {
      
      final response = await mDio.get(
        'https://project.iith.ac.in/bheri/chunk/cite/$chunkRefId/',
        options: Options(
          headers: {
            'accept': '*/*',
            ApiConstants.HEADER_REQUIRE_TOKEN: true, // Authentication required
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final citationResult = BookChunkCitationRM.fromJson(response.data);
        
        
        return DomainResult<BookChunkCitationRM>(
          DomainResultStatus.SUCCESS,
          data: citationResult,
        );
      } else if (response.statusCode == 404) {
        return DomainResult<BookChunkCitationRM>(
          DomainResultStatus.ERROR,
          message: 'Citation not available for this chunk',
        );
      } else {
        return DomainResult<BookChunkCitationRM>(
          DomainResultStatus.ERROR,
          message: 'Failed to get citation: ${response.statusCode}',
        );
      }
    } catch (e) {
      
      String errorMessage = 'Error getting citation';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          errorMessage = 'Authentication failed - please login again';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Citation not found';
        } else {
          errorMessage = 'Network error: ${e.response?.statusCode ?? 'Unknown'}';
        }
      }
      
      return DomainResult<BookChunkCitationRM>(
        DomainResultStatus.ERROR,
        message: errorMessage,
      );
    }
  }

  @override
  Future<DomainResult<String>> shareChunkAsText({required int chunkRefId}) async {
    try {
      
      final response = await mDio.get(
        'https://project.iith.ac.in/bheri/share/',
        queryParameters: {
          'chunk_id': chunkRefId,
          'platform': 'app',
          'type': 'text',
        },
        options: Options(
          headers: {
            'accept': '*/*',
            ApiConstants.HEADER_REQUIRE_TOKEN: true, // Authentication required
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final shareText = response.data.toString();
        
        
        return DomainResult<String>(
          DomainResultStatus.SUCCESS,
          data: shareText,
        );
      } else {
        return DomainResult<String>(
          DomainResultStatus.ERROR,
          message: 'Failed to get share content: ${response.statusCode}',
        );
      }
    } catch (e) {
      
      String errorMessage = 'Error getting share content';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          errorMessage = 'Authentication failed - please login again';
        } else {
          errorMessage = 'Network error: ${e.response?.statusCode ?? 'Unknown'}';
        }
      }
      
      return DomainResult<String>(
        DomainResultStatus.ERROR,
        message: errorMessage,
      );
    }
  }

  @override
  Future<DomainResult<String>> shareChunkAsImage({required int chunkRefId}) async {
    try {
      
      final response = await mDio.get(
        'https://project.iith.ac.in/bheri/share/',
        queryParameters: {
          'chunk_id': chunkRefId,
          'platform': 'app',
          'type': 'image',
        },
        options: Options(
          headers: {
            'accept': '*/*',
            ApiConstants.HEADER_REQUIRE_TOKEN: true, // Authentication required
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final shareImageContent = response.data.toString();
        
        
        return DomainResult<String>(
          DomainResultStatus.SUCCESS,
          data: shareImageContent,
        );
      } else {
        return DomainResult<String>(
          DomainResultStatus.ERROR,
          message: 'Failed to get share content: ${response.statusCode}',
        );
      }
    } catch (e) {
      
      String errorMessage = 'Error getting share content';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          errorMessage = 'Authentication failed - please login again';
        } else {
          errorMessage = 'Network error: ${e.response?.statusCode ?? 'Unknown'}';
        }
      }
      
      return DomainResult<String>(
        DomainResultStatus.ERROR,
        message: errorMessage,
      );
    }
  }

  void dispose() {
    _mCurrentSearchWord.close();
    _mChunkResults.close();
    _mEventSearchQuery.close();
  }
}
