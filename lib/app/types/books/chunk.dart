import 'package:json_annotation/json_annotation.dart';

part 'chunk.g.dart';

@JsonSerializable()
class BookChunkRM {
  @JsonKey(name: 'text')
  final String text;
  
  @JsonKey(name: 'chunk_ref_id')
  final int chunkRefId;
  
  @JsonKey(name: 'score')
  final double score;
  
  @JsonKey(name: 'reference')
  final String reference;

  BookChunkRM({
    required this.text,
    required this.chunkRefId,
    required this.score,
    required this.reference,
  });

  factory BookChunkRM.fromJson(Map<String, dynamic> json) => _$BookChunkRMFromJson(json);
  Map<String, dynamic> toJson() => _$BookChunkRMToJson(this);
}

@JsonSerializable()
class BookChunksResponseRM {
  @JsonKey(name: 'success')
  final bool success;
  
  @JsonKey(name: 'data')
  final List<BookChunkRM> data;

  BookChunksResponseRM({
    required this.success,
    required this.data,
  });

  factory BookChunksResponseRM.fromJson(Map<String, dynamic> json) => _$BookChunksResponseRMFromJson(json);
  Map<String, dynamic> toJson() => _$BookChunksResponseRMToJson(this);
}


