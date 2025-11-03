
import 'package:dharak_flutter/app/types/verse/language_pref.dart';
import 'package:json_annotation/json_annotation.dart';

part 'get_dto.g.dart';



@JsonSerializable()
class VerseLanguagePrefGetResultDto {
  final bool? success;
  final String? message;

  @JsonKey(name: "op_lang_pref")
  final String? opLangPref;

  VerseLanguagePrefGetResultDto({
    this.message, 
    this.success,  
    this.opLangPref,
  });

  factory VerseLanguagePrefGetResultDto.fromJson(Map<String, dynamic> json) =>
      _$VerseLanguagePrefGetResultDtoFromJson(json);
  Map<String, dynamic> toJson() => _$VerseLanguagePrefGetResultDtoToJson(this);

  // Convert to VersesLanguagePrefRM for backward compatibility
  VersesLanguagePrefRM get langPref => VersesLanguagePrefRM(
    output: opLangPref,
  );
}

