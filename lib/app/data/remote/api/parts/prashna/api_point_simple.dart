import 'package:dharak_flutter/app/data/remote/api/parts/prashna/dto/chat_request_dto.dart';
import 'package:dharak_flutter/app/data/services/developer_mode_service.dart';
import 'package:dharak_flutter/app/types/prashna/ai_model.dart';
import 'package:dharak_flutter/flavors.dart';
import 'package:dio/dio.dart';

/// Simple API point for Prashna without Retrofit - handles SSE streaming directly
class PrashnaApiPointSimple {
  final Dio _dio;
  final String _defaultBaseUrl;

  PrashnaApiPointSimple({required Dio dio, required String baseUrl}) 
      : _dio = dio, _defaultBaseUrl = baseUrl;
  
  /// Get the current base URL (developer mode aware)
  String get _baseUrl {
    if (DeveloperModeService.instance.isAuthenticated) {
      return DeveloperModeService.instance.currentApiUrl ?? _defaultBaseUrl;
    }
    return _defaultBaseUrl;
  }

  /// Unified chat endpoint - Returns SSE stream for any AI model
  Future<Response<ResponseBody>> askWithModel(ChatRequestDto request, AiModel model) async {
    return await _dio.get<ResponseBody>(
      '$_baseUrl/prashna/ask/',
      queryParameters: {
        'model': model.modelParameter,
        'query': request.message,
        'session_id': request.sessionId,
      },
      options: Options(
        headers: {
          'Accept': '*/*',
          'requiresToken': true,
        },
        responseType: ResponseType.stream,
      ),
    );
  }

  /// Legacy method for Gemini - now uses unified endpoint
  @Deprecated('Use askWithModel instead')
  Future<Response<ResponseBody>> askGemini(ChatRequestDto request) async {
    return askWithModel(request, AiModel.gemini);
  }

  /// Legacy method for LangGraph - now uses unified endpoint  
  @Deprecated('Use askWithModel instead')
  Future<Response<ResponseBody>> askLangGraph(ChatRequestDto request) async {
    return askWithModel(request, AiModel.qwen);
  }

  /// Fetch reference data for source IDs (webapp format: {"verse": [1,2], "defn": [671], "chunk": [10,11]})
  Future<Response<Map<String, dynamic>>> fetchReferenceData(Map<String, List<dynamic>> sourceIds) async {
    return await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/api/ref_data/',
      data: sourceIds,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'requiresToken': true,
        },
      ),
    );
  }
}
