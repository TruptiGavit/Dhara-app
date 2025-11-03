import 'package:json_annotation/json_annotation.dart';

part 'share_link_res_dto.g.dart';

@JsonSerializable()
class ShareLinkResDto {
  @JsonKey(name: 'share_id')
  final String shareId;
  
  @JsonKey(name: 'short_url')
  final String shortUrl;
  
  @JsonKey(name: 'deep_link')
  final String deepLink;
  
  @JsonKey(name: 'share_message')
  final String shareMessage;
  
  @JsonKey(name: 'expires_at')
  final String? expiresAt;

  const ShareLinkResDto({
    required this.shareId,
    required this.shortUrl,
    required this.deepLink,
    required this.shareMessage,
    this.expiresAt,
  });

  factory ShareLinkResDto.fromJson(Map<String, dynamic> json) => _$ShareLinkResDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ShareLinkResDtoToJson(this);
}

