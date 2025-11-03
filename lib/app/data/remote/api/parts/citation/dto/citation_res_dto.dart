import 'package:json_annotation/json_annotation.dart';

part 'citation_res_dto.g.dart';

@JsonSerializable()
class CitationResDto {
  @JsonKey(name: 'cite_data')
  final CitationDataDto? citeData;

  CitationResDto({
    this.citeData,
  });

  factory CitationResDto.fromJson(Map<String, dynamic> json) => _$CitationResDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CitationResDtoToJson(this);
}

@JsonSerializable()
class CitationDataDto {
  @JsonKey(name: 'APA')
  final String apa;
  
  @JsonKey(name: 'MLA')
  final String mla;
  
  @JsonKey(name: 'Harvard')
  final String harvard;
  
  @JsonKey(name: 'Chichago') // Note: Backend API uses "Chichago" spelling
  final String chicago;
  
  @JsonKey(name: 'Vancouver')
  final String vancouver;

  CitationDataDto({
    required this.apa,
    required this.mla,
    required this.harvard,
    required this.chicago,
    required this.vancouver,
  });

  factory CitationDataDto.fromJson(Map<String, dynamic> json) => _$CitationDataDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CitationDataDtoToJson(this);
}