import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dharak_flutter/app/core/plugins/dhara_plugin.dart';
import 'package:dharak_flutter/app/core/plugins/plugin_types.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/controller.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/state.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/page.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/args.dart';

/// Prashna plugin implementation
/// Wraps the existing PrashnaController with AI chat streaming functionality
class PrashnaPlugin implements DharaPlugin {
  final PrashnaController _controller;

  PrashnaPlugin(this._controller);

  @override
  PluginType get type => PluginType.prashna;

  @override
  String get displayName => 'Prashna';

  @override
  Color get themeColor => Colors.indigo; // Your exact current color

  @override
  IconData get icon => Icons.chat_bubble_outline; // Chat icon for Prashna

  @override
  PluginCapabilities get capabilities => const PluginCapabilities(
        supportsStreaming: true, // Prashna supports streaming AI responses
        supportsLanguageSelection: false,
        supportsBookmarks: false, // Chat history instead of bookmarks
        supportsCitation: false, // AI responses don't have citations
        supportsSharing: true,
      );

  @override
  String get searchHintText => "Ask a question about Sanskrit, philosophy, or any topic...";

  @override
  String get welcomeTitle => "Welcome to \nPrashna";

  @override
  String get welcomeDescription =>
      "Ask me anything about Sanskrit, philosophy, spirituality, or any topic. I'm here to help with AI-powered answers and insights.";

  @override
  bool get hasResults {
    final state = _controller.state;
    return state.currentSession?.messages.isNotEmpty == true;
  }

  @override
  bool get isLoading => _controller.state.isLoading == true || _controller.state.isStreaming == true;

  @override
  String? get currentQuery => _controller.state.currentMessage;

  @override
  Future<void> performSearch(String query, {Map<String, dynamic>? options}) async {
    // For Prashna, "search" means sending a message
    _controller.messageController.text = query;
    _controller.onMessageChanged(query);
    await _controller.sendMessage();
  }

  @override
  Widget buildStandalonePage({bool hideSearchBar = false, bool hideWelcomeMessage = false}) {
    // Return your exact existing page
    return PrashnaPage(
      mRequestArgs: PrashnaArgsRequest(
        default1: hideSearchBar ? "embedded_search" : "standalone",
        initialMessage: null,
        sessionId: null,
      ),
    );
  }

  @override
  Widget buildEmbeddedContent() {
    // Return your existing page in embedded mode
    return PrashnaPage(
      mRequestArgs: PrashnaArgsRequest(
        default1: "embedded_search",
        initialMessage: null,
        sessionId: null,
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
        
        // AI Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeColor.withOpacity(0.1),
                Colors.purple.withOpacity(0.1),
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
        
        // Quick starter prompts
        _buildQuickPrompts(),
        
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
          // Animated thinking indicator
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: themeColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20.0),
          Icon(
            Icons.chat_bubble_outline,
            size: 32,
            color: themeColor.withOpacity(0.7),
          ),
          const SizedBox(height: 16.0),
          Text(
            'AI is thinking...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeColor,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Generating personalized insights',
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
    // For chat, clearing means starting a new session
    // For clearing chat results - implement based on your controller's method
    // _controller.clearSession(); // Replace with your actual method
  }

  @override
  List<DharaResult> getStandardizedResults() {
    final state = _controller.state;
    final session = state.currentSession;
    
    if (session == null) return [];
    
    return session.messages.map((message) {
      return DharaResult(
        id: message.id,
        source: PluginType.prashna,
        title: message.isUser ? 'You' : 'AI Assistant',
        content: message.content,
        subtitle: message.timestamp?.toString(),
        originalData: message, // Keep original for your existing UI
        metadata: {
          'isUser': message.isUser,
          'timestamp': message.timestamp?.toIso8601String(),
          'aiModel': state.selectedAiModel.displayName,
          'sessionId': session.id,
        },
      );
    }).toList();
  }

  /// Build quick prompt suggestions
  Widget _buildQuickPrompts() {
    final prompts = [
      "What is dharma?",
      "Explain karma",
      "Sanskrit wisdom",
      "Meditation guide",
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.0,
      runSpacing: 8.0,
      children: prompts.map((prompt) => _buildPromptChip(prompt)).toList(),
    );
  }

  Widget _buildPromptChip(String prompt) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => performSearch(prompt),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeColor.withOpacity(0.3),
              width: 1,
            ),
            color: themeColor.withOpacity(0.05),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 14,
                color: themeColor,
              ),
              const SizedBox(width: 4),
              Text(
                prompt,
                style: TextStyle(
                  fontSize: 12,
                  color: themeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
