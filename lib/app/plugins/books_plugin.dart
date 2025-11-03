import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dharak_flutter/app/core/plugins/dhara_plugin.dart';
import 'package:dharak_flutter/app/core/plugins/plugin_types.dart';
import 'package:dharak_flutter/app/ui/pages/books/controller.dart';
import 'package:dharak_flutter/app/ui/pages/books/cubit_states.dart';
import 'package:dharak_flutter/app/ui/pages/books/page.dart';
import 'package:dharak_flutter/app/ui/pages/books/args.dart';

/// Books plugin implementation
/// Wraps the existing BooksController without changing its logic
class BooksPlugin implements DharaPlugin {
  final BooksController _controller;

  BooksPlugin(this._controller);

  @override
  PluginType get type => PluginType.books;

  @override
  String get displayName => 'Books';

  @override
  Color get themeColor => Colors.blue; // Your exact current color

  @override
  IconData get icon => Icons.menu_book; // Your exact current icon

  @override
  PluginCapabilities get capabilities => const PluginCapabilities(
        supportsStreaming: false,
        supportsLanguageSelection: false,
        supportsBookmarks: true,
        supportsCitation: true,
        supportsSharing: true,
      );

  @override
  String get searchHintText => "Ask a question..."; // Your exact current hint

  @override
  String get welcomeTitle => "Welcome to \nBooks"; // Your exact current title

  @override
  String get welcomeDescription =>
      "Search and explore ancient texts and scriptures from various traditions and sources."; // Your exact current description

  @override
  bool get hasResults {
    final state = _controller.state;
    return state.bookChunks.isNotEmpty;
  }

  @override
  bool get isLoading => _controller.state.isLoading == true;

  @override
  String? get currentQuery => _controller.state.searchQuery;

  @override
  Future<void> performSearch(String query, {Map<String, dynamic>? options}) async {
    // Use your exact existing search logic
    _controller.mSearchController.text = query;
    _controller.onFormSearchTextChanged(query);
    await _controller.onSearchDirectQuery(query);
  }

  @override
  Widget buildStandalonePage({bool hideSearchBar = false, bool hideWelcomeMessage = false}) {
    // Return your exact existing page
    return BooksPage(
      mRequestArgs: BooksArgsRequest(
        default1: hideSearchBar ? "embedded_search" : "standalone",
        hideSearchBar: hideSearchBar,
        hideWelcomeMessage: hideWelcomeMessage,
      ),
    );
  }

  @override
  Widget buildEmbeddedContent() {
    // Return your existing page in embedded mode
    return BooksPage(
      mRequestArgs: BooksArgsRequest(
        default1: "embedded_search",
        hideSearchBar: true,
        hideWelcomeMessage: true,
      ),
    );
  }

  @override
  Widget buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32.0),
        
        // Welcome title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            welcomeTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        
        const SizedBox(height: 24.0),
        
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
        
        const SizedBox(height: 40.0),
        
        // Module icon
        Icon(
          icon,
          size: 48.0,
          color: themeColor.withOpacity(0.6),
        ),
        
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
          CircularProgressIndicator(
            color: themeColor,
          ),
          const SizedBox(height: 16.0),
          Text(
            'Searching in $displayName...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void clearResults() {
    // Clear the search in your existing controller
    _controller.mSearchController.clear();
    _controller.onFormSearchTextChanged('');
  }

  @override
  List<DharaResult> getStandardizedResults() {
    final state = _controller.state;
    
    return state.bookChunks.map((chunk) {
      return DharaResult(
        id: '${chunk.chunkRefId}',
        source: PluginType.books,
        title: chunk.reference,
        content: chunk.text,
        subtitle: 'Score: ${(chunk.score * 100).toInt()}%',
        originalData: chunk, // Keep original for your existing UI
        metadata: {
          'score': chunk.score,
          'reference': chunk.reference,
          'chunkRefId': chunk.chunkRefId,
        },
      );
    }).toList();
  }
}


