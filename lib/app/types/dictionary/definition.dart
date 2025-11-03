import 'package:dharak_flutter/app/types/dictionary/word_hyplink.dart';
import 'package:json_annotation/json_annotation.dart';

part 'definition.g.dart';

@JsonSerializable()
class WordDefinitionRM {

  
  // "text": 
  // "short_text":        
  // "language":
  // "source":
  // "src_short_title": 
  // "source_url":


  final String text;

  @JsonKey(name: 'short_text')
  final String shortText;

  final String language;

  final String source;

  @JsonKey(name: 'src_short_title')
  final String srcShortTitle;

  @JsonKey(name: 'source_url')
  final String? sourceUrl;

  @JsonKey(name: 'dict_ref_id')
  final int? dictRefId;

  @JsonKey(name: 'word_hyplinks')
  final List<WordHyplinkRM>? wordHyplinks;




  WordDefinitionRM({
    required this.text,
    required this.shortText,
    required this.language,
    required this.source,
    required this.srcShortTitle,
    this.sourceUrl,
    this.dictRefId,
    this.wordHyplinks,
  });

  factory WordDefinitionRM.fromJson(Map<String, dynamic> json) => _$WordDefinitionRMFromJson(json);
  Map<String, dynamic> toJson() => _$WordDefinitionRMToJson(this);
}
