import 'package:dharak_flutter/app/data/remote/api/parts/auth/dto/auth_login_req_dto.dart';
import 'package:dharak_flutter/app/types/auth/login.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'api_point.g.dart';

@RestApi()
abstract class AuthApiPoint {
  factory AuthApiPoint(Dio dio, {String baseUrl,}) = _AuthApiPoint;

  @POST("/api/google_login/")
  Future<AuthLoginRM> login(@Body() AuthLoginReqDto body);

  

  // @GET("/auth/login")
  // Future<AccessTokenType> login2(
  //     {@Query("email") String? email, @Query("password") String? password});

  //  @POST("/auth/verify")
  // Future<ParamAuth> verify(@Body() Map<String, dynamic> body);
}
