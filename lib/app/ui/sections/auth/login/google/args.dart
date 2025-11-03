import 'package:json_annotation/json_annotation.dart';

part 'args.g.dart';

class GoogleLoginArgsRequest {
  final String purpose;

  GoogleLoginArgsRequest({
    required this.purpose,
  });
}

@JsonSerializable()
class GoogleLoginArgsResult {
  final String resultCode;
  final String? idToken;

  GoogleLoginArgsResult({
    required this.resultCode,
    this.idToken,
  });

  factory GoogleLoginArgsResult.fromJson(Map<String, dynamic> json) =>
      _$GoogleLoginArgsResultFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleLoginArgsResultToJson(this);
}