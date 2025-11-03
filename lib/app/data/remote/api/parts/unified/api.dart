import 'package:dharak_flutter/app/data/remote/api/parts/unified/api_point_simple.dart';
import 'package:dharak_flutter/app/types/unified/unified_search_response.dart';

class UnifiedSearchApiRepo {
  final UnifiedSearchApiPointSimple _apiPoint = UnifiedSearchApiPointSimple();

  /// Perform unified search and return combined results
  Future<UnifiedSearchResult> search(String query) async {
    try {
      print("🔍 Starting unified search for: '$query'");
      final result = await _apiPoint.processUnifiedSearch(query);
      
      print("✅ Unified search completed:");
      print("   - Definitions: ${result.definitions.length}");
      print("   - Verses: ${result.verses?.verses.verses.length ?? 0}");
      print("   - Chunks: ${result.chunks?.chunks.data.length ?? 0}");
      
      return result;
    } catch (e) {
      print("❌ Unified search repository error: $e");
      rethrow;
    }
  }

  /// Get streaming results for real-time updates
  Stream<UnifiedSearchResponse> searchStream(String query) {
    return _apiPoint.unifiedSearch(query);
  }
}
