import 'package:dharak_flutter/app/types/verse/bookmarks/verse_bookmark.dart';

import 'package:json_annotation/json_annotation.dart';

part 'bookmarks_result.g.dart';

@JsonSerializable()
class VerseBookmarksResultRM {
  final String message;
  final List<VerseBookmarkRM> verse;

  VerseBookmarksResultRM({required this.message, required this.verse});

  factory VerseBookmarksResultRM.fromJson(Map<String, dynamic> json) =>
      _$VerseBookmarksResultRMFromJson(json);
  Map<String, dynamic> toJson() => _$VerseBookmarksResultRMToJson(this);
}
