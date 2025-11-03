import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dharak_flutter/app/core/plugins/dhara_plugin.dart';
import 'package:dharak_flutter/app/core/plugins/plugin_types.dart';
import 'package:dharak_flutter/app/ui/pages/unified/controller.dart';
import 'package:dharak_flutter/app/ui/pages/unified/cubit_states.dart';
import 'package:dharak_flutter/app/ui/pages/unified/page.dart';

/// Unified Search plugin implementation
/// Wraps the existing UnifiedSearchController for cross-module search
class UnifiedPlugin implements DharaPlugin {
  final UnifiedSearchController _controller;

  UnifiedPlugin(this._controller);

  @override
  PluginType get type => PluginType.unified;

  @override
  String get displayName => 'Unified';

  @override
  Color get themeColor => Colors.purple; // Your exact current color

  @override
  IconData get icon => Icons.chat_bubble_outline; // Your exact current icon

  @override
  PluginCapabilities get capabilities => const PluginCapabilities(
        supportsStreaming: false,
        supportsLanguageSelection: false,
        supportsBookmarks: true,
        supportsCitation: true,
        supportsSharing: true,
      );

  @override
  String get searchHintText => "Search across all modules simultaneously...";

  @override
  String get welcomeTitle => "Welcome to \nUnified Search";

  @override
  String get welcomeDescription =>
      "Search across all modules simultaneously. Get definitions, verses, book content, and AI insights in one unified view.";

  @override
  bool get hasResults {
    final state = _controller.state;
    if (state is UnifiedSearchSuccess) {
      return state.result.hasResults;
    }
    return false;
  }

  @override
  bool get isLoading {
    final state = _controller.state;
    return state is UnifiedSearchLoading;
  }

  @override
  String? get currentQuery {
    final state = _controller.state;
    if (state is UnifiedSearchSuccess) {
      return state.query;
    } else if (state is UnifiedSearchLoading) {
      return state.query;
    } else if (state is UnifiedSearchEmpty) {
      return state.query;
    } else if (state is UnifiedSearchError) {
      return state.query;
    }
    return null;
  }

  @override
  Future<void> performSearch(String query, {Map<String, dynamic>? options}) async {
    // Use streaming search for instant results
    await _controller.searchStreaming(query);
  }

  @override
  Widget buildStandalonePage({bool hideSearchBar = false, bool hideWelcomeMessage = false}) {
    // Return your exact existing page
    return UnifiedSearchPage(
      hideSearchBar: hideSearchBar,
      hideWelcomeMessage: hideWelcomeMessage,
    );
  }

  @override
  Widget buildEmbeddedContent() {
    // Return your existing page in embedded mode
    return UnifiedSearchPage(
      hideSearchBar: true,
      hideWelcomeMessage: true,
    );
  }

  @override
  Widget buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32.0),
        
        // Unified search icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeColor.withOpacity(0.1),
                Colors.indigo.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: themeColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            size: 36,
            color: themeColor,
          ),
        ),
        
        const SizedBox(height: 24.0),
        
        // Welcome title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            welcomeTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
        ),
        
        const SizedBox(height: 16.0),
        
        // Welcome description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            welcomeDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
        
        const SizedBox(height: 32.0),
        
        // Feature highlights
        _buildFeatureHighlights(),
        
        const SizedBox(height: 32.0),
      ],
    );
  }

  @override
  Widget buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            'Searching across all modules...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeColor,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Processing definitions, verses, and books',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void clearResults() {
    // Clear unified search results
    _controller.clear();
  }

  @override
  List<DharaResult> getStandardizedResults() {
    final state = _controller.state;
    
    if (state is! UnifiedSearchSuccess) return [];
    
    final result = state.result;
    final allResults = <DharaResult>[];
    
    // Convert word definitions from unified result
    for (final defResponse in result.definitions) {
      if (defResponse.foundMatch) {
        for (final definition in defResponse.definitions.details.definitions ?? []) {
          allResults.add(DharaResult(
            id: '${defResponse.definitions.details.word}_${definition.dictRefId}',
            source: PluginType.wordDefine,
            title: defResponse.definitions.details.word ?? 'Unknown Word',
            content: definition.text,
            subtitle: definition.shortText,
            originalData: definition,
            metadata: {
              'type': 'definition',
              'language': definition.language,
              'source': definition.source,
            },
          ));
        }
      }
    }
    
    // Convert verses
    if (result.verses != null) {
      for (final verse in result.verses!.verses.verses) {
        allResults.add(DharaResult(
          id: 'verse_${verse.versePk}',
          source: PluginType.quickVerse,
          title: verse.verseRef,
          content: verse.verseText,
          subtitle: verse.verseLetText,
          originalData: verse,
          metadata: {
            'type': 'verse',
            'versePk': verse.versePk,
            'isStarred': verse.isStarred,
          },
        ));
      }
    }
    
    // Convert book chunks
    if (result.chunks != null) {
      for (final chunk in result.chunks!.chunks.data) {
        allResults.add(DharaResult(
          id: 'book_${chunk.chunkRefId}',
          source: PluginType.books,
          title: chunk.reference,
          content: chunk.text,
          subtitle: 'Score: ${(chunk.score * 100).toInt()}%',
          originalData: chunk,
          metadata: {
            'type': 'book',
            'score': chunk.score,
            'chunkRefId': chunk.chunkRefId,
          },
        ));
      }
    }
    
    return allResults;
  }

  /// Build feature highlights for unified search
  Widget _buildFeatureHighlights() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          _buildFeatureItem(
            Icons.local_library_outlined,
            'Word Definitions',
            'Sanskrit meanings & etymology',
            const Color(0xFFF9140C),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.keyboard_command_key,
            'Verses & Shlokas',
            'Sacred texts & poetry',
            const Color(0xFF189565),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.menu_book,
            'Ancient Books',
            'Scriptures & literature',
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.chat_bubble_outline_outlined,
            'AI Insights',
            'Personalized explanations',
            Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
