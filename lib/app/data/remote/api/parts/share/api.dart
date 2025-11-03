import 'package:dharak_flutter/app/data/remote/api/base/api_request.dart';
import 'package:dharak_flutter/app/data/remote/api/base/api_response.dart';
import 'package:dharak_flutter/app/data/remote/api/base/dto/error_dto.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/share/api_point.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/share/dto/share_req_dto.dart';
import 'package:dharak_flutter/app/types/share/share_link.dart';

class ShareApiRepo extends ApiRequest<ErrorDto> {
  ShareApiPoint apiPoint;

  ShareApiRepo({required this.apiPoint});

  Future<ApiResponse<ShareLinkRM, ErrorDto>> trackShare(ShareReqDto body, String app) async {
    final queries = body.toJson();
    var result = await sendRequest(
      () => apiPoint.trackShare(app, queries),
      (data) => Future.value(ErrorDto.fromJson(data)),
    );

    // Convert DTO to RM
    if (result.status == ApiResponseStatus.SUCCESS && result.data != null) {
      final convertedResult = ApiResponse<ShareLinkRM, ErrorDto>.success(
        data: ShareLinkRM.fromDto(result.data!),
      );
      return convertedResult;
    }
    
    return ApiResponse<ShareLinkRM, ErrorDto>.error(error: result.error);
  }

  Future<ApiResponse<ShareLinkRM, ErrorDto>> generateShareLink(String contentType, String contentId) async {
    var result = await sendRequest(
      () => apiPoint.generateShareLink(contentType, contentId),
      (data) => Future.value(ErrorDto.fromJson(data)),
    );

    // Convert DTO to RM
    if (result.status == ApiResponseStatus.SUCCESS && result.data != null) {
      final convertedResult = ApiResponse<ShareLinkRM, ErrorDto>.success(
        data: ShareLinkRM.fromDto(result.data!),
      );
      return convertedResult;
    }
    
    return ApiResponse<ShareLinkRM, ErrorDto>.error(error: result.error);
  }

  /// Get share content for copy text - returns formatted text ready for clipboard
  Future<ApiResponse<String, ErrorDto>> getShareContentForCopy({
    String? word,
    String? defId,
    String? verseId,
  }) async {
    var result = await sendRequest(
      () => apiPoint.getShareContent(
        'copy', // platform
        'text', // type
        word,   // word parameter
        defId,  // defId parameter  
        verseId, // verseId parameter
      ),
      (data) => Future.value(ErrorDto.fromJson(data)),
    );

    return result;
  }

  /// Get share content for image sharing - logs the share action
  Future<ApiResponse<String, ErrorDto>> getShareContentForImage({
    String? word,
    String? defId,
    String? verseId,
  }) async {
    var result = await sendRequest(
      () => apiPoint.getShareContent(
        'app',    // platform
        'image',  // type
        word,     // word parameter
        defId,    // defId parameter  
        verseId,  // verseId parameter
        requiresToken: true, // needed to identify the user
      ),
      (data) => Future.value(ErrorDto.fromJson(data)),
    );

    return result;
  }
}
