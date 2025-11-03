import 'package:json_annotation/json_annotation.dart';

part 'book_chunk.g.dart';

@JsonSerializable()
class BookChunkRM {
  final String? text;
  
  @JsonKey(name: 'chunk_ref_id')
  final int? chunkRefId;
  
  final double? score;
  final String? reference;
  
  // New API fields for enhanced book cards
  @JsonKey(name: 'source_title')
  final String? sourceTitle;
  
  @JsonKey(name: 'source_url')
  final String? sourceUrl;
  
  @JsonKey(name: 'source_type')
  final String? sourceType;
  
  // Bookmark status (similar to verses)
  @JsonKey(name: 'is_starred')
  final bool? isStarred;

  BookChunkRM({
    this.text,
    this.chunkRefId,
    this.score,
    this.reference,
    this.sourceTitle,
    this.sourceUrl,
    this.sourceType,
    this.isStarred,
  });

  factory BookChunkRM.fromJson(Map<String, dynamic> json) =>
      _$BookChunkRMFromJson(json);

  Map<String, dynamic> toJson() => _$BookChunkRMToJson(this);
  
  /// Create a copy with updated fields (similar to VerseRM.copyWith)
  BookChunkRM copyWith({
    String? text,
    int? chunkRefId,
    double? score,
    String? reference,
    String? sourceTitle,
    String? sourceUrl,
    String? sourceType,
    bool? isStarred,
  }) {
    return BookChunkRM(
      text: text ?? this.text,
      chunkRefId: chunkRefId ?? this.chunkRefId,
      score: score ?? this.score,
      reference: reference ?? this.reference,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceType: sourceType ?? this.sourceType,
      isStarred: isStarred ?? this.isStarred,
    );
  }
}

