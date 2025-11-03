import 'package:dharak_flutter/app/data/local/secure/secure_local_data.dart';
import 'package:dharak_flutter/app/data/remote/api/interceptors/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
// import 'package:hundi_flutter/app/data/base/remote/interceptor/tokenInterceptor_api.dart';

class DioCreator {
  // final TokenInterceptor tokenInterceptor;

  late final Dio dio;

  final SecureLocalData storage;

  late final AuthInterceptor authInterceptor;

  // final FbAuthService fbAuthService;

  // DioCreator({required this.storage, required this.fbAuthService})

  DioCreator({required this.storage}) {
    dio = Dio(
      BaseOptions(
        contentType: "application/json",
        // headers: <String, String>{"ngrok-skip-browser-warning": "ss"}
      ),
    );

    authInterceptor = AuthInterceptor(dio, storage);

    dio.interceptors.addAll([
      authInterceptor,

      // Temporarily disable verbose API logging to see Prashna debug logs
      PrettyDioLogger(responseBody: false, requestHeader: false, requestBody: false),
    ]);
  }

  Dio getDio() {
    return dio;
  }

  AuthInterceptor getAuthInterceptor() {

    return authInterceptor;
  }
}
