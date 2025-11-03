import 'package:dharak_flutter/app/types/unified/unified_search_response.dart';
import 'package:equatable/equatable.dart';

abstract class UnifiedSearchCubitState extends Equatable {
  const UnifiedSearchCubitState();

  @override
  List<Object?> get props => [];
}

/// Initial state when no search has been performed
class UnifiedSearchInitial extends UnifiedSearchCubitState {
  const UnifiedSearchInitial();
}

/// Loading state during search
class UnifiedSearchLoading extends UnifiedSearchCubitState {
  final String query;

  const UnifiedSearchLoading({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Success state with search results
class UnifiedSearchSuccess extends UnifiedSearchCubitState {
  final String query;
  final UnifiedSearchResult result;

  const UnifiedSearchSuccess({
    required this.query,
    required this.result,
  });

  @override
  List<Object?> get props => [query, result];
}

/// Empty state when search returns no results
class UnifiedSearchEmpty extends UnifiedSearchCubitState {
  final String query;

  const UnifiedSearchEmpty({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Error state when search fails
class UnifiedSearchError extends UnifiedSearchCubitState {
  final String query;
  final String error;

  const UnifiedSearchError({
    required this.query,
    required this.error,
  });

  @override
  List<Object?> get props => [query, error];
}

/// Streaming state for real-time results
class UnifiedSearchStreaming extends UnifiedSearchCubitState {
  final String query;
  final UnifiedSearchResult partialResult;

  const UnifiedSearchStreaming({
    required this.query,
    required this.partialResult,
  });

  @override
  List<Object?> get props => [query, partialResult];
}

