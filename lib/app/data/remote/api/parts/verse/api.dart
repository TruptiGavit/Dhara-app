import 'dart:developer';

import 'package:dharak_flutter/app/data/remote/api/base/api_request.dart';
import 'package:dharak_flutter/app/data/remote/api/base/api_response.dart';
import 'package:dharak_flutter/app/data/remote/api/base/dto/error_dto.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/verse/api_point.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/verse/dto/dto_converter.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/verse/dto/languages/get_dto.dart';
import 'package:dharak_flutter/app/types/search-history/result.dart';
import 'package:dharak_flutter/app/types/verse/bookmarks/bookmark_toggle_result.dart';
import 'package:dharak_flutter/app/types/verse/bookmarks/bookmarks_result.dart';
import 'package:dharak_flutter/app/types/verse/verse_prev_next_result.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/types/verse/verse_foot.dart';
import 'package:dharak_flutter/app/types/verse/verse_head.dart';
import 'package:dharak_flutter/app/types/verse/verses.dart';
import 'package:dio/dio.dart';

class VerseApiRepo extends ApiRequest<ErrorDto> {
  final VerseApiPoint apiPoint;

  final Dio dio;
  final String baseUrl;
  // final VerseDtoConverter  dtoConverter =  VerseDtoConverter();

  VerseApiRepo({
    required this.apiPoint,
    required this.dio,
    required this.baseUrl,
  });

  // factory VerseApiRepo(Dio dio, {String baseUrl}) = VerseApiRepo;

  // @POST("/auth/verify")
  Future<ApiResponse<VersesResultRM, ErrorDto>> getVerses({
    required String inputStr,
  }) async {
    var result = await sendRequest(
      () => apiPoint.getVerses(inputStr: inputStr, requiresToken: true),
      (data) {
        return Future.value(ErrorDto.fromJson(data));
      },
    );

    if (result.status == ApiResponseStatus.SUCCESS && result.data != null) {
      var result2 = VerseDtoConverter.parseResponse(result.data!);
      // inspect(result2);
      return ApiResponse.success(data: result2);
    } else if (result.error != null) {
      inspect(result);
      return ApiResponse.error(
        data: null,

        error: result.error,
        message: result.error?.message ?? result.message,
      );
    }

    // return result;

    return ApiResponse.error(message: "dsd");
  }

  Future<ApiResponse<VerseBookmarksResultRM, ErrorDto>> getBookmarks() async {
    var result = await sendRequest(
      () => apiPoint.getBookmarks(requiresToken: true),
      (data) => Future.value(ErrorDto.fromJson(data)),
    );

    return result;
  }

  Future<ApiResponse<VerseBookmarkToggleResultRM, ErrorDto>> toggleBookmark(
    String id, {
    bool isToRemove = true,
  }) async {
    var result = await sendRequest(
      () =>
          isToRemove ? apiPoint.unstarBookmark(id, requiresToken: true) : apiPoint.starBookmark(id, requiresToken: true),
      (data) => Future.value(ErrorDto.fromJson(data)),
    );

    return result;
  }

  Future<ApiResponse<VerseLanguagePrefGetResultDto, ErrorDto>> getLanguagePref({
    String? output,
  }) async {
    var result = await sendRequest(
      () => apiPoint.getLanguagePref(output: output, requiresToken: true),
      (data) => Future.value(ErrorDto.fromJson(data)),
    );

    return result;
  }

  Future<ApiResponse<SearchHistoryResultRM, ErrorDto>>
  getSearchHistory() async {
    var result = await sendRequest(
      () => apiPoint.getSearchHistory(requiresToken: true),
      (data) => Future.value(ErrorDto.fromJson(data)),
    );

    return result;
  }

  // Get previous verse by verse_pk - follows same pattern as other API calls
  // Uses sendRequest helper for consistent error handling and response processing
  Future<ApiResponse<VersePrevNextResultRM, ErrorDto>> getPreviousVerse({
    required String versePk,
  }) async {
    var result = await sendRequest(
      () => apiPoint.getPreviousVerse(versePk, requiresToken: true),
      (data) => Future.value(ErrorDto.fromJson(data)),
    );

    return result;
  }

  // Get next verse by verse_pk - follows same pattern as other API calls  
  // Uses sendRequest helper for consistent error handling and response processing
  Future<ApiResponse<VersePrevNextResultRM, ErrorDto>> getNextVerse({
    required String versePk,
  }) async {
    var result = await sendRequest(
      () => apiPoint.getNextVerse(versePk, requiresToken: true),
      (data) => Future.value(ErrorDto.fromJson(data)),
    );

    return result;
  }

  Future<ApiResponse<bool, ErrorDto>> getVersesByCallback({
    required String inputStr,
    required void Function({
      VerseRM? item,
      VerseFootRM? footer,
      VerseHeadRM? header,
    })
    onItem,
  }) async {
    // var result = await sendRequest(
    //   () => apiPoint.getVerses(inputStr: inputStr),
    //   (data) {
    //     return Future.value(ErrorDto.fromJson(data));
    //   },
    // );

    // var res = await dio.get<ResponseBody>(
    //   "",
    //   options: Options(responseType: ResponseType.stream),
    // );

    var result = await sendRequestStreamLine<bool>(
      () => dio.get<ResponseBody>(
        "${baseUrl}/verse/v2/find",
        queryParameters: {"input_string": inputStr},
        
        options: Options(responseType: ResponseType.stream, headers: {
"requiresToken": true
        }),
      ),
      () {
        return true;
      },
      (data) {
        return Future.value(ErrorDto.fromJson(data));
      },
      callback: (line) {
        var jsonMap = VerseDtoConverter.parseResponseJson(line);

        if (jsonMap != null && jsonMap.isNotEmpty) {
          try {
            final dataType = jsonMap["data_type"];
            print("line: ${dataType}");

            if (dataType == null || dataType is! String) return;

            switch (dataType as String) {
              case "head":
                inspect(jsonMap);
                onItem.call(header: VerseHeadRM.fromJson(jsonMap));
                break;
              case "verse":
                onItem.call(item: VerseRM.fromJson(jsonMap));
                break;
              case "foot":
                onItem.call(footer: VerseFootRM.fromJson(jsonMap));
                break;
              case "info":
                // Handle new info type from v2 API - just log it for now
                print("Info data type received: $jsonMap");
                break;
              default:
                print("Unknown data type: $dataType");
            }
          } catch (e) {
            inspect(jsonMap);
            print("JSON Parsing Error: ${e}");
            // print("${jsonMap}")
          }
        }
      },
    );

    // res.data.stream

    // response

    // if (result.status == ApiResponseStatus.SUCCESS && result.data != null) {
    //   var result2 = VerseDtoConverter.parseResponse(result.data!);
    //   // inspect(result2);
    //   return ApiResponse.success(data: result2);
    // } else if (result.error != null) {
    //   inspect(result);
    //   return ApiResponse.error(
    //     data: null,

    //     error: result.error,
    //     message: result.error?.message ?? result.message,
    //   );
    // }

    return result;

    // return ApiResponse.error(message: "dsd");
  }
}