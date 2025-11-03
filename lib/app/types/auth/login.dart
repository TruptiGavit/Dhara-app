import 'package:dharak_flutter/app/types/user/user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'login.g.dart';

@JsonSerializable()
class AuthLoginRM {
  @JsonKey(name: 'access_token')
  final String accessToken;

  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  @JsonKey(name: 'user')
  final UserRM? user;

  const AuthLoginRM({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  factory AuthLoginRM.fromJson(Map<String, dynamic> json) =>
      _$AuthLoginRMFromJson(json);

  Map<String, dynamic> toJson() => _$AuthLoginRMToJson(this);
}