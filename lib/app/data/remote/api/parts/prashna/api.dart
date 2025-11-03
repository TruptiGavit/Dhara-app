import 'dart:async';
import 'dart:convert';

import 'package:dharak_flutter/app/data/remote/api/base/api_request.dart';
import 'package:dharak_flutter/app/data/remote/api/base/dto/error_dto.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/prashna/api_point_simple.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/prashna/dto/chat_request_dto.dart';
import 'package:dharak_flutter/app/types/prashna/ai_model.dart';
import 'package:dharak_flutter/app/types/prashna/sse_event.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class PrashnaApiRepo extends ApiRequest<ErrorDto> {
  final PrashnaApiPointSimple apiPoint;

  PrashnaApiRepo({required this.apiPoint});



  /// Send chat message and get SSE stream response
  Stream<SseEventResult> sendChatMessage({
    required String message,
    required String sessionId,
    required AiModel aiModel,
  }) async* {
    try {
      final request = ChatRequestDto(
        message: message,
        sessionId: sessionId,
      );


      // Direct API call with proper error handling using unified endpoint
      final response = await apiPoint.askWithModel(request, aiModel);

      if (response.statusCode == 200) {
        yield* _parseSSEStream(response.data!.stream, aiModel);
      } else {
        final errorMessage = 'HTTP ${response.statusCode}: ${response.statusMessage}';
        yield SseEventResult(
          error: errorMessage,
          isComplete: true,
        );
      }
    } on DioException catch (e) {
      yield SseEventResult(
        error: _getDioErrorMessage(e),
        isComplete: true,
      );
    } catch (e, stackTrace) {
      yield SseEventResult(
        error: 'An unexpected error occurred: ${e.toString()}',
        isComplete: true,
      );
    }
  }

  /// Parse SSE stream from response
  Stream<SseEventResult> _parseSSEStream(Stream<List<int>> stream, AiModel aiModel) async* {
    StreamController<String> lineController = StreamController<String>();
    String buffer = '';

    // Convert byte stream to line stream
    stream.listen(
      (bytes) {
        final chunk = utf8.decode(bytes);
        buffer += chunk;
        
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // Keep incomplete line in buffer
        
        for (final line in lines) {
          lineController.add(line);
        }
      },
      onDone: () {
        if (buffer.isNotEmpty) {
          lineController.add(buffer);
        }
        lineController.close();
      },
      onError: (error) {
        lineController.addError(error);
      },
    );

    // Parse SSE lines
    await for (final line in lineController.stream) {
      final result = _parseSseLine(line, aiModel);
      if (result != null) {
        yield result;
      }
    }

    yield const SseEventResult(isComplete: true);
  }

  /// Parse individual SSE line
  SseEventResult? _parseSseLine(String line, AiModel aiModel) {
    try {
      // Skip empty lines and comments
      if (line.trim().isEmpty || line.startsWith(':')) {
        return null;
      }

      String jsonStr = line.trim();

      // Handle traditional SSE format: "data: {json}"
      if (line.startsWith('data: ')) {
        jsonStr = line.substring(6).trim();
      }
      
      // Handle end of stream markers
      if (jsonStr == '[DONE]' || jsonStr.isEmpty) {
        return const SseEventResult(isComplete: true);
      }

      // Try to parse as JSON (supports both SSE and raw JSON formats)
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        final event = SseEvent.fromJson(json);
        
        
        return SseEventResult(event: event);
      } catch (e) {
        return SseEventResult(error: 'Failed to parse response data');
      }
    } catch (e) {
      return SseEventResult(error: 'Failed to parse response line');
    }
  }

  /// Get user-friendly error message from DioException
  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. The server is taking too long to respond.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return 'Authentication failed. Please log in again.';
        } else if (statusCode == 403) {
          return 'Access denied. You may not have permission to use this feature.';
        } else if (statusCode == 429) {
          return 'Too many requests. Please wait a moment and try again.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        }
        return 'Server returned error $statusCode. Please try again.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Connection failed. Please check your internet connection.';
      case DioExceptionType.badCertificate:
        return 'Security certificate error. Please check your connection.';
      case DioExceptionType.unknown:
        return 'Network error. Please check your connection and try again.';
    }
  }

  /// Fetch reference data for source citations (webapp format)
  Future<Map<String, dynamic>> fetchReferenceData(Map<String, List<dynamic>> sourceIds) async {
    try {
      
      final response = await apiPoint.fetchReferenceData(sourceIds);
      
      if (response.statusCode == 200 && response.data != null) {
        // Reference data fetched successfully
        return response.data!;
      } else {
        throw Exception('Failed to fetch reference data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMessage = _getDioErrorMessage(e);
      throw Exception('Failed to fetch reference data: $errorMessage');
    } catch (e) {
      throw Exception('Failed to fetch reference data: $e');
    }
  }

  /// Generate unique session ID
  static String generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'session_${timestamp}_$random';
  }
}
