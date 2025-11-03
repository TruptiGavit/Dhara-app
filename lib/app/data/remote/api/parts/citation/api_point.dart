import 'package:dharak_flutter/app/types/citation/citation.dart';
import 'package:dharak_flutter/app/types/citation/verse_citation.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'api_point.g.dart';

@RestApi()
abstract class CitationApiPoint {
  factory CitationApiPoint(Dio dio, {String baseUrl}) = _CitationApiPoint;

  @GET("/dict/cite/{dictRefId}/")
  Future<CitationRM> getDefinitionCitation(
    @Path("dictRefId") int dictRefId, {
    @Header("requiresToken") bool requiresToken = true,
  });

  @GET("/verse/cite/{versePk}/")
  Future<VerseCitationRM> getVerseCitation(
    @Path("versePk") int versePk, {
    @Header("requiresToken") bool requiresToken = true,
  });
}
