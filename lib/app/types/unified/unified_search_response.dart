import 'package:dharak_flutter/app/types/dictionary/word_definitions.dart';
import 'package:dharak_flutter/app/types/verse/verses.dart';
import 'package:dharak_flutter/app/types/books/chunk.dart';

/// Unified search response wrapper
class UnifiedSearchResponse {
  final String type;
  final dynamic data;

  UnifiedSearchResponse({
    required this.type,
    required this.data,
  });

  factory UnifiedSearchResponse.fromJson(Map<String, dynamic> json) {
    return UnifiedSearchResponse(
      type: json['type'] as String,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
    };
  }
}

/// Splits response from unified search
class UnifiedSplitsResponse {
  final List<String> nouns;
  final List<String> verbs;
  final List<String> quotedTexts;
  final String heritageQuery;

  UnifiedSplitsResponse({
    required this.nouns,
    required this.verbs,
    required this.quotedTexts,
    required this.heritageQuery,
  });

  factory UnifiedSplitsResponse.fromJson(Map<String, dynamic> json) {
    return UnifiedSplitsResponse(
      nouns: List<String>.from(json['nouns'] ?? []),
      verbs: List<String>.from(json['verbs'] ?? []),
      quotedTexts: List<String>.from(json['quoted_texts'] ?? []),
      heritageQuery: json['heritage_query'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nouns': nouns,
      'verbs': verbs,
      'quoted_texts': quotedTexts,
      'heritage_query': heritageQuery,
    };
  }
}

/// Definition response wrapper for unified search
class UnifiedDefinitionResponse {
  final DictWordDefinitionsRM definitions;

  UnifiedDefinitionResponse({
    required this.definitions,
  });

  factory UnifiedDefinitionResponse.fromJson(Map<String, dynamic> json) {
    return UnifiedDefinitionResponse(
      definitions: DictWordDefinitionsRM.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return definitions.toJson();
  }
  
  // Convenience getters
  String get givenWord => definitions.givenWord;
  bool get success => definitions.success;
  bool get foundMatch => definitions.foundMatch ?? false;
  List<String> get similarWords => definitions.similarWords;
}

/// Verse response wrapper for unified search  
class UnifiedVerseResponse {
  final VersesResultRM verses;

  UnifiedVerseResponse({
    required this.verses,
  });

  factory UnifiedVerseResponse.fromJson(Map<String, dynamic> json) {
    return UnifiedVerseResponse(
      verses: VersesResultRM.fromJson(json),
    );
  }
  
  factory UnifiedVerseResponse.fromList(List<dynamic> list) {
    // Convert list format to the expected VersesResultRM format
    final versesData = list.where((item) => 
      item is Map<String, dynamic> && item['data_type'] == 'verse'
    ).toList();
    
    final infoData = list.firstWhere(
      (item) => item is Map<String, dynamic> && item['data_type'] == 'info',
      orElse: () => <String, dynamic>{},
    ) as Map<String, dynamic>?;
    
    // Create the structure that VersesResultRM expects
    final jsonData = <String, dynamic>{
      'head': {
        'data_type': 'info',  // VerseHeadRM requires this field
        'input_string': infoData?['input_string'] ?? '',
        'input_script': infoData?['input_script'] ?? '',
        'output_script': infoData?['output_script'] ?? '',
        'total_verse': infoData?['total_verse'] ?? versesData.length,
      },
      'verses': versesData,
      'foot': null,  // VersesResultRM expects head, verses, foot structure
    };
    
    print("🔧 Creating VersesResultRM with data: $jsonData");
    print("🔧 Verses data preview: ${versesData.take(1).toList()}");
    
    return UnifiedVerseResponse(
      verses: VersesResultRM.fromJson(jsonData),
    );
  }

  Map<String, dynamic> toJson() {
    return verses.toJson();
  }
  
  // Add copyWith method for updating verses
  UnifiedVerseResponse copyWith({
    VersesResultRM? verses,
  }) {
    return UnifiedVerseResponse(
      verses: verses ?? this.verses,
    );
  }
}

/// Chunk response wrapper for unified search
class UnifiedChunkResponse {
  final BookChunksResponseRM chunks;

  UnifiedChunkResponse({
    required this.chunks,
  });

  factory UnifiedChunkResponse.fromJson(Map<String, dynamic> json) {
    return UnifiedChunkResponse(
      chunks: BookChunksResponseRM.fromJson(json),
    );
  }
  
  factory UnifiedChunkResponse.fromList(List<dynamic> list) {
    // Convert list format to the expected BookChunksResponseRM format
    final chunksData = list.map((item) => item as Map<String, dynamic>).toList();
    
    final jsonData = <String, dynamic>{
      'success': true,  // Add the required success field
      'data': chunksData,
    };
    
    return UnifiedChunkResponse(
      chunks: BookChunksResponseRM.fromJson(jsonData),
    );
  }

  Map<String, dynamic> toJson() {
    return chunks.toJson();
  }
}

/// Combined unified search result
class UnifiedSearchResult {
  final UnifiedSplitsResponse? splits;
  final List<UnifiedDefinitionResponse> definitions;
  final UnifiedVerseResponse? verses;
  final UnifiedChunkResponse? chunks;

  UnifiedSearchResult({
    this.splits,
    required this.definitions,
    this.verses,
    this.chunks,
  });

  bool get hasResults => 
      definitions.isNotEmpty || 
      (verses?.verses.verses.isNotEmpty ?? false) || 
      (chunks?.chunks.data.isNotEmpty ?? false);

  bool get hasDefinitions => definitions.any((def) => def.foundMatch);
  bool get hasVerses => verses?.verses.verses.isNotEmpty ?? false;
  bool get hasChunks => chunks?.chunks.data.isNotEmpty ?? false;
  
  // Add copyWith method for updating search results
  UnifiedSearchResult copyWith({
    UnifiedSplitsResponse? splits,
    List<UnifiedDefinitionResponse>? definitions,
    UnifiedVerseResponse? verses,
    UnifiedChunkResponse? chunks,
  }) {
    return UnifiedSearchResult(
      splits: splits ?? this.splits,
      definitions: definitions ?? this.definitions,
      verses: verses ?? this.verses,
      chunks: chunks ?? this.chunks,
    );
  }
}
