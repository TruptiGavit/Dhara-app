import 'package:json_annotation/json_annotation.dart';

part 'share_req_dto.g.dart';

@JsonSerializable()
class ShareReqDto {
  @JsonKey(name: 'content_type')
  final String contentType; // 'verse' or 'definition'
  
  @JsonKey(name: 'content_id')
  final String contentId;
  
  @JsonKey(name: 'platform')
  final String platform; // 'whatsapp', 'instagram', 'twitter', etc.
  
  @JsonKey(name: 'share_type')
  final String shareType; // 'text', 'image', 'link'
  
  @JsonKey(name: 'user_id')
  final String? userId;

  const ShareReqDto({
    required this.contentType,
    required this.contentId,
    required this.platform,
    required this.shareType,
    this.userId,
  });

  factory ShareReqDto.fromJson(Map<String, dynamic> json) => _$ShareReqDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ShareReqDtoToJson(this);
}

