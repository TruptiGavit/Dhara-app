import 'dart:async';

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:dharak_flutter/app/bloc/state_bloc.dart';
import 'package:dharak_flutter/app/types/unified/unified_response.dart';
import 'package:dharak_flutter/core/services/unified_service.dart';
import 'package:dharak_flutter/core/components/tool_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'unified_controller.g.dart';

@CopyWith()
class UnifiedState extends BlocState {
  final List<UnifiedSearchResult> searchResults;
  final bool isLoading;
  final bool isStreaming;
  final String? error;
  final String currentQuery;
  final int searchCounter;

  UnifiedState({
    this.searchResults = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.error,
    this.currentQuery = '',
    this.searchCounter = 0,
  });

  @override
  List<Object?> get props => [
    searchResults,
    isLoading,
    isStreaming,
    error,
    currentQuery,
    searchCounter,
  ];
}

class UnifiedController extends Cubit<UnifiedState> {
  final UnifiedService _unifiedService = UnifiedService.instance;
  
  StreamSubscription<List<UnifiedSearchResult>>? _resultsSubscription;
  StreamSubscription<bool>? _loadingSubscription;
  StreamSubscription<bool>? _streamingSubscription;

  UnifiedController() : super(UnifiedState()) {
    _subscribeToServices();
  }

  void _subscribeToServices() {
    // Listen to search results updates
    _resultsSubscription = _unifiedService.currentResults.listen((results) {
      emit(state.copyWith(
        searchResults: results,
        searchCounter: state.searchCounter + 1,
      ));
    });

    // Listen to loading state updates
    _loadingSubscription = _unifiedService.isLoading.listen((isLoading) {
      emit(state.copyWith(
        isLoading: isLoading,
        error: isLoading ? null : state.error, // Clear error when starting new search
      ));
    });

    // Listen to streaming state updates
    _streamingSubscription = _unifiedService.isStreaming.listen((isStreaming) {
      emit(state.copyWith(
        isStreaming: isStreaming,
      ));
    });
  }

  /// Perform unified search
  Future<void> searchUnified(String query, {bool forceRefresh = false}) async {
    if (query.trim().isEmpty) return;

    try {
      emit(state.copyWith(
        currentQuery: query,
        error: null,
      ));

      await _unifiedService.searchUnified(query, forceRefresh: forceRefresh);
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to search: $e',
        isLoading: false,
      ));
    }
  }

  /// Clear all search results
  void clearAllResults() {
    _unifiedService.clearResults();
    emit(state.copyWith(
      currentQuery: '',
      error: null,
      searchCounter: state.searchCounter + 1,
    ));
  }

  /// Remove a specific search result
  void removeResult(String query) {
    _unifiedService.removeResult(query);
  }

  /// Refresh current search
  Future<void> refreshCurrentSearch() async {
    if (state.currentQuery.isNotEmpty) {
      await searchUnified(state.currentQuery);
    }
  }

  // Getters for UI convenience
  bool get hasResults => state.searchResults.isNotEmpty;
  int get resultCount => state.searchResults.length;

  /// Get expandable tools for a specific result
  List<ExpandableToolType> getExpandableTools(UnifiedSearchResult result) {
    final tools = <ExpandableToolType>[];
    
    if (result.hasDefinition) tools.add(ExpandableToolType.definition);
    if (result.hasVerses) tools.add(ExpandableToolType.verse);
    if (result.hasChunks) tools.add(ExpandableToolType.chunk);
    
    return tools;
  }

  @override
  Future<void> close() {
    _resultsSubscription?.cancel();
    _loadingSubscription?.cancel();
    _streamingSubscription?.cancel();
    return super.close();
  }
}


