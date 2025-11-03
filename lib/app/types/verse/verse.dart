import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:dharak_flutter/app/types/dictionary/word_hyplink.dart';
import 'package:dharak_flutter/app/types/verse/verse_other_field.dart';
import 'package:json_annotation/json_annotation.dart';

part 'verse.g.dart';

@CopyWith()
@JsonSerializable()
class VerseRM {

  @JsonKey(name: "verse_let_text")
  final String? verseLetText;

  @JsonKey(name: "verse_let_other_scripts")
  final Map<String, String>? verseLetOtherScripts;

  @JsonKey(name: "verse_let_part")
  final String? verseLetPart;

  @JsonKey(name: "verse_text")
  final String? verseText;

  @JsonKey(name: "verse_other_scripts")
  final Map<String, String>? verseOtherScripts;

  @JsonKey(name: "verse_pk")
  final int versePk;

  @JsonKey(name: "verse_ref")
  final String? verseRef;

  @JsonKey(name: "is_starred")
  final bool? isStarred;

  @JsonKey(name: "other_fields")
  final List<VerseOtherFieldRM>? otherFields;

  @JsonKey(name: "source_title")
  final String? sourceTitle;

  @JsonKey(name: "source_name")
  final String? sourceName;

  @JsonKey(name: "source_url")
  final String? sourceUrl;

  @JsonKey(name: "word_hyplinks")
  final List<WordHyplinkRM>? wordHyplinks;

  @JsonKey(name: "data_type")
  final String? dataType;

  final String? similarity;

  VerseRM({
    this.verseLetText,
    this.verseLetOtherScripts,
    this.verseLetPart,
    this.verseText,
    this.verseOtherScripts,
    required this.versePk,
    this.verseRef,
    this.isStarred,
    this.otherFields,
    this.sourceTitle,
    this.sourceName,
    this.sourceUrl,
    this.wordHyplinks,
    this.dataType,
    this.similarity,
  });

  factory VerseRM.fromJson(Map<String, dynamic> json) =>
      _$VerseRMFromJson(json);
  Map<String, dynamic> toJson() => _$VerseRMToJson(this);
}

// @JsonSerializable()
// class OtherFieldRM {
//   final String title;
//   final String shortTitle;
//   final String value;

//   OtherFieldRM({
//     required this.title,
//     required this.shortTitle,
//     required this.value,
//   });

//   factory OtherFieldRM.fromJson(Map<String, dynamic> json) =>
//       _$OtherFieldRMFromJson(json);
//   Map<String, dynamic> toJson() => _$OtherFieldRMToJson(this);
// }