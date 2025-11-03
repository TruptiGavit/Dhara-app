import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:json_annotation/json_annotation.dart';

part 'verse_sibling_result.g.dart';

// Data model for previous verse API response: /verse/v1/prev_sib/{verse_pk}/
@JsonSerializable()
class VersePrevSiblingResultRM {
  final bool? success;
  final String message;
  
  @JsonKey(name: 'prev_sib')
  final VerseRM? prevSib;

  VersePrevSiblingResultRM({
    this.success,
    required this.message,
    this.prevSib,
  });

  factory VersePrevSiblingResultRM.fromJson(Map<String, dynamic> json) =>
      _$VersePrevSiblingResultRMFromJson(json);
  Map<String, dynamic> toJson() => _$VersePrevSiblingResultRMToJson(this);
}

// Data model for next verse API response: /verse/v1/next_sib/{verse_pk}/
@JsonSerializable()
class VerseNextSiblingResultRM {
  final bool? success;
  final String message;
  
  @JsonKey(name: 'next_sib')
  final VerseRM? nextSib;

  VerseNextSiblingResultRM({
    this.success,
    required this.message,
    this.nextSib,
  });

  factory VerseNextSiblingResultRM.fromJson(Map<String, dynamic> json) =>
      _$VerseNextSiblingResultRMFromJson(json);
  Map<String, dynamic> toJson() => _$VerseNextSiblingResultRMToJson(this);
} 