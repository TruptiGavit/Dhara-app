import 'package:json_annotation/json_annotation.dart';
import 'book_chunk.dart';

part 'book_chunks_result.g.dart';

@JsonSerializable()
class BookChunksResultRM {
  final bool success;
  final List<BookChunkRM> data;

  BookChunksResultRM({
    required this.success,
    required this.data,
  });

  factory BookChunksResultRM.fromJson(Map<String, dynamic> json) =>
      _$BookChunksResultRMFromJson(json);

  Map<String, dynamic> toJson() => _$BookChunksResultRMToJson(this);
}











