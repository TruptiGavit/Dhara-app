import 'package:dharak_flutter/app/data/remote/api/parts/share/dto/share_link_res_dto.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'api_point.g.dart';

@RestApi()
abstract class ShareApiPoint {
  factory ShareApiPoint(Dio dio, {String baseUrl}) = _ShareApiPoint;

  @GET("/share/{app}/")
  Future<ShareLinkResDto> trackShare(
    @Path("app") String app,
    @Queries() Map<String, dynamic> queries,
  );

  @GET("/share/link/")
  Future<ShareLinkResDto> generateShareLink(
    @Query("content_type") String contentType,
    @Query("content_id") String contentId,
  );

  @GET("/share/")
  Future<String> getShareContent(
    @Query("platform") String platform,
    @Query("type") String type,
    @Query("word") String? word,
    @Query("def_id") String? defId,
    @Query("verse_id") String? verseId, {
    @Header("requiresToken") bool requiresToken = false,
  });
}
