import 'package:json_annotation/json_annotation.dart';

part 'verse_head.g.dart';

@JsonSerializable()
class VerseHeadRM {
  @JsonKey(name: "data_type")
  String dataType;

  @JsonKey(name: "input_string")
  String? inputString;


  @JsonKey(name: "search_scripts")
  List<String> searchScripts;


  @JsonKey(name: "input_script")
  String? inputScript;


  @JsonKey(name: "output_script")
  String? outputScript;

  VerseHeadRM({
    required this.dataType,
     this.inputString,
    required this.searchScripts,
     this.inputScript,
    this.outputScript,
  });

  factory VerseHeadRM.fromJson(Map<String, dynamic> json) =>
      _$VerseHeadRMFromJson(json);
  Map<String, dynamic> toJson() => _$VerseHeadRMToJson(this);
}
