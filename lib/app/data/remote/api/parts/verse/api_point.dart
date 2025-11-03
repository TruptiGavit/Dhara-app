// import 'package:dharak_flutter/app/types/verse/verses.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/verse/dto/languages/get_dto.dart';
import 'package:dharak_flutter/app/types/search-history/result.dart';
import 'package:dharak_flutter/app/types/verse/bookmarks/bookmark_toggle_result.dart';
import 'package:dharak_flutter/app/types/verse/bookmarks/bookmarks_result.dart';
import 'package:dharak_flutter/app/types/verse/verse_prev_next_result.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'api_point.g.dart';

@RestApi()
abstract class VerseApiPoint {
  factory VerseApiPoint(Dio dio, {String baseUrl}) = _VerseApiPoint;

  @GET("/verse/v2/find/")
  Future<String> getVerses({
    @Query("input_string") required String inputStr,
    @Header("requiresToken") bool requiresToken = false,
    // @Header("Accept") String accept = "text/plain",
  });

  @GET("/verse/get_starred/")
  Future<VerseBookmarksResultRM> getBookmarks({
    @Header("requiresToken") bool requiresToken = false,
    // @Header("Accept") String accept = "text/plain",
  });

  @GET("/verse/unstar/{id}/")
  Future<VerseBookmarkToggleResultRM> unstarBookmark(
    @Path("id") String id, {
    @Header("requiresToken") bool requiresToken = false,
    // @Header("Accept") String accept = "text/plain",
  });

  @GET("/verse/star/{id}/")
  Future<VerseBookmarkToggleResultRM> starBookmark(
    @Path("id") String id, {
    @Header("requiresToken") bool requiresToken = false,
    // @Header("Accept") String accept = "text/plain",
  });

  @GET("/verse/history/")
  Future<SearchHistoryResultRM> getSearchHistory({
    @Header("requiresToken") bool requiresToken = false,
  });

  @GET("/verse/v1/language/")
  Future<VerseLanguagePrefGetResultDto> getLanguagePref({
    @Header("requiresToken") bool requiresToken = false,
    @Query("output") String? output,
  });

  // Previous verse API endpoint - gets the previous sibling verse by verse_pk
  @GET("/verse/v1/prev_sib/{verse_pk}/")
  Future<VersePrevNextResultRM> getPreviousVerse(
    @Path("verse_pk") String versePk, {
    @Header("requiresToken") bool requiresToken = false,
  });

  // Next verse API endpoint - gets the next sibling verse by verse_pk  
  @GET("/verse/v1/next_sib/{verse_pk}/")
  Future<VersePrevNextResultRM> getNextVerse(
    @Path("verse_pk") String versePk, {
    @Header("requiresToken") bool requiresToken = false,
  });
}