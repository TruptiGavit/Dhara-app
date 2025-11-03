import 'package:json_annotation/json_annotation.dart';


part 'verse_other_field.g.dart';

@JsonSerializable()
class VerseOtherFieldRM {
  final String? title;

  @JsonKey(name: "short_title")
  final String? shortTitle;
  
  final String? value;

  VerseOtherFieldRM({
    this.title,
    this.shortTitle,
    this.value,
  });

  factory VerseOtherFieldRM.fromJson(Map<String, dynamic> json) => _$VerseOtherFieldRMFromJson(json);
  Map<String, dynamic> toJson() => _$VerseOtherFieldRMToJson(this);
}