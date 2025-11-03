import 'package:json_annotation/json_annotation.dart';

part 'auth_login_req_dto.g.dart';

@JsonSerializable()
class AuthLoginReqDto {
  @JsonKey(name: 'access_token')
  final String? accessToken;

  @JsonKey(name: 'id_token')
  final String? idToken;

  String? client;

  AuthLoginReqDto({
    this.accessToken,
    this.idToken,
    this.client,
  });

  factory AuthLoginReqDto.fromJson(Map<String, dynamic> json) =>
      _$AuthLoginReqDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AuthLoginReqDtoToJson(this);
}