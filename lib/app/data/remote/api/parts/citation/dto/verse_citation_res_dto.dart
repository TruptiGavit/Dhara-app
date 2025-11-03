import 'package:json_annotation/json_annotation.dart';

part 'verse_citation_res_dto.g.dart';

@JsonSerializable()
class VerseCitationResDto {
  @JsonKey(name: 'cite_data')
  final VerseCitationDataDto? citeData;

  VerseCitationResDto({
    this.citeData,
  });

  factory VerseCitationResDto.fromJson(Map<String, dynamic> json) => _$VerseCitationResDtoFromJson(json);
  Map<String, dynamic> toJson() => _$VerseCitationResDtoToJson(this);
}

@JsonSerializable()
class VerseCitationDataDto {
  @JsonKey(name: 'Footnote')
  final String footnote;

  VerseCitationDataDto({
    required this.footnote,
  });

  factory VerseCitationDataDto.fromJson(Map<String, dynamic> json) => _$VerseCitationDataDtoFromJson(json);
  Map<String, dynamic> toJson() => _$VerseCitationDataDtoToJson(this);
}