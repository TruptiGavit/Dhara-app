import 'package:dharak_flutter/app/data/remote/api/base/api_request.dart';
import 'package:dharak_flutter/app/data/remote/api/base/api_response.dart';
import 'package:dharak_flutter/app/data/remote/api/base/dto/error_dto.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/citation/api_point.dart';
import 'package:dharak_flutter/app/types/citation/citation.dart';
import 'package:dharak_flutter/app/types/citation/verse_citation.dart';

class CitationApiRepo extends ApiRequest<ErrorDto> {
  CitationApiPoint apiPoint;

  CitationApiRepo({required this.apiPoint});

  Future<ApiResponse<CitationRM, ErrorDto>> getDefinitionCitation(int dictRefId) async {
    var result = await sendRequest(
      () => apiPoint.getDefinitionCitation(dictRefId),
      (data) => Future.value(ErrorDto.fromJson(data)),
    );

    return result;
  }

  Future<ApiResponse<VerseCitationRM, ErrorDto>> getVerseCitation(int versePk) async {
    var result = await sendRequest(
      () => apiPoint.getVerseCitation(versePk),
      (data) => Future.value(ErrorDto.fromJson(data)),
    );

    return result;
  }
}

