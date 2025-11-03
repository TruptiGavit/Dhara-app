import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dharak_flutter/app/data/local/secure/secure_local_data.dart';
import 'package:dharak_flutter/app/types/books/book_chunk.dart';
import 'package:dharak_flutter/app/types/dictionary/word_definitions.dart';
import 'package:dharak_flutter/app/types/unified/unified_response.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/core/cache/smart_search_cache.dart';
import 'package:dharak_flutter/core/services/verse_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/controller.dart';
import 'package:rxdart/rxdart.dart';

class UnifiedService {
  static final UnifiedService _instance = UnifiedService._internal();
  static UnifiedService get instance => _instance;
  UnifiedService._internal();

  Dio? _dio;
  final String _baseUrl = 'https://project.iith.ac.in/bheri';
  
  // Get the configured Dio instance with auth interceptors
  Dio get dio {
    _dio ??= Modular.get<Dio>();
    return _dio!;
  }

  // Track search sessions (incremented each time user clicks send)
  int _currentSearchSessionId = 0;
  
  // Verse response counter to ensure unique queries
  int _verseResponseCounter = 0;

  // Reactive streams for current search results
  final BehaviorSubject<List<UnifiedSearchResult>> _currentResults = 
      BehaviorSubject<List<UnifiedSearchResult>>.seeded([]);

  // Stream to track loading state
  final BehaviorSubject<bool> _isLoading = BehaviorSubject<bool>.seeded(false);
  
  // Stream to track if API is still streaming responses
  final BehaviorSubject<bool> _isStreaming = BehaviorSubject<bool>.seeded(false);

  // Stream getters
  Stream<List<UnifiedSearchResult>> get currentResults => _currentResults.stream;
  Stream<bool> get isLoading => _isLoading.stream;
  Stream<bool> get isStreaming => _isStreaming.stream;

  // Current values
  List<UnifiedSearchResult> get currentResultsValue => _currentResults.value;
  bool get isLoadingValue => _isLoading.value;

  /// Perform unified search with streaming response
  Future<void> searchUnified(String query, {bool forceRefresh = false}) async {
    if (query.trim().isEmpty) {
      return;
    }

    // Increment search session ID for new search
    _currentSearchSessionId++;
    final currentSessionId = _currentSearchSessionId;
    
    // Reset verse counter for new search
    _verseResponseCounter = 0;
    
    // ✅ FIX: Clear ALL previous results when starting a new search
    final currentResults = _currentResults.value;
    if (currentResults.isNotEmpty) {
    }
    _currentResults.add([]);

    try {
      _isLoading.add(true);
      print('🔄 Setting streaming to true');
      _isStreaming.add(true);
      
      // Check cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedResult = SmartSearchCache.instance.getUnifiedResult(query);
        if (cachedResult != null) {
          print('🔄 Using cached unified result for: $query');
        
        // ✅ FIX: Decompose cached result into individual tool results
        // Instead of adding the combined result, recreate individual tool cards
        
        // 1. Create definition result if exists
        if (cachedResult.hasDefinition) {
          final definitionResult = UnifiedSearchResult(
            query: cachedResult.definition!.givenWord ?? query,
            timestamp: DateTime.now(),
            searchSessionId: currentSessionId, // ✅ NEW session ID
            splits: cachedResult.splits,
            definition: cachedResult.definition,
          );
          _addOrUpdateResult(definitionResult);
          print('📖 Recreated cached definition result for word: ${cachedResult.definition!.givenWord}');
        }
        
        // 2. Create verse result if exists  
        if (cachedResult.hasVerses) {
          String verseQuery = query;
          if (cachedResult.splits != null && cachedResult.splits!.quotedTexts.isNotEmpty) {
            verseQuery = '"${cachedResult.splits!.quotedTexts.join('", "')}"';
          }
          
          final verseResult = UnifiedSearchResult(
            query: verseQuery,
            timestamp: DateTime.now(),
            searchSessionId: currentSessionId, // ✅ NEW session ID
            splits: cachedResult.splits,
            verses: cachedResult.verses,
            outputScript: cachedResult.outputScript,
          );
          _addOrUpdateResult(verseResult);
          print('📜 Recreated cached verse result with ${cachedResult.verses!.length} verses');
          
          // Add verses to VerseService cache for interaction
          final verseService = VerseService.instance;
          for (var verse in cachedResult.verses!) {
            verseService.addVerseToCache(verse);
          }
        }
        
        // 3. Create chunk result if exists
        if (cachedResult.hasChunks) {
          String chunkQuery = query;
          if (cachedResult.splits != null && cachedResult.splits!.heritageQuery.isNotEmpty) {
            chunkQuery = cachedResult.splits!.heritageQuery;
          }
          
          final chunkResult = UnifiedSearchResult(
            query: chunkQuery,
            timestamp: DateTime.now(),
            searchSessionId: currentSessionId, // ✅ NEW session ID
            splits: cachedResult.splits,
            chunks: cachedResult.chunks,
          );
          _addOrUpdateResult(chunkResult);
          print('📚 Recreated cached chunk result with ${cachedResult.chunks!.length} book chunks');
        }
        
          _isLoading.add(false);
          print('🔄 Setting streaming to false (cache hit)');
          _isStreaming.add(false);
          return;
        }
      } else {
        print('🔄 Force refresh requested - bypassing cache for query: $query');
      }

      // Prepare new result container
      final newResult = UnifiedSearchResult(
        query: query,
        timestamp: DateTime.now(),
        searchSessionId: currentSessionId,
      );

      // Add empty result first (will be updated as we receive data)
      _addOrUpdateResult(newResult);

      // Start streaming request - let auth interceptor handle authentication
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$_baseUrl/quick_search/?query=$encodedQuery';
      
      print('🔍 Starting unified search: $url');
      print('🔐 Using configured Dio with auth interceptors');

      // Use configured Dio instance which will automatically add auth headers via interceptor
      final response = await dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'accept': '*/*',
            'requiresToken': true, // Signal the auth interceptor to add auth headers
          },
        ),
      );

      print('📡 API response received, status: ${response.statusCode}');

      if (response.data != null) {
        // ✅ FIX: Only process response if it's still from the current session
        if (currentSessionId == _currentSearchSessionId) {
          print('✅ Processing API response for current session $currentSessionId');
          await _handleStreamingResponse(response.data!, query, newResult, currentSessionId);
        } else {
          print('⏰ Ignoring stale API response from session $currentSessionId (current: $_currentSearchSessionId)');
        }
      }

    } catch (e) {
      print('❌ Unified search error: $e');
      _isLoading.add(false);
      print('🔄 Setting streaming to false (error)');
      _isStreaming.add(false);
      rethrow;
    }
  }

  /// Handle streaming response from unified API
  Future<void> _handleStreamingResponse(
    ResponseBody responseBody, 
    String query, 
    UnifiedSearchResult result,
    int currentSessionId
  ) async {
    UnifiedSearchResult currentResult = result;
    String buffer = '';

    await for (final bytes in responseBody.stream) {
      final chunk = utf8.decode(bytes);
      buffer += chunk;
      
      // Try to extract complete JSON objects
      while (buffer.isNotEmpty) {
        // Find start of JSON object
        final startIndex = buffer.indexOf('{');
        if (startIndex == -1) {
          buffer = '';
          break;
        }
        
        if (startIndex > 0) {
          buffer = buffer.substring(startIndex);
        }
        
        // Try to find the complete JSON object
        int braceCount = 0;
        int endIndex = -1;
        bool inString = false;
        bool escaped = false;
        
        for (int i = 0; i < buffer.length; i++) {
          final char = buffer[i];
          
          if (escaped) {
            escaped = false;
            continue;
          }
          
          if (char == '\\') {
            escaped = true;
            continue;
          }
          
          if (char == '"') {
            inString = !inString;
            continue;
          }
          
          if (!inString) {
            if (char == '{') {
              braceCount++;
            } else if (char == '}') {
              braceCount--;
              if (braceCount == 0) {
                endIndex = i;
                break;
              }
            }
          }
        }
        
        if (endIndex == -1) {
          // Incomplete JSON, wait for more data
          print('🔄 Incomplete JSON, waiting for more data. Buffer length: ${buffer.length}');
          break;
        }
        
        final jsonString = buffer.substring(0, endIndex + 1);
        buffer = buffer.substring(endIndex + 1);
        
        print('🎯 Extracted complete JSON: ${jsonString.length} chars');
        
            try {
              final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
              final type = jsonMap['type'] as String?;
              final data = jsonMap['data'];

              if (type == null || data == null) continue;

              print('📦 Received unified data type: $type');

              // Fix null word_hyplinks issue and other null fields
              if (type == 'verse' && data is List) {
                for (var verse in data) {
                  if (verse is Map<String, dynamic>) {
                    // Fix null word_hyplinks
                    if (verse['word_hyplinks'] == null) {
                      verse['word_hyplinks'] = <Map<String, dynamic>>[];
                    }
                    // Fix null other_fields
                    if (verse['other_fields'] == null) {
                      verse['other_fields'] = <Map<String, dynamic>>[];
                    }
                    // Ensure numeric fields are not null
                    if (verse['verse_pk'] == null) {
                      verse['verse_pk'] = 0; // Default value
                    }
                  }
                }
              }

              switch (type) {
            case 'info':
              // Handle language info from unified response
              final infoData = data as Map<String, dynamic>;
              final outputScript = infoData['output_script'] as String?;
              print('🌍 UNIFIED: Received output_script: $outputScript');
              
              // Store the output script and reprocess any existing verses
              currentResult = currentResult.copyWith(
                outputScript: outputScript,
                searchSessionId: currentSessionId
              );
              
              // If we already have verses, reprocess them with the new language info
              if (currentResult.verses != null && currentResult.verses!.isNotEmpty) {
                print('🔄 UNIFIED: Found existing verses, reprocessing with language: $outputScript');
                _reprocessVersesWithLanguage(currentResult, currentSessionId, query);
              }
              break;

            case 'splits':
              final splits = QuerySplitsRM.fromJson(data as Map<String, dynamic>);
              currentResult = currentResult.copyWith(
                splits: splits,
                searchSessionId: currentSessionId
              );
              break;

            case 'definition':
              final definition = DictWordDefinitionsRM.fromJson(data as Map<String, dynamic>);
              
              // Create a separate result for each definition response
              final definitionResult = UnifiedSearchResult(
                query: definition.givenWord ?? query, // Use the specific word
                timestamp: DateTime.now(),
                searchSessionId: currentSessionId, // ✅ FIX: Use session ID from current search
                splits: currentResult.splits, // Share the splits
                definition: definition,
              );
              
              if (definition.details.definitions.isNotEmpty) {
                final firstDefText = definition.details.definitions.first.text;
                final preview = firstDefText.length > 50 ? firstDefText.substring(0, 50) : firstDefText;
                print('🔍 FIRST DEFINITION: $preview');
              }
              _addOrUpdateResult(definitionResult);
              print('📖 Created separate definition result for word: ${definition.givenWord}');
              break;

            case 'verse':
              final versesData = data as List<dynamic>;
              print('🔍 RAW VERSE API RESPONSE: ${versesData.length} verses received');
              print('🔍 QUOTED TEXTS: ${currentResult.splits?.quotedTexts ?? 'None'}');
              print('🔍 COMPLETE API RESPONSE DATA:');
              print(versesData.toString());
              
              final verses = <VerseRM>[];
              for (int i = 0; i < versesData.length; i++) {
                var v = versesData[i];
                try {
                  final verse = VerseRM.fromJson(v as Map<String, dynamic>);
                  verses.add(verse); // Store original verses first
                  print('🔍 VERSE $i: PK=${verse.versePk}, Text="${verse.verseText?.substring(0, 100) ?? 'N/A'}...", LetText="${verse.verseLetText?.substring(0, 100) ?? 'N/A'}...", Source="${verse.sourceTitle ?? 'N/A'}"');
                } catch (e) {
                  print('❌ Error parsing individual verse: $e');
                  print('📄 Problematic verse data: $v');
                  // Skip this verse and continue
                }
              }
              
              // ✅ CORRECT APPROACH: Each verse response creates ONE card
              // The API sends 3 separate verse responses, so we create one card per response
              
              _verseResponseCounter++;
              
              // Determine which quoted text this verse response corresponds to
              String cardQuery;
              if (currentResult.splits?.quotedTexts != null && currentResult.splits!.quotedTexts!.isNotEmpty) {
                final quotedTexts = currentResult.splits!.quotedTexts!;
                // Use the verse response counter to map to the correct quoted text
                final quotedTextIndex = (_verseResponseCounter - 1) % quotedTexts.length;
                cardQuery = quotedTexts[quotedTextIndex];
                print('🎯 UNIFIED: Verse response #$_verseResponseCounter maps to quoted text: "$cardQuery"');
              } else {
                cardQuery = query;
                print('🎯 UNIFIED: No quoted texts, using main query: "$cardQuery"');
              }
              
              // Create ONE verse result for this specific response
              final verseResult = UnifiedSearchResult(
                query: cardQuery,
                timestamp: DateTime.now(),
                searchSessionId: currentSessionId,
                splits: currentResult.splits,
                verses: verses, // These verses are specifically for this quoted text
                outputScript: currentResult.outputScript,
              );
              
              print('🔍 VERSE DEBUG: Creating verse result for "$cardQuery" with ${verses.length} verses (response #$_verseResponseCounter)');
              
              // Apply language transformation immediately if needed
              if (currentResult.outputScript == null) {
                print('🌍 UNIFIED: No output script, applying language transformation for "$cardQuery"');
                final tempResult = verseResult.copyWith(outputScript: 'Devanagari');
                _reprocessVersesWithLanguage(tempResult, currentSessionId, cardQuery);
              } else {
                print('🌍 UNIFIED: Output script available, adding result directly for "$cardQuery"');
                _addOrUpdateResult(verseResult);
              }
              
              // Continue processing - don't break, as more verse responses may come
              break;

            case 'chunk':
              final chunksData = data as List<dynamic>;
              final chunks = chunksData
                  .map((c) => BookChunkRM.fromJson(c as Map<String, dynamic>))
                  .toList();
              
              // Create chunk result with heritage query
              String chunkQuery = query;
              if (currentResult.splits != null && currentResult.splits!.heritageQuery.isNotEmpty) {
                chunkQuery = currentResult.splits!.heritageQuery;
              }
              
              final chunkResult = UnifiedSearchResult(
                query: chunkQuery,
                timestamp: DateTime.now(),
                searchSessionId: currentSessionId, // ✅ FIX: Use session ID from current search
                splits: currentResult.splits,
                chunks: chunks,
              );
              
              _addOrUpdateResult(chunkResult);
              print('📚 Created chunk result with ${chunks.length} book chunks');
              break;

            default:
              print('⚠️ Unknown unified data type: $type');
          }

        } catch (e) {
          print('❌ JSON parsing error in unified response: $e');
          print('📄 Problematic JSON: ${jsonString.length > 200 ? '${jsonString.substring(0, 200)}...' : jsonString}');
        }
      }
    }

    // Cache the final result
    SmartSearchCache.instance.setUnifiedResult(query, currentResult);
    _isLoading.add(false);
    print('🔄 Setting streaming to false (API complete)');
    _isStreaming.add(false);
  }




  /// Add or update a search result
  void _addOrUpdateResult(UnifiedSearchResult newResult) {
    final currentResults = List<UnifiedSearchResult>.from(_currentResults.value);
    
    // ✅ FIX: FORCE all new results to use current session ID
    final correctedResult = newResult.copyWith(
      searchSessionId: _currentSearchSessionId,
    );
    
    // Check for duplicates based on query and current session
    final existingIndex = currentResults.indexWhere(
      (result) => result.query.toLowerCase() == correctedResult.query.toLowerCase() && 
                  result.searchSessionId == _currentSearchSessionId
    );

    if (existingIndex != -1) {
      // Update existing result (prevent duplicates)
      currentResults[existingIndex] = correctedResult;
      print('🔄 UnifiedService: Updated existing result for "${correctedResult.query}" (session $_currentSearchSessionId)');
    } else {
      // Add new result at the beginning
      currentResults.insert(0, correctedResult);
      print('🔄 UnifiedService: Added NEW result for current session $_currentSearchSessionId: "${correctedResult.query}"');
      print('📊 Total results after addition: ${currentResults.length}');
    }

    // Debug: Print details of all results being broadcasted
    print('🔄 UnifiedService: Broadcasting ${currentResults.length} results to stream');
    for (int i = 0; i < currentResults.length; i++) {
      final result = currentResults[i];
      print('   $i: "${result.query}" (session ${result.searchSessionId}) - hasDefinition: ${result.hasDefinition}, hasVerses: ${result.hasVerses}, hasChunks: ${result.hasChunks}');
    }
    _currentResults.add(currentResults);
  }

  void _reprocessVersesWithLanguage(UnifiedSearchResult currentResult, int sessionId, String query) {
    if (currentResult.verses == null || currentResult.verses!.isEmpty || currentResult.outputScript == null) {
      return;
    }

    print('🌍 UNIFIED: Reprocessing ${currentResult.verses!.length} verses with language: ${currentResult.outputScript}');
    
    final transformedVerses = <VerseRM>[];
    for (var verse in currentResult.verses!) {
      final processedVerse = verse.copyWith(
        verseText: verse.verseOtherScripts?[currentResult.outputScript] ?? verse.verseText,
        verseLetText: verse.verseLetOtherScripts?[currentResult.outputScript] ?? verse.verseLetText,
      );
      
      print('🔄 UNIFIED: Transformed verse ${verse.versePk}: ${verse.verseText?.substring(0, 20)}... -> ${processedVerse.verseText?.substring(0, 20)}...');
      transformedVerses.add(processedVerse);
    }

    // Create verse result with transformed verses
    // ✅ FIX: Use the passed query parameter directly instead of combining all quoted texts
    String verseQuery = query;
    
    print('🔍 REPROCESS DEBUG: Creating transformed verse result for "${verseQuery}" with session $sessionId (original query: "$query")');
    final verseResult = UnifiedSearchResult(
      query: verseQuery,
      timestamp: DateTime.now(),
      searchSessionId: sessionId, // ✅ FIX: Use session ID from current search
      splits: currentResult.splits,
      verses: transformedVerses,
      outputScript: currentResult.outputScript,
    );
    
    // Add verses to VerseService cache for interaction
    final verseService = VerseService.instance;
    for (var verse in transformedVerses) {
      verseService.addVerseToCache(verse);
    }
    
    _addOrUpdateResult(verseResult);
    print('✅ UNIFIED: Reprocessed and updated verse result with language transformation');
  }

  /// Clear all results
  void clearResults() {
    _currentResults.add([]);
    _isLoading.add(false);
    _isStreaming.add(false);
  }

  /// Clear cache to force fresh results (for language changes)
  void clearCache() {
    SmartSearchCache.instance.clearUnifiedCache();
    print('🗑️ UNIFIED: Cache cleared for language change');
  }

  /// Remove a specific result
  void removeResult(String query) {
    final currentResults = List<UnifiedSearchResult>.from(_currentResults.value);
    currentResults.removeWhere(
      (result) => result.query.toLowerCase() == query.toLowerCase()
    );
    _currentResults.add(currentResults);
    
    // Also remove from cache
    SmartSearchCache.instance.clearUnifiedResult(query);
  }

  /// Silent refresh of verses for language change
  /// This fetches fresh verse data from the API using verse PKs and applies the new language preference
  Future<void> refreshVersesForLanguageChange() async {
    try {
      print('🔄 UNIFIED: Starting silent refresh for language change');
      
      final currentResults = _currentResults.value;
      if (currentResults.isEmpty) {
        print('🔄 UNIFIED: No results to refresh');
        return;
      }
      
      // Collect all verse PKs from current results
      final Set<int> allVersePks = {};
      for (final result in currentResults) {
        if (result.verses != null) {
          for (final verse in result.verses!) {
            allVersePks.add(verse.versePk);
          }
        }
      }
      
      if (allVersePks.isEmpty) {
        print('🔄 UNIFIED: No verses found to refresh');
        return;
      }
      
      print('🔄 UNIFIED: Refreshing ${allVersePks.length} verses: ${allVersePks.toList()}');
      
      // Create search query with all verse PKs
      final versePksString = allVersePks.join(' ');
      final url = '$_baseUrl/verse/v2/find/?input_string=${Uri.encodeComponent(versePksString)}';
      
      print('🔄 UNIFIED: Fetching verses from: $url');
      
      // Use configured Dio instance with auth interceptors
      final response = await dio.get(url, options: Options(headers: {
        'accept': '*/*',
        'requiresToken': true, // Signal the auth interceptor to add auth headers
      }));
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        print('🔄 UNIFIED: Received verse refresh response: ${responseData.toString().substring(0, 100)}...');
        
        if (responseData is Map<String, dynamic> && responseData['verses'] != null) {
          final versesData = responseData['verses'] as List<dynamic>;
          final refreshedVerses = <VerseRM>[];
          
          for (var v in versesData) {
            try {
              final verse = VerseRM.fromJson(v as Map<String, dynamic>);
              refreshedVerses.add(verse);
            } catch (e) {
              print('❌ UNIFIED: Error parsing refreshed verse: $e');
            }
          }
          
          print('🔄 UNIFIED: Successfully parsed ${refreshedVerses.length} refreshed verses');
          
          // Update all results with new verse data
          final updatedResults = <UnifiedSearchResult>[];
          for (final result in currentResults) {
            if (result.verses != null && result.verses!.isNotEmpty) {
              final updatedVerses = <VerseRM>[];
              
              for (final oldVerse in result.verses!) {
                // Find the refreshed version of this verse
                final refreshedVerse = refreshedVerses.firstWhere(
                  (rv) => rv.versePk == oldVerse.versePk,
                  orElse: () => oldVerse, // Keep original if not found
                );
                updatedVerses.add(refreshedVerse);
              }
              
              updatedResults.add(result.copyWith(verses: updatedVerses));
            } else {
              // Keep non-verse results unchanged
              updatedResults.add(result);
            }
          }
          
          // Emit the updated results
          _currentResults.add(updatedResults);
          print('✅ UNIFIED: Silent refresh completed successfully');
        }
      } else {
        print('❌ UNIFIED: Silent refresh failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ UNIFIED: Silent refresh error: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _currentResults.close();
    _isLoading.close();
  }
}
