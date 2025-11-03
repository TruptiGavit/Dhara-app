import 'package:json_annotation/json_annotation.dart';

part 'share_data_res_dto.g.dart';

@JsonSerializable()
class ShareDataResDto {
  @JsonKey(name: "share_data")
  final String shareData;

  ShareDataResDto({
    required this.shareData,
  });

  factory ShareDataResDto.fromJson(Map<String, dynamic> json) => _$ShareDataResDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ShareDataResDtoToJson(this);
}

