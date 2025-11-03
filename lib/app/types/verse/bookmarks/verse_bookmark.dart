import 'package:json_annotation/json_annotation.dart';

part 'verse_bookmark.g.dart';

@JsonSerializable()
class VerseBookmarkRM {

  final String? source;


  final String key;

  final String text;


  final int pk;


  // final String similarity;

  VerseBookmarkRM({
    this.source,
    required this.key,
    required this.text,
    required this.pk,
    // required this.similarity,
  });

  factory VerseBookmarkRM.fromJson(Map<String, dynamic> json) =>
      _$VerseBookmarkRMFromJson(json);
  Map<String, dynamic> toJson() => _$VerseBookmarkRMToJson(this);
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
