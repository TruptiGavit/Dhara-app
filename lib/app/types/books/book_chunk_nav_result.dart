import 'package:json_annotation/json_annotation.dart';
import 'package:dharak_flutter/app/types/books/book_chunk.dart';

part 'book_chunk_nav_result.g.dart';

@JsonSerializable()
class BookChunkNextResultRM {
  @JsonKey(name: 'next_sib')
  final BookChunkRM? nextSib;

  BookChunkNextResultRM({this.nextSib});

  factory BookChunkNextResultRM.fromJson(Map<String, dynamic> json) =>
      _$BookChunkNextResultRMFromJson(json);

  Map<String, dynamic> toJson() => _$BookChunkNextResultRMToJson(this);

  BookChunkRM? getNextChunk() => nextSib;
}

@JsonSerializable()
class BookChunkPrevResultRM {
  @JsonKey(name: 'prev_sib')
  final BookChunkRM? prevSib;

  BookChunkPrevResultRM({this.prevSib});

  factory BookChunkPrevResultRM.fromJson(Map<String, dynamic> json) =>
      _$BookChunkPrevResultRMFromJson(json);

  Map<String, dynamic> toJson() => _$BookChunkPrevResultRMToJson(this);

  BookChunkRM? getPrevChunk() => prevSib;
}











