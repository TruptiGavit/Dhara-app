import 'package:json_annotation/json_annotation.dart';

part 'verse_foot.g.dart';

@JsonSerializable()
class VerseFootRM {
  @JsonKey(name: "data_type")
  String dataType;

  @JsonKey(name: "total_verse")
  int totalVerse;

  VerseFootRM({required this.dataType, required this.totalVerse});

  factory VerseFootRM.fromJson(Map<String, dynamic> json) =>
      _$VerseFootRMFromJson(json);
  Map<String, dynamic> toJson() => _$VerseFootRMToJson(this);
}
