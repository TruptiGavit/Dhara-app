import 'package:dharak_flutter/app/data/remote/api/base/api_request.dart';
import 'package:dharak_flutter/app/data/remote/api/base/api_response.dart';
import 'package:dharak_flutter/app/data/remote/api/base/dto/error_dto.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/auth/dto/auth_login_req_dto.dart';
import 'package:dharak_flutter/app/types/auth/login.dart';
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

part 'api.g.dart';

@RestApi()
abstract class AuthApiPoint {
  factory AuthApiPoint(Dio dio, {String baseUrl}) = _AuthApiPoint;

  @POST('/api/glogin/')
  Future<AuthLoginRM> login(@Body() AuthLoginReqDto request);
}

class AuthApiRepo extends ApiRequest<ErrorDto> {
  final AuthApiPoint apiPoint;

  AuthApiRepo({required this.apiPoint});

  Future<ApiResponse<AuthLoginRM, ErrorDto>> login(AuthLoginReqDto request) async {
    var result = await sendRequest(
      () => apiPoint.login(request),
      (data) => Future.value(ErrorDto.fromJson(data)),
    );

    return result;
  }
}