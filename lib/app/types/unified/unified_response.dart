import 'package:dharak_flutter/app/types/books/book_chunk.dart';
import 'package:dharak_flutter/app/types/dictionary/word_definitions.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:json_annotation/json_annotation.dart';

part 'unified_response.g.dart';

/// Base class for unified search response items
@JsonSerializable()
class UnifiedResponseItem {
  final String type;
  final dynamic data;

  UnifiedResponseItem({
    required this.type,
    required this.data,
  });

  factory UnifiedResponseItem.fromJson(Map<String, dynamic> json) => 
      _$UnifiedResponseItemFromJson(json);
  Map<String, dynamic> toJson() => _$UnifiedResponseItemToJson(this);
}

/// Query splits data
@JsonSerializable()
class QuerySplitsRM {
  final List<String> nouns;
  @JsonKey(defaultValue: <String>[])
  final List<String> verbs;
  @JsonKey(name: 'quoted_texts')
  final List<String> quotedTexts;
  @JsonKey(name: 'heritage_query')
  final String heritageQuery;

  QuerySplitsRM({
    required this.nouns,
    this.verbs = const <String>[],
    required this.quotedTexts,
    required this.heritageQuery,
  });

  factory QuerySplitsRM.fromJson(Map<String, dynamic> json) => 
      _$QuerySplitsRMFromJson(json);
  Map<String, dynamic> toJson() => _$QuerySplitsRMToJson(this);
}

/// Unified search result container
class UnifiedSearchResult {
  final String query;
  final DateTime timestamp;
  final int searchSessionId; // Track which search session this belongs to
  final QuerySplitsRM? splits;
  final DictWordDefinitionsRM? definition;
  final List<VerseRM>? verses;
  final List<BookChunkRM>? chunks;
  final String? outputScript; // Language script from unified API response

  UnifiedSearchResult({
    required this.query,
    required this.timestamp,
    required this.searchSessionId,
    this.splits,
    this.definition,
    this.verses,
    this.chunks,
    this.outputScript,
  });

  UnifiedSearchResult copyWith({
    String? query,
    DateTime? timestamp,
    int? searchSessionId,
    QuerySplitsRM? splits,
    DictWordDefinitionsRM? definition,
    List<VerseRM>? verses,
    List<BookChunkRM>? chunks,
    String? outputScript,
  }) {
    return UnifiedSearchResult(
      query: query ?? this.query,
      timestamp: timestamp ?? this.timestamp,
      searchSessionId: searchSessionId ?? this.searchSessionId,
      splits: splits ?? this.splits,
      definition: definition ?? this.definition,
      verses: verses ?? this.verses,
      chunks: chunks ?? this.chunks,
      outputScript: outputScript ?? this.outputScript,
    );
  }

  // Helper getters
  bool get hasDefinition => definition != null && 
                           (definition!.foundMatch ?? false) && 
                           definition!.details.definitions.isNotEmpty;
  bool get hasVerses => verses != null && verses!.isNotEmpty;
  bool get hasChunks => chunks != null && chunks!.isNotEmpty;
  bool get hasAnyResults => hasDefinition || hasVerses || hasChunks;
}
