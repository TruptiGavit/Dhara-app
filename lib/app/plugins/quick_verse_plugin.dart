import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dharak_flutter/app/core/plugins/dhara_plugin.dart';
import 'package:dharak_flutter/app/core/plugins/plugin_types.dart';
import 'package:dharak_flutter/app/ui/pages/verses/controller.dart';
import 'package:dharak_flutter/app/ui/pages/verses/cubit_states.dart';
import 'package:dharak_flutter/app/ui/pages/verses/page.dart';
import 'package:dharak_flutter/app/ui/pages/verses/args.dart';

/// QuickVerse plugin implementation
/// Wraps the existing VersesController with streaming support and language selection
class QuickVersePlugin implements DharaPlugin {
  final VersesController _controller;

  QuickVersePlugin(this._controller);

  @override
  PluginType get type => PluginType.quickVerse;

  @override
  String get displayName => 'QuickVerse';

  @override
  Color get themeColor => const Color(0xFF189565); // Your exact current green color

  @override
  IconData get icon => Icons.keyboard_command_key; // Your exact current icon

  @override
  PluginCapabilities get capabilities => const PluginCapabilities(
        supportsStreaming: true, // QuickVerse supports streaming
        supportsLanguageSelection: true, // QuickVerse supports language selection
        supportsBookmarks: true,
        supportsCitation: true,
        supportsSharing: true,
      );

  @override
  String get searchHintText => "Type partial verse to search..."; // Your exact current hint

  @override
  String get welcomeTitle => "Welcome to \nQuickVerse"; // Your exact current title

  @override
  String get welcomeDescription =>
      "Do you have a shloka, mantra, verse or a kriti humming in your mind? Search for it here. Just enter the parts you remember to get started!"; // Your exact current description

  @override
  bool get hasResults {
    final state = _controller.state;
    return state.verseList.isNotEmpty;
  }

  @override
  bool get isLoading => _controller.state.isLoading == true;

  @override
  String? get currentQuery => _controller.state.searchQuery;

  @override
  Future<void> performSearch(String query, {Map<String, dynamic>? options}) async {
    // Use your exact existing search logic with streaming support
    _controller.mSearchController.text = query;
    _controller.onFormSearchTextChanged(query);
    await _controller.onSearchDirectQuery(query);
  }

  @override
  Widget buildStandalonePage({bool hideSearchBar = false, bool hideWelcomeMessage = false}) {
    // Return your exact existing page
    return VersesPage(
      mRequestArgs: VersesArgsRequest(
        default1: hideSearchBar ? "embedded_search" : "standalone",
        hideSearchBar: hideSearchBar,
        hideWelcomeMessage: hideWelcomeMessage,
      ),
    );
  }

  @override
  Widget buildEmbeddedContent() {
    // Return your existing page in embedded mode
    return VersesPage(
      mRequestArgs: VersesArgsRequest(
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
              color: Color(0xFF189565),
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
        
        // Language selection bar - unique to QuickVerse
        _buildLanguageSelectionBar(),
        
        const SizedBox(height: 24.0),
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
    
    return state.verseList.map((verse) {
      return DharaResult(
        id: verse.versePk.toString(),
        source: PluginType.quickVerse,
        title: verse.verseRef,
        content: verse.verseText,
        subtitle: verse.verseLetText,
        originalData: verse, // Keep original for your existing UI
        metadata: {
          'sourceTitle': verse.sourceTitle,
          'sourceName': verse.sourceName,
          'isStarred': verse.isStarred,
          'versePk': verse.versePk,
          'wordHyplinks': verse.wordHyplinks,
          'similarity': verse.similarity,
        },
      );
    }).toList();
  }

  /// Build language selection bar - your exact existing logic
  Widget _buildLanguageSelectionBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: themeColor.withAlpha(0x20),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: themeColor.withAlpha(0x1A),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Left side: Transcription credit
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate,
                  size: 12,
                  color: themeColor,
                ),
                const SizedBox(width: 4),
                const Flexible(
                  child: Text(
                    "Transcription by Aksharamukha",
                    style: TextStyle(
                      color: Color(0xFF189565),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Right side: Language selector
          _buildCompactLanguageSelector(),
        ],
      ),
    );
  }

  /// Compact language selector - your exact existing component
  Widget _buildCompactLanguageSelector() {
    return BlocBuilder<VersesController, VersesCubitState>(
      bloc: _controller,
      buildWhen: (previous, current) =>
          current.verseLanguagePref != previous.verseLanguagePref,
      builder: (context, state) {
        final currentLanguage = state.verseLanguagePref?.output ?? 'devanagari';
        
        return PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
              color: themeColor,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getLanguageLabel(currentLanguage),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 12,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          onSelected: (String value) async {
            // Your existing language change logic would go here
            // This would typically call your dashboard controller
            print("Language changed to: $value");
          },
          itemBuilder: (context) => _getSupportedLanguages().entries.map<PopupMenuItem<String>>((entry) {
            return PopupMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          offset: const Offset(0, 25),
        );
      },
    );
  }

  /// Get language label - your existing logic
  String _getLanguageLabel(String language) {
    final labels = {
      'devanagari': 'देवनागरी',
      'english': 'English',
      'kannada': 'ಕನ್ನಡ',
      'telugu': 'తెలుగు',
      'tamil': 'தமிழ்',
      'bengali': 'বাংলা',
      'gujarati': 'ગુજરાતી',
      'malayalam': 'മലയാളം',
      'gurmukhi': 'ਗੁਰਮੁਖੀ',
    };
    return labels[language] ?? language;
  }

  /// Get supported languages - your existing logic
  Map<String, String> _getSupportedLanguages() {
    return {
      'devanagari': 'देवनागरी',
      'english': 'English',
      'kannada': 'ಕನ್ನಡ',
      'telugu': 'తెలుగు',
      'tamil': 'தமிழ்',
      'bengali': 'বাংলা',
      'gujarati': 'ગુજરાતી',
      'malayalam': 'മലയാളം',
      'gurmukhi': 'ਗੁਰਮੁਖੀ',
    };
  }
}
