import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dharak_flutter/app/data/services/developer_mode_service.dart';
import 'package:dharak_flutter/app/types/unified/unified_search_response.dart';
import 'package:dharak_flutter/flavors.dart';

class UnifiedSearchApiPointSimple {
  final Dio _dio = Dio();

  String get _baseUrl {
    // Use developer mode URL if authenticated, otherwise use production URL
    if (DeveloperModeService.instance.isAuthenticated) {
      return DeveloperModeService.instance.currentApiUrl;
    }
    return F.apiUrl;
  }

  /// Perform unified search using the quick_search endpoint
  Stream<UnifiedSearchResponse> unifiedSearch(String query) async* {
    final uri = Uri.parse('$_baseUrl/quick_search/');
    final url = uri.replace(queryParameters: {'query': query}).toString();

    print("🔍 Unified search URL: $url");

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Accept': '*/*',
            'User-Agent': 'Dhara-Flutter-App',
          },
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data.stream as Stream<List<int>>;
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);
        
        // Process complete lines
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // Keep incomplete line in buffer

        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.isNotEmpty) {
            try {
              final json = jsonDecode(trimmedLine) as Map<String, dynamic>;
              yield UnifiedSearchResponse.fromJson(json);
            } catch (e) {
              print("❌ Error parsing unified search line: $e");
              print("❌ Problematic line: $trimmedLine");
            }
          }
        }
      }

      // Process any remaining data in buffer
      if (buffer.trim().isNotEmpty) {
        try {
          final json = jsonDecode(buffer.trim()) as Map<String, dynamic>;
          yield UnifiedSearchResponse.fromJson(json);
        } catch (e) {
          print("❌ Error parsing final unified search buffer: $e");
        }
      }
    } catch (e) {
      print("❌ Unified search error: $e");
      rethrow;
    }
  }

  /// Process unified search responses and organize them
  Future<UnifiedSearchResult> processUnifiedSearch(String query) async {
    UnifiedSplitsResponse? splits;
    List<UnifiedDefinitionResponse> definitions = [];
    UnifiedVerseResponse? verses;
    UnifiedChunkResponse? chunks;

    try {
      await for (final response in unifiedSearch(query)) {
        try {
          switch (response.type) {
            case 'splits':
              if (response.data is Map<String, dynamic>) {
                splits = UnifiedSplitsResponse.fromJson(
                  response.data as Map<String, dynamic>
                );
              } else {
                print("⚠️ Splits data is not a Map: ${response.data.runtimeType}");
              }
              break;
            
            case 'definition':
              if (response.data is Map<String, dynamic>) {
                definitions.add(UnifiedDefinitionResponse.fromJson(
                  response.data as Map<String, dynamic>
                ));
              } else {
                print("⚠️ Definition data is not a Map: ${response.data.runtimeType}");
              }
              break;
            
            case 'verse':
            print("🔍 Found verse data: ${response.data}");
              try {
                if (response.data is Map<String, dynamic>) {
                  verses = UnifiedVerseResponse.fromJson(
                    response.data as Map<String, dynamic>
                  );
                } else if (response.data is List) {
                  // Handle verse data that comes as a list
                  verses = UnifiedVerseResponse.fromList(
                    response.data as List<dynamic>
                  );
                } else {
                  print("⚠️ Verse data is not a Map or List: ${response.data.runtimeType}");
                }
              } catch (e, stackTrace) {
                print("❌ Detailed verse processing error: $e");
                print("📍 Stack trace: $stackTrace");
                print("📄 Raw verse data: ${response.data}");
              }
              break;
            
            case 'chunk':
              if (response.data is Map<String, dynamic>) {
                chunks = UnifiedChunkResponse.fromJson(
                  response.data as Map<String, dynamic>
                );
              } else if (response.data is List) {
                // Handle chunk data that comes as a list
                chunks = UnifiedChunkResponse.fromList(
                  response.data as List<dynamic>
                );
              } else {
                print("⚠️ Chunk data is not a Map or List: ${response.data.runtimeType}");
              }
              break;
            
            default:
              print("⚠️ Unknown unified response type: ${response.type}");
              break;
          }
        } catch (e) {
          print("❌ Error processing response type ${response.type}: $e");
          print("❌ Response data: ${response.data}");
        }
      }
    } catch (e) {
      print("❌ Error processing unified search: $e");
      rethrow;
    }

    return UnifiedSearchResult(
      splits: splits,
      definitions: definitions,
      verses: verses,
      chunks: chunks,
    );
  }
}
