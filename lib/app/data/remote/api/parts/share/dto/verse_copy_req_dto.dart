import 'package:json_annotation/json_annotation.dart';

part 'verse_copy_req_dto.g.dart';

@JsonSerializable()
class VerseCopyReqDto {
  @JsonKey(name: "verse_ids")
  final List<int> verseIds;

  VerseCopyReqDto({
    required this.verseIds,
  });

  factory VerseCopyReqDto.fromJson(Map<String, dynamic> json) => _$VerseCopyReqDtoFromJson(json);
  Map<String, dynamic> toJson() => _$VerseCopyReqDtoToJson(this);
}

