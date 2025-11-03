
import 'package:dharak_flutter/app/types/verse/bookmarks/verse_bookmark.dart';
import 'package:json_annotation/json_annotation.dart';

part 'getall_dto.g.dart';



@JsonSerializable()
class VerseBookmarkGetAllDto {
  // @BuiltValueField(wireName: '_id')


  final String message;
  final List<VerseBookmarkRM> data;


  // final ParamFriendship? friendship;
  VerseBookmarkGetAllDto(
      {  required this.message,  required this.data});

  factory VerseBookmarkGetAllDto.fromJson(Map<String, dynamic> json) =>
      _$VerseBookmarkGetAllDtoFromJson(json);
  Map<String, dynamic> toJson() => _$VerseBookmarkGetAllDtoToJson(this);

 
}

