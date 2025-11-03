import 'package:dharak_flutter/app/types/dictionary/definition.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dict_word_detail.g.dart';

@JsonSerializable()
class DictWordDetailRM {

  
  @JsonKey(name: 'llm_def')
  final String? llmDef;

  final String? word;

  final List<WordDefinitionRM> definitions;


  @JsonKey(name: 'other_scripts')
  final Map<String, String?> otherScripts;


  DictWordDetailRM({
     this.llmDef,
     this.word,
     this.definitions = const[],
     this.otherScripts =  const {},
  });

  factory DictWordDetailRM.fromJson(Map<String, dynamic> json) => _$DictWordDetailRMFromJson(json);
  Map<String, dynamic> toJson() => _$DictWordDetailRMToJson(this);
}
