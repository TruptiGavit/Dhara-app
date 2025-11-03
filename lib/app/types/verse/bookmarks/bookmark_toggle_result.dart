
import 'package:json_annotation/json_annotation.dart';

part 'bookmark_toggle_result.g.dart';

@JsonSerializable()
class VerseBookmarkToggleResultRM {
  final String message;
  final bool success;

  VerseBookmarkToggleResultRM({required this.message, required this.success});

  factory VerseBookmarkToggleResultRM.fromJson(Map<String, dynamic> json) =>
      _$VerseBookmarkToggleResultRMFromJson(json);
  Map<String, dynamic> toJson() => _$VerseBookmarkToggleResultRMToJson(this);
}
