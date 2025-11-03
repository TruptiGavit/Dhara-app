import 'dart:async';
import 'package:dharak_flutter/app/data/remote/api/parts/unified/api.dart';
import 'package:dharak_flutter/app/domain/verse/repo.dart';
import 'package:dharak_flutter/app/types/unified/unified_search_response.dart';
import 'package:dharak_flutter/app/types/verse/language_pref.dart';
import 'package:dharak_flutter/app/ui/pages/unified/cubit_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart'; // 🚀 PERFORMANCE: Import for kDebugMode
import 'package:flutter_modular/flutter_modular.dart';

class UnifiedSearchController extends Cubit<UnifiedSearchCubitState> {
  final UnifiedSearchApiRepo _apiRepo = UnifiedSearchApiRepo();
  StreamSubscription? _streamSubscription;
  StreamSubscription<VersesLanguagePrefRM?>? _languageChangeSubscription;

  UnifiedSearchController() : super(UnifiedSearchInitial()) {
    _setupLanguageChangeListener();
  }

  /// Setup listener for global language changes to refresh unified results
  void _setupLanguageChangeListener() {
    try {
      final versesRepo = Modular.get<VerseRepository>();
      _languageChangeSubscription = versesRepo.mLanguagePrefObservable.listen((languagePref) {
        if (languagePref != null && mounted) {
          _handleLanguageChange(languagePref);
        }
      });
    } catch (e) {
    }
  }

  /// Handle language change for unified search results
  void _handleLanguageChange(VersesLanguagePrefRM languagePref) {
    final currentState = state;
    if (currentState is UnifiedSearchStreaming && currentState.currentResults?.verses != null) {
      _refreshVersesWithNewLanguage(currentState, languagePref);
    } else if (currentState is UnifiedSearchLoaded && currentState.results?.verses != null) {
      _refreshVersesWithNewLanguage(currentState, languagePref);
    }
  }

  /// Refresh verses in current results with new language
  void _refreshVersesWithNewLanguage(dynamic currentState, VersesLanguagePrefRM languagePref) {
    try {
      UnifiedSearchResult? results;
      
      if (currentState is UnifiedSearchStreaming) {
        results = currentState.currentResults;
      } else if (currentState is UnifiedSearchLoaded) {
        results = currentState.results;
      }
      
      if (results?.verses?.verses.verses != null) {
        final updatedVerses = results!.verses!.verses.verses.map((verse) {
          final newVerseText = verse.verseOtherScripts?[languagePref.output] ?? verse.verseText;
          final newVerseLetText = verse.verseLetOtherScripts?[languagePref.output] ?? verse.verseLetText;
          
          return verse.copyWith(
            verseText: newVerseText,
            verseLetText: newVerseLetText,
          );
        }).toList();
        
        final updatedVersesResult = results.verses!.verses.copyWith(verses: updatedVerses);
        final updatedVersesResponse = results.verses!.copyWith(verses: updatedVersesResult);
        final updatedResults = results.copyWith(verses: updatedVersesResponse);
        
        if (currentState is UnifiedSearchStreaming) {
          emit(UnifiedSearchStreaming(
            query: currentState.query,
            currentResults: updatedResults,
            accumulatedLines: currentState.accumulatedLines,
          ));
        } else if (currentState is UnifiedSearchLoaded) {
          emit(UnifiedSearchLoaded(results: updatedResults));
        }
        
      }
    } catch (e) {
      if (kDebugMode) print("💥 UNIFIED: Error refreshing verses with new language: $e");
    }
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    _languageChangeSubscription?.cancel();
    return super.close();
  }

  /// Perform unified search with real-time streaming
  Future<void> searchStreaming(String query) async {
    if (query.trim().isEmpty) {
      emit(UnifiedSearchInitial());
      return;
    }

    // Cancel any existing search
    _streamSubscription?.cancel();

    // Skip loading state - go directly to streaming for instant results

    // Initialize accumulator for streaming results
    List<UnifiedDefinitionResponse> definitions = [];
    UnifiedVerseResponse? verses;
    UnifiedChunkResponse? chunks;
    UnifiedSplitsResponse? splits;

    try {
      print("🔍 Starting real-time streaming search for: '$query'");
      
      _streamSubscription = _apiRepo.searchStream(query).listen(
        (response) {
          try {
            if (kDebugMode) print("📡 Received streaming data: type=${response.type}");
            
            // Process each streaming response type
            switch (response.type) {
              case 'splits':
                if (response.data is Map<String, dynamic>) {
                  splits = UnifiedSplitsResponse.fromJson(
                    response.data as Map<String, dynamic>
                  );
                  if (kDebugMode) print("✅ Splits received");
                }
                break;
              
              case 'definition':
                if (response.data is Map<String, dynamic>) {
                  final newDef = UnifiedDefinitionResponse.fromJson(
                    response.data as Map<String, dynamic>
                  );
                  definitions.add(newDef);
                  if (kDebugMode) print("✅ Definition received for word: ${newDef.definitions?.details.word}");
                }
                break;
              
              case 'verse':
                if (response.data is Map<String, dynamic>) {
                  verses = UnifiedVerseResponse.fromJson(
                    response.data as Map<String, dynamic>
                  );
                  if (kDebugMode) print("✅ Verses received: ${verses?.verses.verses.length} verses");
                } else if (response.data is List) {
                  verses = UnifiedVerseResponse.fromList(
                    response.data as List<dynamic>
                  );
                  if (kDebugMode) print("✅ Verses received: ${verses?.verses.verses.length} verses");
                }
                break;
              
              case 'chunk':
                final chunkReceiveTime = DateTime.now().millisecondsSinceEpoch;
                if (response.data is Map<String, dynamic>) {
                  chunks = UnifiedChunkResponse.fromJson(
                    response.data as Map<String, dynamic>
                  );
                  if (kDebugMode) print("✅ Chunks received: ${chunks?.chunks?.data.length} chunks at ${chunkReceiveTime}ms");
                } else if (response.data is List) {
                  chunks = UnifiedChunkResponse.fromList(
                    response.data as List<dynamic>
                  );
                  if (kDebugMode) print("✅ Chunks received: ${chunks?.chunks?.data.length} chunks at ${chunkReceiveTime}ms");
                }
                break;
            }

            // Emit streaming state with current partial results
            final partialResult = UnifiedSearchResult(
              splits: splits,
              definitions: definitions,
              verses: verses,
              chunks: chunks,
            );

            final emitTime = DateTime.now().millisecondsSinceEpoch;
            if (kDebugMode && chunks != null) print("📡 Emitting state with chunks at ${emitTime}ms");
            
            emit(UnifiedSearchStreaming(
              query: query,
              partialResult: partialResult,
            ));

          } catch (e) {
            print("❌ Error processing streaming response: $e");
          }
        },
        onDone: () {
          // When streaming is complete, emit final success state
          final finalResult = UnifiedSearchResult(
            splits: splits,
            definitions: definitions,
            verses: verses,
            chunks: chunks,
          );

          print("🔍 Streaming completed for '$query'");
          print("   - Final definitions: ${definitions.length}");
          print("   - Final verses: ${verses?.verses.verses.length ?? 0}");
          print("   - Final chunks: ${chunks?.chunks?.data.length ?? 0}");

          if (finalResult.hasResults) {
            emit(UnifiedSearchSuccess(
              query: query,
              result: finalResult,
            ));
          } else {
            emit(UnifiedSearchEmpty(query: query));
          }
        },
        onError: (error) {
          print("❌ Streaming search error: $error");
          emit(UnifiedSearchError(
            query: query,
            error: error.toString(),
          ));
        },
      );

    } catch (e) {
      print("❌ Unified streaming search controller error: $e");
      emit(UnifiedSearchError(
        query: query,
        error: e.toString(),
      ));
    }
  }

  /// Legacy method removed - use searchStreaming() for instant results

  /// Get streaming search results
  Stream<UnifiedSearchResponse> searchStream(String query) {
    return _apiRepo.searchStream(query);
  }

  /// Clear search results
  void clear() {
    emit(UnifiedSearchInitial());
  }

  /// Reset to initial state
  void reset() {
    emit(UnifiedSearchInitial());
  }
}

