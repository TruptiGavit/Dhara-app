import 'package:json_annotation/json_annotation.dart';

part 'word_hyplink.g.dart';

@JsonSerializable()
class WordHyplinkRM {
  final String? word;
  
  @JsonKey(name: 'start_index')
  final int? startIndex;
  
  @JsonKey(name: 'end_index')
  final int? endIndex;

  WordHyplinkRM({
    this.word,
    this.startIndex,
    this.endIndex,
  });

  factory WordHyplinkRM.fromJson(Map<String, dynamic> json) => _$WordHyplinkRMFromJson(json);
  Map<String, dynamic> toJson() => _$WordHyplinkRMToJson(this);
}
