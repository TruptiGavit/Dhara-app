import 'package:dharak_flutter/app/types/dictionary/dict_word_detail.dart';
import 'package:json_annotation/json_annotation.dart';

part 'word_definitions.g.dart';

@JsonSerializable()
class DictWordDefinitionsRM {
  @JsonKey(name: 'given_word')
  final String givenWord;

  final bool success;

  @JsonKey(name: 'found_match')
  final bool? foundMatch;

  final DictWordDetailRM details;

  @JsonKey(name: "similar_words")
  final List<String> similarWords;

  DictWordDefinitionsRM({
    required this.givenWord,
    required this.success,
    required this.foundMatch,
    required this.details,
    this.similarWords = const []

    // this.heading,
  });

  factory DictWordDefinitionsRM.fromJson(Map<String, dynamic> json) =>
      _$DictWordDefinitionsRMFromJson(json);
  Map<String, dynamic> toJson() => _$DictWordDefinitionsRMToJson(this);
}
