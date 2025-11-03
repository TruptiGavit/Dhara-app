import 'package:dharak_flutter/app/data/remote/api/parts/share/dto/share_link_res_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'share_link.g.dart';

@JsonSerializable()
class ShareLinkRM {
  final String shareId;
  final String shortUrl;
  final String deepLink;
  final String shareMessage;
  final String? expiresAt;

  const ShareLinkRM({
    required this.shareId,
    required this.shortUrl,
    required this.deepLink,
    required this.shareMessage,
    this.expiresAt,
  });

  factory ShareLinkRM.fromJson(Map<String, dynamic> json) => _$ShareLinkRMFromJson(json);
  Map<String, dynamic> toJson() => _$ShareLinkRMToJson(this);

  factory ShareLinkRM.fromDto(ShareLinkResDto dto) {
    return ShareLinkRM(
      shareId: dto.shareId,
      shortUrl: dto.shortUrl,
      deepLink: dto.deepLink,
      shareMessage: dto.shareMessage,
      expiresAt: dto.expiresAt,
    );
  }
}
