import 'package:json_annotation/json_annotation.dart';

part 'access_token.g.dart';

@JsonSerializable()
class AccessTokenRM {
  @JsonKey(name: 'access_token')
  final String accessToken;

  // Getter for backward compatibility
  String get access => accessToken;

  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  @JsonKey(name: 'token_type')
  final String tokenType;

  @JsonKey(name: 'expires_in')
  final int expiresIn;

  const AccessTokenRM({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AccessTokenRM.fromJson(Map<String, dynamic> json) =>
      _$AccessTokenRMFromJson(json);

  Map<String, dynamic> toJson() => _$AccessTokenRMToJson(this);
}