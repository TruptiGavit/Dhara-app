import 'package:json_annotation/json_annotation.dart';

part 'definition_copy_req_dto.g.dart';

@JsonSerializable()
class DefinitionCopyReqDto {
  @JsonKey(name: "defn_ids")
  final List<int> defnIds;

  DefinitionCopyReqDto({
    required this.defnIds,
  });

  factory DefinitionCopyReqDto.fromJson(Map<String, dynamic> json) => _$DefinitionCopyReqDtoFromJson(json);
  Map<String, dynamic> toJson() => _$DefinitionCopyReqDtoToJson(this);
}

