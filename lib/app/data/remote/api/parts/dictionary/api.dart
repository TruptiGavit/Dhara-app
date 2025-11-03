import 'package:dharak_flutter/app/data/remote/api/base/api_request.dart';
import 'package:dharak_flutter/app/data/remote/api/base/api_response.dart';
import 'package:dharak_flutter/app/data/remote/api/base/dto/error_dto.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/dictionary/api_point.dart';
import 'package:dharak_flutter/app/types/dictionary/word_definitions.dart';
import 'package:dharak_flutter/app/types/search-history/result.dart';

class DictionaryApiRepo extends ApiRequest<ErrorDto> {
  DictionaryApiPoint apiPoint;

  DictionaryApiRepo({required this.apiPoint});
  // factory DictionaryApiRepo(Dio dio, {String baseUrl}) = DictionaryApiRepo;

  // @POST("/auth/verify")
  Future<ApiResponse<DictWordDefinitionsRM, ErrorDto>> getDefinition({
    required String word,
  }) async {
    // print("login: $body");
    var result = await sendRequest(
      () => apiPoint.getDefinition(word: word),
      (data) => Future.value(ErrorDto.fromJson(data)),
    );

    // if (result.status == ApiResponseStatus.SUCCESS) {
    //   result.data?.sort((a, b) => a.messages.firstOrNull?.timestamp != null
    //       ? b.messages.firstOrNull?.timestamp
    //               ?.compareTo(a.messages.firstOrNull!.timestamp!) ??
    //           1
    //       : -1);
    //   // ApiResponse.success(data: )
    // }
    return result;
  }


  Future<ApiResponse<SearchHistoryResultRM, ErrorDto>> getSearchHistory() async {
    // print("login: $body");
    var result = await sendRequest(
      () => apiPoint.getSearchHistory(),
      (data) => Future.value(ErrorDto.fromJson(data)),
    );

    return result;
  }
}
