import 'package:json_annotation/json_annotation.dart';
import 'package:dharak_flutter/app/types/books/book_chunk.dart';

part 'book_bookmark_result.g.dart';

@JsonSerializable()
class BookChunkBookmarkToggleResultRM {
  final String message;
  final bool? success; // Made nullable to handle API variations

  BookChunkBookmarkToggleResultRM({required this.message, this.success});

  factory BookChunkBookmarkToggleResultRM.fromJson(Map<String, dynamic> json) =>
      _$BookChunkBookmarkToggleResultRMFromJson(json);
  Map<String, dynamic> toJson() => _$BookChunkBookmarkToggleResultRMToJson(this);
}

@JsonSerializable()
class BookChunkStarredListResultRM {
  final List<BookChunkRM> chunks;

  BookChunkStarredListResultRM({required this.chunks});

  factory BookChunkStarredListResultRM.fromJson(Map<String, dynamic> json) =>
      _$BookChunkStarredListResultRMFromJson(json);
  Map<String, dynamic> toJson() => _$BookChunkStarredListResultRMToJson(this);
}
