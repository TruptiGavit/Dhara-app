
import 'package:dharak_flutter/app/types/dictionary/word_definitions.dart';
import 'package:dharak_flutter/app/types/search-history/result.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'api_point.g.dart';

@RestApi()
abstract class DictionaryApiPoint {
  factory DictionaryApiPoint(
    Dio dio, {
    String baseUrl,
  }) = _DictionaryApiPoint;

  @GET("/dict/v1_5/get_defs/")
  Future<DictWordDefinitionsRM> getDefinition(
      {@Query("word") required String word, @Header("requiresToken") bool requiresToken = false});

  @GET("/dict/history/")
  Future<SearchHistoryResultRM> getSearchHistory(
      { @Header("requiresToken") bool requiresToken = false});

}
