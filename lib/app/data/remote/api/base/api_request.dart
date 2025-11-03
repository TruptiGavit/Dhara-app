import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dharak_flutter/app/data/remote/api/base/api_response.dart';
import 'package:dio/dio.dart';

class ApiRequest<ErrorType> {
  Future<ApiResponse<T, ErrorType>> sendRequest<T>(
    Future<T> Function() call,
    Future<ErrorType> Function(Map<String, dynamic> data) errorParse,
  ) async {
    try {
      var result = await call();

      return ApiResponse<T, ErrorType>.success(data: result);
    } on DioException catch (e) {
      // print(e.message);

      print("ApiRequest sendRequest 1: $e");
      inspect(e);

      // inspect(e);
      String message = "";

      if (e.response?.statusMessage != null) {
        message = e.response!.statusMessage!;
      } else {
        message = e.message ?? "";
      }

      ErrorType? errorObject;
      if (e.response?.data != null) {
        try {
          if (e.response?.data is String) {
            errorObject = await errorParse(
              jsonDecode(e.response?.data) as Map<String, dynamic>,
            );
          } else {
            errorObject = await errorParse(
              e.response?.data as Map<String, dynamic>,
            );
          }
        } catch (err) {
          print("ApiRequest sendRequest 2: $err");
          print("ApiRequest sendRequest 3 e: ${e.response?.data}");
          inspect(e.response?.data);
        }
      }

      return ApiResponse<T, ErrorType>.error(
        message: message,
        error: errorObject,
        dioStatusCode: e.response?.statusCode,
      );
      // if(e.response){
      //   e.response

      // }
    } catch (error) {
      inspect(error);
      return ApiResponse<T, ErrorType>.error(message: "Something went wrong 2");
    }
  }

  Future<ApiResponse<T, ErrorType>> sendRequestStreamLine<T>(
    Future<Response<ResponseBody>> Function() call,
    T Function() onDone,
    Future<ErrorType> Function(Map<String, dynamic> data) errorParse, {
    void Function(String line)? callback,
  }) async {
    StreamTransformer<Uint8List, List<int>> unit8Transformer =
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            sink.add(List<int>.from(data));
          },
        );
    try {
      var response = await call();

      final stream = response.data?.stream
          .transform(unit8Transformer)
          .transform(const Utf8Decoder())
          .transform(const LineSplitter());

      if (stream != null) {
        await for (final line in stream) {
          if (line.trim().isEmpty) continue;
          callback?.call(line);
        }
      }

      return ApiResponse.success(data: onDone());

      //     return ApiResponse<T, ErrorType>.success(data: result);
    } on DioException catch (e) {
      // print(e.message);

      print("ApiRequest sendRequest 1: $e");
      // inspect(e);

      // inspect(e);
      String message = "";

      if (e.response?.statusMessage != null) {
        message = e.response!.statusMessage!;
      } else {
        message = e.message ?? "";
      }

      ErrorType? errorObject;
      if (e.response?.data != null) {
        try {
          if (e.response?.data is String) {
            errorObject = await errorParse(
              jsonDecode(e.response?.data) as Map<String, dynamic>,
            );
          } else if (e.response?.data is ResponseBody) {
            print(
              "ApiRequest sendRequest 1 3: ${(e.response?.data as ResponseBody).statusCode}",
            );

            inspect(e.response?.data);
            // final errorStream = (e.response?.data as ResponseBody).stream..toString();
            //     print("object: ${errorStream}");

            final errorStream = (e.response?.data as ResponseBody).stream
                .transform(unit8Transformer)
                .transform(const Utf8Decoder())
                .transform(const LineSplitter());

            // print("object: ${errorStream}");

            if (errorStream != null) {
              await for (final line in errorStream) {
                if (line.trim().isEmpty) continue;
                // callback?.call(line);
                print("object: ${line}");

                try {
                  errorObject = await errorParse(
                    jsonDecode(line) as Map<String, dynamic>,
                  );
                } catch (e) {

                  print("ApiRequest sendRequest e parse 1 ");
                }

                if (errorObject != null) {
                  break;
                }
              }
            }
          } else {
            errorObject = await errorParse(
              e.response?.data as Map<String, dynamic>,
            );
          }
        } catch (err) {
          print("ApiRequest sendRequest 2: $err");
          print("ApiRequest sendRequest 3 e: ${e.response?.data}");
        }
      }

      // print()

      

      return ApiResponse<T, ErrorType>.error(
        message: message,
        error: errorObject,
        dioStatusCode: e.response?.statusCode,
      );
      // if(e.response){
      //   e.response

      // }
    } catch (error) {
      inspect(error);
      return ApiResponse<T, ErrorType>.error(message: "Something went wrong 2");
    }
  }
}
