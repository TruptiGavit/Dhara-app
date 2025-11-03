import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:dharak_flutter/app/types/prashna/ai_model.dart';
import 'package:dharak_flutter/app/types/prashna/chat_message.dart';
import 'package:dharak_flutter/app/domain/dictionary/repo.dart';
import 'package:dharak_flutter/app/domain/verse/repo.dart';
import 'package:dharak_flutter/app/ui/pages/words/controller.dart';
import 'package:dharak_flutter/app/ui/pages/verses/controller.dart';
// import 'package:dharak_flutter/app/ui/pages/books/controller.dart'; // Removed unused import
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/tools_sources_modal.dart';
import 'package:dharak_flutter/app/types/prashna/api_response_parser.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:markdown_widget/markdown_widget.dart';

class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final bool isStreaming;
  final String? currentTool;
  final bool isDeveloperMode;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback? onRetry;
  final AppThemeColors? themeColors;
  final AppThemeDisplay? appThemeDisplay;

  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.isStreaming,
    this.currentTool,
    this.isDeveloperMode = false,
    required this.onCopy,
    required this.onShare,
    this.onRetry,
    this.themeColors,
    this.appThemeDisplay,
  });

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();

  /// Get dynamic thinking message based on current tool
  static String getThinkingMessage(String? currentTool) {
    if (currentTool == null) {
      return 'AI is working...';
    }

    // Extract tool name and parameters
    String toolName = currentTool;
    String? queryParam;
    
    if (currentTool.contains(' with params:')) {
      toolName = currentTool.split(' with params:').first;
      
      // Try to extract query parameter for more specific messages
      try {
        final paramsString = currentTool.split(' with params:').last;
        if (paramsString.contains('words: [') && paramsString.contains(']')) {
          final wordsMatch = RegExp(r'words: \[([^\]]+)\]').firstMatch(paramsString);
          if (wordsMatch != null) {
            queryParam = wordsMatch.group(1)?.replaceAll('"', '').split(',').first.trim();
          }
        } else if (paramsString.contains('verse_part:')) {
          final verseMatch = RegExp(r'verse_part: ([^,}]+)').firstMatch(paramsString);
          if (verseMatch != null) {
            queryParam = verseMatch.group(1)?.replaceAll('"', '').trim();
          }
        } else if (paramsString.contains('dict_word:')) {
          final dictMatch = RegExp(r'dict_word: ([^,}]+)').firstMatch(paramsString);
          if (dictMatch != null) {
            queryParam = dictMatch.group(1)?.replaceAll('"', '').trim();
          }
        } else if (paramsString.contains('chunk_query:')) {
          final chunkMatch = RegExp(r'chunk_query: ([^,}]+)').firstMatch(paramsString);
          if (chunkMatch != null) {
            queryParam = chunkMatch.group(1)?.replaceAll('"', '').trim();
            if (queryParam!.length > 25) {
              queryParam = '${queryParam!.substring(0, 25)}...';
            }
          }
        }
      } catch (e) {
        // If parsing fails, use default messages
      }
    }
    
    switch (toolName.toLowerCase()) {
      case 'dict_lookup':
        return queryParam != null 
            ? 'Searching meaning of [$queryParam]'
            : 'Searching word meanings...';
      case 'verse_lookup':
        return queryParam != null 
            ? 'Looking up verse for [$queryParam]'
            : 'Looking up verses...';
      case 'chunk_search':
      case 'chunk_lookup':
        return queryParam != null 
            ? 'Searching books for [$queryParam]'
            : 'Searching texts...';
      case 'regex_word_search':
        return 'Finding patterns...';
      default:
        return 'Working...';
    }
  }
}

class _ChatMessageWidgetState extends State<ChatMessageWidget> {
  late ScrollController _sourcesScrollController;
  final Map<int, GlobalKey> _sourceKeys = {};

  @override
  void initState() {
    super.initState();
    _sourcesScrollController = ScrollController();
    _initializeSourceKeys();
  }

  @override
  void didUpdateWidget(ChatMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize keys if citations changed
    if (oldWidget.message.citations.length != widget.message.citations.length) {
      _initializeSourceKeys();
    }
  }

  /// Initialize GlobalKeys for source citations
  void _initializeSourceKeys() {
    _sourceKeys.clear();
    for (final citation in widget.message.citations) {
      // Use a unique key that combines message ID and citation ID to avoid duplicates
      final uniqueKey = citation.id;
      _sourceKeys[uniqueKey] = GlobalKey(debugLabel: 'source_${widget.message.id}_$uniqueKey');
    }
  }

  @override
  void dispose() {
    _sourcesScrollController.dispose();
    super.dispose();
  }

  // New helper methods for Perplexity-style UI

  /// Check if we should show action buttons for tools/sources/logs
  bool _shouldShowActionButtons() {
    return message.isCompleted && (_hasToolCalls() || _hasSources() || _hasLogs());
  }

  /// Check if message has tool calls to display
  bool _hasToolCalls() {
    return message.toolCalls.where((tc) => tc.name.toLowerCase() != 'heritage_lookup').isNotEmpty;
  }

  /// Check if message has sources to display
  bool _hasSources() {
    return message.citations.isNotEmpty;
  }

  /// Check if message has execution logs to display
  bool _hasLogs() {
    // Check if execution log data is available
    if (message.executionLog != null) {
      return message.executionLog!.events.isNotEmpty;
    }
    
    // Fall back to parsing from rawContent or content
    final content = message.rawContent ?? message.content ?? '';
    if (content.isNotEmpty) {
      final executionLog = PrashnaApiResponseParser.parseExecutionLog(content);
      if (executionLog != null) {
        return executionLog.events.isNotEmpty;
      }
    }
    
    // NO FALLBACK: Only show logs tab if real execution data exists
    return false;
  }

  /// Get count of relevant tool calls (excluding heritage_lookup)
  int _getToolCallsCount() {
    final filteredTools = message.toolCalls.where((tc) => !tc.name.toLowerCase().contains('heritage_lookup')).toList();
    
    // Count only the tools that have display names (similar to modal filtering)
    int displayableCount = 0;
    for (final toolCall in filteredTools) {
      final toolName = _getToolDisplayName(toolCall.name);
      // Only count tools that can be displayed (have proper names)
      if (toolName != null && !toolName.isEmpty) {
        displayableCount++;
      }
    }
    
    // Tool processing completed
    
    return displayableCount;
  }

  /// Get the tab index for logs based on what other tabs are available
  int _getLogsTabIndex() {
    int index = 0;
    if (_hasToolCalls()) index++;
    if (_hasSources()) index++;
    return index;
  }

  /// Build action button for tools/sources/logs
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: (widget.themeColors?.primary ?? Colors.indigo.shade500).withOpacity(0.1),
        highlightColor: (widget.themeColors?.primary ?? Colors.indigo.shade500).withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            // Minimal background with subtle border
            color: widget.themeColors?.isDark == true 
                ? Colors.grey.shade800.withOpacity(0.3)
                : Colors.grey.shade100.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.themeColors?.isDark == true 
                  ? Colors.grey.shade600.withOpacity(0.4)
                  : Colors.grey.shade300.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minimal icon with subtle primary color
              Icon(
                icon,
                size: 12,
                color: widget.themeColors?.isDark == true 
                    ? Colors.grey.shade300
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: widget.themeColors?.isDark == true 
                      ? Colors.grey.shade300
                      : Colors.grey.shade700,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                // Attention-grabbing count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    // Use primary color for count to grab attention
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.themeColors?.primary ?? Colors.indigo.shade500,
                        (widget.themeColors?.primary ?? Colors.indigo.shade500).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.themeColors?.primary ?? Colors.indigo.shade500).withOpacity(0.3),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: widget.themeColors?.isDark == true 
                          ? Colors.grey.shade900 
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build answer content without tabs (direct display)
  Widget _buildAnswerContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Answer Content (markdown with clickable source citations)
            if (message.content.isEmpty && isStreaming)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.themeColors?.primary ?? Colors.indigo.shade500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ChatMessageWidget.getThinkingMessage(widget.currentTool),
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.themeColors?.onSurfaceMedium ?? Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildMarkdownContent(),
            
            // Error Message
            if (message.hasError && message.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade500,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message.errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (widget.onRetry != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onRetry,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build compact logs icon button to save space
  Widget _buildLogsIconButton({
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        splashColor: widget.themeColors?.isDark == true 
            ? Colors.indigo.shade800.withOpacity(0.3)
            : Colors.indigo.shade100,
        highlightColor: widget.themeColors?.isDark == true 
            ? Colors.indigo.shade900.withOpacity(0.2)
            : Colors.indigo.shade50,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: widget.themeColors?.isDark == true 
                ? Colors.indigo.shade800.withOpacity(0.3)
                : Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.themeColors?.isDark == true 
                  ? Colors.indigo.shade600.withOpacity(0.4)
                  : Colors.indigo.shade200,
              width: 1,
            ),
          ),
          child: Icon(
            Icons.timeline,
            size: 14,
            color: widget.themeColors?.isDark == true 
                ? Colors.indigo.shade300
                : Colors.indigo.shade700,
          ),
        ),
      ),
    );
  }

  /// Show modal with tools and sources (Perplexity-style)
  void _showToolsAndSourcesModal({int initialTab = 0, int? scrollToSource}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5), // Darker backdrop for better distinction
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => ToolsAndSourcesModal(
        message: message,
        initialTab: initialTab,
        scrollToSource: scrollToSource,
        themeColors: widget.themeColors,
        sourceKeys: _sourceKeys,
        sourcesScrollController: _sourcesScrollController,
      ),
    );
  }

  ChatMessage get message => widget.message;
  bool get isStreaming => widget.isStreaming;

  /// Handle source citation click - navigate to Sources tab and scroll to specific source
  void _onSourceCitationClick(int sourceNumber) {
    // Open the modal with Sources tab selected and scroll to specific source
    _showToolsAndSourcesModal(initialTab: 1, scrollToSource: sourceNumber);
  }

  /// Scroll to a specific source by its number and highlight it (within Sources tab only)
  void _scrollToSource(int sourceNumber) {
    if (!mounted || !_sourcesScrollController.hasClients) return;
    
    // Find the index of the source in the sorted list
    final sortedSources = List<SourceCitation>.from(widget.message.citations)
      ..sort((a, b) => a.id.compareTo(b.id));
    
    final targetIndex = sortedSources.indexWhere((source) => source.id == sourceNumber);
    if (targetIndex == -1) return;
    
    // Calculate scroll position (approximate item height: 80px + 8px margin)
    const double itemHeight = 88.0;
    final double targetOffset = targetIndex * itemHeight;
    
    // Animate scroll within the Sources tab ListView only
    _sourcesScrollController.animateTo(
      targetOffset.clamp(0.0, _sourcesScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    ).then((_) {
      // Trigger highlight animation after scrolling is complete
      final key = _sourceKeys[sourceNumber];
      final context = key?.currentContext;
      if (context != null) {
        final sourceCardState = context.findAncestorStateOfType<_ExpandableSimpleSourceCardState>();
        sourceCardState?.highlightSource();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _buildAvatar(),
              
              const SizedBox(width: 12),
              
              // Message Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message Header
                    _buildMessageHeader(),
                    
                    const SizedBox(height: 8),
                    
                    // For user messages, show simple content
                    if (message.isUser)
                      _buildMessageContent(context),
                    
                    // For AI messages, show tabs with Answer, Tools, Sources, Tasks
                    if (!message.isUser)
                      _buildAiResponseTabs(),
                    
                    // Actions (only for AI messages, not user messages)
                    if (!message.isUser && (message.isCompleted || message.hasError))
                      _buildMessageActions(),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Full-width separator line after completed AI messages
        if (!message.isUser && message.isCompleted)
          Container(
            margin: const EdgeInsets.only(top: 16, bottom: 8),
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  (widget.themeColors?.primary ?? Colors.indigo.shade300).withOpacity(0.8),
                  (widget.themeColors?.primary ?? Colors.indigo.shade300).withOpacity(0.8),
                  (widget.themeColors?.primary ?? Colors.indigo.shade300).withOpacity(0.8),
                  (widget.themeColors?.primary ?? Colors.indigo.shade300).withOpacity(0.8),
                  (widget.themeColors?.primary ?? Colors.indigo.shade300).withOpacity(0.8),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: message.isUser 
            ? widget.themeColors?.primaryLight ?? Colors.indigo.shade100 
            : widget.themeColors?.primaryLight ?? Colors.indigo.shade100,
        shape: BoxShape.circle,
      ),
      child: message.isUser 
          ? Icon(
              Icons.person,
              size: 18,
              color: widget.themeColors?.primaryHigh ?? Colors.indigo.shade600,
            )
          : ClipOval(
              child: Image.asset(
                'assets/img/dhara_logo.png', // Use Prashna/Dhara logo for AI assistant
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if image not found
                  return Icon(
                    _getAiIcon(message.aiModel),
                    size: 18,
                    color: widget.themeColors?.primaryHigh ?? Colors.indigo.shade600,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildMessageHeader() {
    return Column(
      children: [
        Row(
          children: [
            // Assistant name - flexible to allow text wrapping
            Expanded(
              child: Row(
                children: [
                  Text(
                    message.role.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.themeColors?.isDark == true 
                          ? Colors.grey.shade300 
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            // Tools and Sources buttons - fixed width to prevent overflow
            if (!message.isUser && _shouldShowActionButtons()) ...[
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tools button
                  if (_hasToolCalls())
                    _buildActionButton(
                      icon: Icons.build_outlined,
                      label: 'Tools',
                      count: _getToolCallsCount(),
                      onTap: () => _showToolsAndSourcesModal(initialTab: 0),
                    ),
                  
                  if (_hasToolCalls() && _hasSources())
                    const SizedBox(width: 4),
                  
                  // Sources button  
                  if (_hasSources())
                    _buildActionButton(
                      icon: Icons.source_outlined,
                      label: 'Sources',
                      count: message.citations.length,
                      onTap: () => _showToolsAndSourcesModal(initialTab: _hasToolCalls() ? 1 : 0),
                    ),
                  
                  if ((_hasToolCalls() || _hasSources()) && _hasLogs())
                    const SizedBox(width: 4),
                  
                  // Logs button (icon only)
                  if (_hasLogs())
                    _buildLogsIconButton(
                      onTap: () => _showToolsAndSourcesModal(initialTab: _getLogsTabIndex()),
                    ),
                ],
              ),
            ],
          ],
        ),
        
        // Subtle separator line for AI messages with tools/sources
        if (!message.isUser && _shouldShowActionButtons()) ...[
          const SizedBox(height: 8),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  (widget.themeColors?.primary ?? Colors.indigo.shade300).withOpacity(0.3),
                  (widget.themeColors?.primary ?? Colors.indigo.shade300).withOpacity(0.6),
                  (widget.themeColors?.primary ?? Colors.indigo.shade300).withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator() {
    switch (message.status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
          ),
        );
      
      case MessageStatus.streaming:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isStreaming)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade400),
                ),
              ),
            const SizedBox(width: 4),
            _buildTypingIndicator(),
          ],
        );
      
      case MessageStatus.error:
        return Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.red.shade500,
        );
      
      case MessageStatus.cancelled:
        return Icon(
          Icons.cancel_outlined,
          size: 14,
          color: widget.themeColors?.errorColor ?? Colors.red.shade500,
        );
      
      case MessageStatus.completed:
        return Icon(
          Icons.check_circle_outline,
          size: 14,
          color: widget.themeColors?.primaryHigh ?? Colors.indigo.shade500,
        );
    }
  }

  Widget _buildTypingIndicator() {
    if (!isStreaming) return const SizedBox.shrink();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '●',
          style: TextStyle(
            fontSize: 8,
            color: Colors.indigo.shade400,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '●',
          style: TextStyle(
            fontSize: 8,
            color: Colors.indigo.shade300,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '●',
          style: TextStyle(
            fontSize: 8,
            color: Colors.indigo.shade200,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    // For user messages, use minimal Perplexity-style design
    if (message.isUser) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          // Very subtle background - barely visible like Perplexity
          color: widget.themeColors?.isDark == true 
              ? Colors.grey.shade800.withOpacity(0.7)
              : Colors.grey.shade300.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: widget.themeColors?.isDark == true 
                ? Colors.grey.shade200
                : Colors.grey.shade800,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    // For AI messages, keep the existing design
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Content with source citation processing
          RichText(
            text: TextSpan(
              children: message.content.isEmpty && isStreaming 
                ? [TextSpan(
                    text: 'Thinking...',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  )]
                : _processSourceCitations(message.content),
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade800,
                fontStyle: FontStyle.normal,
              ),
            ),
          ),
          
          // Error Message
          if (message.hasError && message.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolCalls() {
    if (message.toolCalls.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tool Calls:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          ...message.toolCalls.map((toolCall) => _buildToolCallItem(toolCall)),
        ],
      ),
    );
  }

  Widget _buildToolCallItem(ToolCall toolCall) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.themeColors?.primaryLight ?? Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            toolCall.isCompleted ? Icons.check_circle : Icons.hourglass_empty,
            size: 12,
            color: widget.themeColors?.primaryHigh ?? Colors.indigo.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            toolCall.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: widget.themeColors?.primaryHigh ?? Colors.indigo.shade700,
            ),
          ),
          if (toolCall.isCompleted) ...[
            const SizedBox(width: 4),
            Text(
              '(${toolCall.duration.inMilliseconds}ms)',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCitations() {
    if (message.citations.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: message.citations.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final citation = entry.value;
          return _buildSourceCitationChip(index, citation);
        }).toList(),
      ),
    );
  }

  Widget _buildSourceCitationChip(int index, SourceCitation citation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: widget.themeColors?.isDark == true 
            ? Colors.indigo.shade800.withOpacity(0.3)
            : Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.themeColors?.isDark == true 
              ? Colors.indigo.shade600.withOpacity(0.4)
              : Colors.indigo.shade200,
          width: 1,
        ),
      ),
      child: Text(
        '[$index]',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: widget.themeColors?.isDark == true 
              ? Colors.indigo.shade300
              : Colors.indigo.shade700,
        ),
      ),
    );
  }

  Widget _buildMessageActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          // Copy Button
          _buildSimpleActionButton(
            icon: Icons.copy,
            onTap: widget.onCopy,  // Let the callback handle copying (so it can clean the text)
          ),
          
          const SizedBox(width: 8),
          
          // Share Button
          _buildSimpleActionButton(
            icon: Icons.share,
            onTap: widget.onShare,
          ),
          
          // Retry Button (for errors)
          if (message.hasError && widget.onRetry != null) ...[
            const SizedBox(width: 8),
            _buildSimpleActionButton(
              icon: Icons.refresh,
              onTap: widget.onRetry!,
              color: widget.themeColors?.primaryHigh ?? Colors.indigo.shade600,
            ),
          ],
        ],
      ),
    );
  }

  /// Build simple action button for copy/share/retry actions
  Widget _buildSimpleActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: widget.themeColors?.isDark == true 
              ? Colors.indigo.shade800.withOpacity(0.3)
              : (widget.themeColors?.primaryLight ?? Colors.indigo.shade100),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: widget.themeColors?.isDark == true 
              ? (color ?? Colors.indigo.shade300)
              : (color ?? (widget.themeColors?.primaryHigh ?? Colors.indigo.shade600)),
        ),
      ),
    );
  }



  /// Process content to replace ```source blocks with numbered citations
  List<TextSpan> _processSourceCitations(String content) {
    if (content.isEmpty) return [TextSpan(text: content)];
    
    // Use webapp-style source processing
    String processedContent = content;
    
    // Pattern to match ```source blocks exactly like webapp
    final RegExp sourcePattern = RegExp(
      r'```source\s*\n?(.*?)\n?```',
      multiLine: true,
      dotAll: true,
    );
    
    // Global source mapping for consistent numbering
    final Map<String, int> sourceMapping = {};
    int citationCounter = 1;
    
    processedContent = processedContent.replaceAllMapped(sourcePattern, (match) {
      final sourceContent = match.group(1)?.trim() ?? '';
      
      try {
        // Parse the source data like webapp
        final Map<String, dynamic> sourceData = _parseWebappSourceData(sourceContent);
        
        // Collect all source IDs from this block
        final List<Map<String, dynamic>> sourcesInBlock = [];
        
        // Process each source type (verse, defn, chunk)
        for (final sourceType in ['verse', 'defn', 'chunk']) {
          if (sourceData[sourceType] != null && sourceData[sourceType] is List) {
            for (final id in sourceData[sourceType]) {
              sourcesInBlock.add({'type': sourceType, 'id': id});
            }
          }
        }
        
        // Create inline references for this source block
        final List<String> inlineRefs = [];
        for (final source in sourcesInBlock) {
          final key = '${source['type']}_${source['id']}';
          if (!sourceMapping.containsKey(key)) {
            sourceMapping[key] = citationCounter++;
          }
          final sourceNumber = sourceMapping[key]!;
          inlineRefs.add('[$sourceNumber]');
        }
        
        // Return inline references (collapsible if many like webapp)
        if (inlineRefs.length > 3) {
          final visibleRefs = inlineRefs.take(3).join(' ');
          final hiddenCount = inlineRefs.length - 3;
          return ' $visibleRefs ... [+$hiddenCount]';
        } else {
          return ' ${inlineRefs.join(' ')}';
        }
        
      } catch (e) {
        // Fallback: create a simple numbered citation
        final key = 'source_$sourceContent';
        if (!sourceMapping.containsKey(key)) {
          sourceMapping[key] = citationCounter++;
        }
        return '[${sourceMapping[key]}]';
      }
    });
    
    // Convert the processed content to clickable TextSpans
    return _convertToClickableSpans(processedContent, sourceMapping);
  }

  /// Add a clickable citation to the spans list
  void _addClickableCitation(List<TextSpan> spans, int sourceNumber) {
    spans.add(TextSpan(
      text: '[$sourceNumber]',
      style: TextStyle(
        color: widget.themeColors?.isDark == true ? Color(0xFF9FA8DA) : Colors.indigo.shade600,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.underline,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () => _onSourceCitationClick(sourceNumber),
    ));
  }
  
  /// Convert processed content with citations to clickable TextSpans
  List<TextSpan> _convertToClickableSpans(String content, Map<String, int> sourceMapping) {
    final List<TextSpan> spans = [];
    
    // Pattern to match citation numbers like [1], [2], [+3], etc.
    final RegExp citationPattern = RegExp(r'\[(\d+|\+\d+)\]');
    int lastMatchEnd = 0;
    
    for (final match in citationPattern.allMatches(content)) {
      // Add text before this citation
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: content.substring(lastMatchEnd, match.start),
        ));
      }
      
      final citationText = match.group(0)!; // Full match like "[1]"
      final numberText = match.group(1)!; // Just the number like "1"
      
      // Handle "+N" style citations (non-clickable)
      if (numberText.startsWith('+')) {
        spans.add(TextSpan(
          text: citationText,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ));
      } else {
        // Regular numbered citation (clickable)
        final sourceNumber = int.tryParse(numberText);
        if (sourceNumber != null) {
          spans.add(TextSpan(
            text: citationText,
            style: TextStyle(
              color: Colors.indigo.shade600,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: Colors.indigo.shade600,
              fontSize: 12,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _onSourceCitationClick(sourceNumber);
              },
          ));
        } else {
          // Fallback for unparseable numbers
          spans.add(TextSpan(text: citationText));
        }
      }
      
      lastMatchEnd = match.end;
    }
    
    // Add remaining text after last citation
    if (lastMatchEnd < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastMatchEnd),
      ));
    }
    
    return spans.isNotEmpty ? spans : [TextSpan(text: content)];
  }
  
  /// Parse source data like webapp (handles Python dict format)
  Map<String, dynamic> _parseWebappSourceData(String sourceContent) {
    try {
      // Convert Python dict format to JSON
      String jsonStr = sourceContent
          .replaceAll("'", '"')  // Single quotes to double quotes
          .replaceAll('True', 'true')
          .replaceAll('False', 'false')
          .replaceAll('None', 'null');
      
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      // Fallback: try to extract arrays manually
      return _extractWebappSourceArrays(sourceContent);
    }
  }
  
  /// Extract source arrays manually (simple fallback)
  Map<String, dynamic> _extractWebappSourceArrays(String content) {
    final Map<String, dynamic> result = {};
    
    // Simple string-based extraction as fallback
    if (content.contains('chunk')) {
      result['chunk'] = [1]; // Fallback: assign a simple ID
    }
    if (content.contains('defn')) {
      result['defn'] = [1]; // Fallback: assign a simple ID
    }
    if (content.contains('verse')) {
      result['verse'] = [1]; // Fallback: assign a simple ID
    }
    
    return result;
  }

  /// Build AI response tabs (Answer, Tools, Sources, Tasks)
  Widget _buildAiResponseTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show answer content directly (no tabs)
          _buildAnswerContent(),
          

        ],
      ),
    );
  }

  /// Build tabs for Tools, Sources, and Tasks (Perplexity-style) - DEPRECATED
  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              labelColor: widget.themeColors?.isDark == true ? Color(0xFF9FA8DA) : Colors.indigo.shade700,
              unselectedLabelColor: widget.themeColors?.isDark == true ? Color(0xFF606070) : Colors.grey.shade600,
              indicatorColor: widget.themeColors?.isDark == true ? Color(0xFF7986CB) : Colors.indigo.shade500,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.build, size: 14),
                      const SizedBox(width: 4),
                      Text('Tools'),
                      if (message.toolCalls.where((tc) => tc.name.toLowerCase() != 'heritage_lookup').isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${message.toolCalls.where((tc) => !tc.name.toLowerCase().contains('heritage_lookup')).length}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.indigo.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.source, size: 14),
                      const SizedBox(width: 4),
                      Text('Sources'),
                      if (message.citations.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: widget.themeColors?.primaryLight ?? Colors.indigo.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${message.citations.length}',
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.themeColors?.primaryHigh ?? Colors.indigo.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.task_alt, size: 14),
                      const SizedBox(width: 4),
                      Text('Tasks'),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              height: 200,
              child: TabBarView(
                children: [
                  _buildToolCallsTab(),
                  _buildSourcesTab(),
                  _buildTasksTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Answer tab with markdown-formatted content
  Widget _buildAnswerTab() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Answer Content (markdown with clickable source citations)
            if (message.content.isEmpty && isStreaming)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      ChatMessageWidget.getThinkingMessage(widget.currentTool),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildMarkdownContent(),
            
            // Error Message
            if (message.hasError && message.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade500,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message.errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build content with markdown rendering and clickable citations
  Widget _buildMarkdownContent() {
    return _buildMixedContent();
  }
  
  /// Build mixed content with markdown and custom clickable citations
  Widget _buildMixedContent() {
    // Process content to separate markdown from source citations
    final parts = _processContentToParts(message.content);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((part) {
        if (part['type'] == 'markdown') {
          // Render markdown content
          return MarkdownWidget(
            data: part['content'] as String,
            shrinkWrap: true,
            selectable: true,
            config: widget.themeColors?.isDark == true
                ? MarkdownConfig.darkConfig
                : MarkdownConfig(
              configs: [
                H1Config(
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.themeColors?.onSurface ?? Colors.black87,
                    height: 1.3,
                  ),
                ),
                H2Config(
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.themeColors?.onSurface ?? Colors.black87,
                    height: 1.3,
                  ),
                ),
                H3Config(
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.themeColors?.onSurface ?? Colors.black87,
                    height: 1.3,
                  ),
                ),
                PConfig(
                  textStyle: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: widget.themeColors?.onSurface ?? Colors.black87,
                  ),
                ),
                CodeConfig(
                  style: TextStyle(
                    color: widget.themeColors?.primaryHigh ?? Colors.red.shade700,
                    backgroundColor: widget.themeColors?.primaryLight ?? Colors.grey.shade100,
                    fontFamily: 'Courier',
                    fontSize: 13,
                  ),
                ),
                PreConfig(
                  padding: const EdgeInsets.all(16),
                  textStyle: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 13,
                    color: Colors.grey.shade800,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                const BlockquoteConfig(),
                TableConfig(
                  wrapper: (table) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: table,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (part['type'] == 'citations') {
          // Render clickable citations
          return _buildClickableCitations(part['citations'] as List<Map<String, dynamic>>);
        } else {
          // Fallback for unknown types
          return Text(part['content'] as String);
        }
      }).toList(),
    );
  }

  /// Process content to separate markdown and citations
  List<Map<String, dynamic>> _processContentToParts(String content) {
    if (content.isEmpty) return [{'type': 'markdown', 'content': content}];
    
    final List<Map<String, dynamic>> parts = [];
    final RegExp sourcePattern = RegExp(
      r'```source\s*\n?(.*?)\n?```',
      multiLine: true,
      dotAll: true,
    );
    
    // Global source mapping for consistent numbering
    final Map<String, int> sourceMapping = {};
    int citationCounter = 1;
    int lastMatchEnd = 0;
    
    for (final match in sourcePattern.allMatches(content)) {
      // Add markdown content before this source block
      if (match.start > lastMatchEnd) {
        final markdownContent = content.substring(lastMatchEnd, match.start);
        if (markdownContent.trim().isNotEmpty) {
          parts.add({'type': 'markdown', 'content': markdownContent});
        }
      }
      
      final sourceContent = match.group(1)?.trim() ?? '';
      
      try {
        // Parse the source data like webapp
        final Map<String, dynamic> sourceData = _parseWebappSourceData(sourceContent);
        
        // Collect all source IDs from this block
        final List<Map<String, dynamic>> sourcesInBlock = [];
        
        // Process each source type (verse, defn, chunk)
        for (final sourceType in ['verse', 'defn', 'chunk']) {
          if (sourceData[sourceType] != null && sourceData[sourceType] is List) {
            for (final id in sourceData[sourceType]) {
              sourcesInBlock.add({'type': sourceType, 'id': id});
            }
          }
        }
        
        // Create citation data for this source block
        final List<Map<String, dynamic>> citations = [];
        for (final source in sourcesInBlock) {
          final key = '${source['type']}_${source['id']}';
          if (!sourceMapping.containsKey(key)) {
            sourceMapping[key] = citationCounter++;
          }
          final sourceNumber = sourceMapping[key]!;
          citations.add({
            'number': sourceNumber,
            'type': source['type'],
            'id': source['id'],
          });
        }
        
        if (citations.isNotEmpty) {
          parts.add({'type': 'citations', 'citations': citations});
        }
        
      } catch (e) {
        // Fallback for unparseable source blocks
        parts.add({
          'type': 'citations', 
          'citations': [{'number': citationCounter++, 'type': 'unknown', 'id': 'unknown'}]
        });
      }
      
      lastMatchEnd = match.end;
    }
    
    // Add remaining markdown content
    if (lastMatchEnd < content.length) {
      final remainingContent = content.substring(lastMatchEnd);
      if (remainingContent.trim().isNotEmpty) {
        parts.add({'type': 'markdown', 'content': remainingContent});
      }
    }
    
    return parts.isNotEmpty ? parts : [{'type': 'markdown', 'content': content}];
  }
  
  /// Build clickable citations widget with expand/collapse functionality
  Widget _buildClickableCitations(List<Map<String, dynamic>> citations) {
    if (citations.isEmpty) return const SizedBox.shrink();
    
    return _ExpandableCitationWidget(citations: citations);
  }


  Widget _buildToolCallsTab() {
    final filteredToolCalls = message.toolCalls
        .where((toolCall) {
          final lowerName = toolCall.name.toLowerCase();
          return !lowerName.contains('heritage_lookup');
        })
        .toList();
        
    if (filteredToolCalls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No tools used',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This response was generated without using any external tools',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple header
          Text(
            'Search Query',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          // Show just the query parameters in a clean way (filter out heritage_lookup)
          ...filteredToolCalls.map((toolCall) => _buildSimpleToolDisplay(toolCall)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ToolCall toolCall, int stepNumber, bool isLast) {
    final iconData = _getToolIcon(toolCall.name);
    final color = _getToolColor(toolCall.name);
    final toolInfo = _getToolInfo(toolCall);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator with step number
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.shade100, color.shade200],
                ),
                border: Border.all(color: color, width: 2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: TextStyle(
                    color: color.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withOpacity(0.3), Colors.grey.shade300],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
              ),
          ],
        ),
        const SizedBox(width: 20),
        // Tool content card
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              // Remove shadow effects for clean Prashna design
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with tool info and status
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color, color.shade600],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(iconData, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              toolInfo['title']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              toolInfo['description']!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.shade50, color.shade100],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: color, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Completed',
                              style: TextStyle(
                                color: color.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Query parameters only (simplified)
                if (toolCall.parameters.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Query:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...toolCall.parameters.entries.map((entry) => 
                          _buildSimpleQueryDisplay(entry.key, entry.value.toString(), color)
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleQueryDisplay(String label, String value, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.label, color: color.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      color: color.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleToolDisplay(ToolCall toolCall) {
    // SAFETY CHECK: Never display heritage_lookup tools
    if (toolCall.name.toLowerCase().contains('heritage_lookup')) {
      return const SizedBox.shrink(); // Return empty widget
    }
    
    final toolColor = _getToolColor(toolCall.name);
    final toolIcon = _getToolIcon(toolCall.name);
    final toolName = _getToolDisplayName(toolCall.name);
    
    // Skip tools that don't have proper display names
    if (toolName == null) {
      return const SizedBox.shrink(); // Return empty widget
    }
    
    // Get main query parameter with better formatting
    String queryText = '';
    if (toolCall.parameters.isNotEmpty) {
      // Extract the main parameter based on tool type
      switch (toolCall.name.toLowerCase()) {
        case 'dict_lookup':
          if (toolCall.parameters.containsKey('dict_word')) {
            queryText = '[${toolCall.parameters['dict_word']}]';
          }
          break;
        case 'verse_lookup':
          if (toolCall.parameters.containsKey('verse_part')) {
            queryText = '[${toolCall.parameters['verse_part']}]';
          }
          break;
        case 'chunk_lookup':
        case 'chunk_search':
          if (toolCall.parameters.containsKey('chunk_query')) {
            final query = toolCall.parameters['chunk_query'].toString();
            // Truncate long queries for display
            final displayQuery = query.length > 30 ? '${query.substring(0, 30)}...' : query;
            queryText = '[${displayQuery}]';
          }
          break;
        default:
          // Fallback to first parameter
          final mainParam = toolCall.parameters.entries.first;
          queryText = '[${mainParam.value}]';
      }
    }
    
        return GestureDetector(
      onTap: () {
        _handleToolCardTap(toolCall);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.themeColors?.isDark == true 
              ? Colors.grey.shade800.withOpacity(0.3)
              : Colors.grey.shade100.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.themeColors?.isDark == true 
                ? toolColor.shade600.withOpacity(0.4)
                : toolColor.shade300, 
            width: 1,
          ),
          // Remove shadow effect for clean Prashna design
        ),
        child: Row(
        children: [
          // Tool icon with color (Perplexity style - small colored circle)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: toolColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              toolIcon,
              color: widget.themeColors?.isDark == true 
                  ? Colors.grey.shade900 
                  : Colors.white,
              size: 12,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Tool info (Perplexity style - clean text)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tool name
                Text(
                  toolName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.themeColors?.isDark == true 
                        ? Colors.grey.shade200 
                        : Colors.grey.shade800,
                  ),
                ),
                
                // Query text if available
                if (queryText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    queryText,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.themeColors?.isDark == true 
                          ? Colors.grey.shade400 
                          : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Map<String, String> _getToolInfo(ToolCall toolCall) {
    // Extract specific query parameter from tool parameters
    String queryParam = _extractQueryParameter(toolCall);
    
    switch (toolCall.name.toLowerCase()) {
      case 'heritage_lookup':
        // Don't show heritage_lookup directly - this should be broken down into individual tools
        return {
          'title': 'Heritage Search',
          'description': 'Searching through multiple heritage sources',
        };
      case 'dict_lookup':
      case 'get-word-definition':
        return {
          'title': 'WordDefine',
          'description': queryParam.isNotEmpty ? 'Looking up: $queryParam' : 'Finding word definitions',
        };
      case 'verse_lookup':
      case 'find-verse':
        return {
          'title': 'QuickVerse',
          'description': queryParam.isNotEmpty ? 'Searching: $queryParam' : 'Finding relevant verses',
        };
      case 'chunk_search':
      case 'chunk_lookup':
        return {
          'title': 'Chunk',
          'description': queryParam.isNotEmpty ? 'Searching: $queryParam' : 'Searching through texts',
        };
      case 'regex_word_search':
        return {
          'title': 'Regex',
          'description': queryParam.isNotEmpty ? 'Pattern: $queryParam' : 'Advanced pattern search',
        };
      default:
        final displayName = _getToolDisplayName(toolCall.name);
        return {
          'title': displayName ?? toolCall.name.replaceAll('_', ' '),
          'description': queryParam.isNotEmpty ? queryParam : 'Executing tool operation',
        };
    }
  }

  String _extractQueryParameter(ToolCall toolCall) {
    if (toolCall.parameters == null) return '';
    
    try {
      // Check for common query parameter names based on tool type
      switch (toolCall.name.toLowerCase()) {
        case 'dict_lookup':
        case 'get-word-definition':
          // Check for dict_words (array) or dict_word (single)
          if (toolCall.parameters!['dict_words'] != null) {
            final words = toolCall.parameters!['dict_words'];
            if (words is List && words.isNotEmpty) {
              return words.length == 1 ? words[0].toString() : '${words.length} words';
            }
          }
          if (toolCall.parameters!['dict_word'] != null) {
            return toolCall.parameters!['dict_word'].toString();
          }
          if (toolCall.parameters!['words'] != null) {
            return toolCall.parameters!['words'].toString();
          }
          break;
          
        case 'verse_lookup':
        case 'find-verse':
          if (toolCall.parameters!['verse_part'] != null) {
            return toolCall.parameters!['verse_part'].toString();
          }
          if (toolCall.parameters!['query'] != null) {
            return toolCall.parameters!['query'].toString();
          }
          break;
          
        case 'chunk_search':
        case 'chunk_lookup':
          if (toolCall.parameters!['chunk_query'] != null) {
            return toolCall.parameters!['chunk_query'].toString();
          }
          if (toolCall.parameters!['query'] != null) {
            return toolCall.parameters!['query'].toString();
          }
          break;
          
        case 'regex_word_search':
          if (toolCall.parameters!['pattern'] != null) {
            return toolCall.parameters!['pattern'].toString();
          }
          break;
          
        case 'heritage_lookup':
          // Extract the query from heritage_lookup parameters
          if (toolCall.parameters!['query'] != null) {
            return toolCall.parameters!['query'].toString();
          }
          break;
      }
      
      // Fallback: try common parameter names
      for (String key in ['query', 'input', 'search', 'text']) {
        if (toolCall.parameters!.containsKey(key) && toolCall.parameters![key] != null) {
          return toolCall.parameters![key].toString();
        }
      }
    } catch (e) {
      // Ignore parameter extraction errors
    }
    
    return '';
  }

     IconData _getToolIcon(String toolName) {
     switch (toolName.toLowerCase()) {
       case 'heritage_lookup':
         return Icons.account_balance; // Heritage/temple icon
       case 'chunk_lookup':
       case 'chunk_search':
         return Icons.menu_book; // Standardized Books icon
       case 'dict_lookup':
       case 'get-word-definition':
         return Icons.local_library_outlined; // Standardized WordDefine icon
       case 'verse_lookup':
       case 'find-verse':
         return Icons.keyboard_command_key; // Standardized QuickVerse icon
       case 'regex_word_search':
         return Icons.search; // Pattern search icon (Regex)
       default:
         return Icons.build_circle; // Default tool icon
     }
   }

  void _handleToolCardTap(ToolCall toolCall) async {
    // Note: Tool cards now show results inline in the Tools & Sources Modal
    // No navigation to other tabs needed - results are displayed within the modal
    
    // This method is kept for compatibility but no longer performs navigation
    // The actual tool handling is done in ToolsAndSourcesModal._handleToolCardTap
  }

  /// Get tool-specific background color (lightest shade)
  Color _getToolBackgroundColor(String toolName) {
    switch (toolName.toLowerCase()) {
      case 'dict_lookup':
      case 'get-word-definition':
        return const Color(0xFFffeaea); // WordDefine red shade 50 (lightest)
      case 'verse_lookup':
      case 'find-verse':
        return const Color(0xFFe8f5f0); // QuickVerse green shade 50 (lightest)
      case 'chunk_lookup':
      case 'chunk_search':
        return Colors.blue.shade50; // Books blue shade 50 (lightest)
      case 'heritage_lookup':
        return Colors.indigo.shade50; // Heritage indigo shade 50 (lightest)
      case 'regex_word_search':
        return Colors.purple.shade50; // Purple shade 50 (lightest)
      default:
        return Colors.indigo.shade50; // Default lightest indigo
    }
  }

  MaterialColor _getToolColor(String toolName) {
    // Use exact colors from WordDefine, QuickVerse modules for consistency
    switch (toolName.toLowerCase()) {
      case 'heritage_lookup':
        return Colors.indigo; // Indigo for heritage
      case 'chunk_lookup':
      case 'chunk_search':
        return Colors.blue; // Blue for Chunk (books/text search)
      case 'dict_lookup':
      case 'get-word-definition':
        // Use standardized WordDefine red: #c60000
        return MaterialColor(0xFFc60000, const <int, Color>{
          50: Color(0xFFffeaea),
          100: Color(0xFFffd5d5),
          200: Color(0xFFffabab),
          300: Color(0xFFff8080),
          400: Color(0xFFff5656),
          500: Color(0xFFc60000), // Main color - matches WordDefine
          600: Color(0xFFb50000),
          700: Color(0xFF9f0000),
          800: Color(0xFF8a0000),
          900: Color(0xFF750000),
        });
      case 'verse_lookup':
      case 'find-verse':
        // Use standardized QuickVerse green: #059669
        return MaterialColor(0xFF059669, const <int, Color>{
          50: Color(0xFFe8f5f0),
          100: Color(0xFFd1ebe1),
          200: Color(0xFFa3d7c3),
          300: Color(0xFF75c3a5),
          400: Color(0xFF47af87),
          500: Color(0xFF059669), // Main color - matches QuickVerse
          600: Color(0xFF04875f),
          700: Color(0xFF037854),
          800: Color(0xFF026a4a),
          900: Color(0xFF015b40),
        });
      case 'regex_word_search':
        return Colors.purple; // Violet/Purple for regex
      default:
        return Colors.indigo; // Default indigo
    }
  }

  String? _getToolDisplayName(String toolName) {
    switch (toolName.toLowerCase()) {
      case 'heritage_lookup':
        return 'Heritage Lookup';
      case 'chunk_search':
      case 'chunk_lookup':
        return 'Chunk'; // Books/text search - blue
      case 'dict_lookup':
      case 'get-word-definition':
        return 'WordDefine'; // Dictionary - red  
      case 'verse_lookup':
      case 'find-verse':
        return 'QuickVerse'; // Verse search - green
      case 'regex_word_search':
        return 'Regex'; // Pattern search - violet
      default:
        // Return null for unknown tools so they get filtered out (consistent with modal)
        return null;
    }
  }

  String _formatToolParameters(Map<String, dynamic> parameters) {
    if (parameters.isEmpty) return 'No parameters';
    
    return parameters.entries.map((entry) {
      return '${entry.key}: ${entry.value}';
    }).join('\n');
  }

  Widget _buildSourcesTab() {
    if (message.citations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.source_outlined, size: 48, color: widget.themeColors?.isDark == true ? Colors.grey.shade600 : Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No sources available',
              style: TextStyle(
                color: widget.themeColors?.isDark == true ? Colors.grey.shade400 : Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sources will appear here when available',
              style: TextStyle(
                color: widget.themeColors?.isDark == true ? Colors.grey.shade500 : Colors.grey.shade400,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort sources by citation number (id) in ascending order
    final sortedSources = List<SourceCitation>.from(message.citations)
      ..sort((a, b) => a.id.compareTo(b.id));

    return ListView.builder(
      controller: _sourcesScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: sortedSources.length,
      itemBuilder: (context, index) {
        final source = sortedSources[index];
        return _buildSimpleSourceCard(source, source.id);
      },
    );
  }

  Widget _buildSimpleSourceCard(SourceCitation source, int sourceNumber) {
    return _ExpandableSimpleSourceCard(
      key: _sourceKeys[sourceNumber],
      source: source,
      sourceNumber: sourceNumber,
      themeColors: widget.themeColors,
    );
  }

  MaterialColor _getSourceTypeColor(String type) {
    // Use exact colors from WordDefine, QuickVerse modules for consistency
    switch (type.toLowerCase()) {
      case 'verse':
        // Use sophisticated muted green: #059669
        return MaterialColor(0xFF059669, const <int, Color>{
          50: Color(0xFFe8f5f0),
          100: Color(0xFFd1ebe1),
          200: Color(0xFFa3d7c3),
          300: Color(0xFF75c3a5),
          400: Color(0xFF47af87),
          500: Color(0xFF059669), // Main color
          600: Color(0xFF04875f),
          700: Color(0xFF037854),
          800: Color(0xFF026a4a),
          900: Color(0xFF015b40),
        });
      case 'defn':
      case 'definition':
        // Use sophisticated muted red: #c60000
        return MaterialColor(0xFFc60000, const <int, Color>{
          50: Color(0xFFffeaea),
          100: Color(0xFFffd5d5),
          200: Color(0xFFffabab),
          300: Color(0xFFff8080),
          400: Color(0xFFff5656),
          500: Color(0xFFc60000), // Main color
          600: Color(0xFFb50000),
          700: Color(0xFF9f0000),
          800: Color(0xFF8a0000),
          900: Color(0xFF750000),
        });
      case 'chunk':
        return Colors.blue; // Blue for Chunk
      default:
        return Colors.indigo;
    }
  }

  IconData _getSourceTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'verse':
        return Icons.keyboard_command_key; // QuickVerse icon from dashboard
      case 'defn':
      case 'definition':
        return Icons.local_library_outlined; // WordDefine icon from dashboard
      case 'chunk':
        return Icons.menu_book; // Books/text search icon
      default:
        return Icons.source_outlined;
    }
  }

  String _getSourceTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'verse':
        return 'Verse'; // Match new consistent naming
      case 'defn':
      case 'definition':
        return 'Dict'; // Match new consistent naming
      case 'chunk':
        return 'Books'; // Match new consistent naming
      default:
        return type.toUpperCase();
    }
  }

  Widget _buildTasksTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Task tracking coming soon',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAiIcon(AiModel? model) {
    if (model == null) return Icons.smart_toy;
    
    switch (model) {
      case AiModel.gemini:
        return Icons.flash_on;
      case AiModel.qwen:
        return Icons.chat_bubble_outline;
    }
  }

  /// Consolidate and group tool calls for clean display (same logic as modal)
  List<ToolCall> _consolidateToolCalls(List<ToolCall> toolCalls) {
    final consolidatedTools = <ToolCall>[];
    final processedTypes = <String>{};
    
    // Group tools by type to create consolidated display
    for (final toolCall in toolCalls) {
      final toolName = toolCall.name.toLowerCase();
      
      // Skip heritage_lookup as it should be broken down
      if (toolName.contains('heritage_lookup')) {
        continue;
      }
      
      // Group dict-related tools
      if ((toolName.contains('dict') || toolName.contains('word')) && !processedTypes.contains('dict')) {
        // Find all dict-related tools and combine their parameters
        final dictTools = toolCalls.where((tc) => 
          tc.name.toLowerCase().contains('dict') || 
          tc.name.toLowerCase().contains('word')
        ).toList();
        
        if (dictTools.isNotEmpty) {
          // Combine all words from dict tools
          final allWords = <String>{};
          final combinedParams = <String, dynamic>{};
          
          for (final dictTool in dictTools) {
            // Extract words from various parameter formats
            final params = dictTool.parameters;
            for (final key in ['words', 'dict_words', 'word', 'dict_word']) {
              final value = params[key];
              if (value != null) {
                if (value is List) {
                  allWords.addAll(value.map((w) => w.toString()));
                } else {
                  allWords.add(value.toString());
                }
              }
            }
            combinedParams.addAll(params);
          }
          
          // Create consolidated dict tool
          consolidatedTools.add(ToolCall(
            name: 'dict_lookup',
            parameters: {
              'words': allWords.toList(),
              'dict_words': allWords.toList(),
              ...combinedParams,
            },
            startTime: dictTools.first.startTime,
            endTime: dictTools.first.endTime,
            result: dictTools.first.result,
          ));
          processedTypes.add('dict');
        }
      }
      
      // Group verse-related tools  
      else if ((toolName.contains('verse') || toolName.contains('heritage')) && !processedTypes.contains('verse')) {
        final verseTools = toolCalls.where((tc) => 
          tc.name.toLowerCase().contains('verse') || 
          tc.name.toLowerCase().contains('heritage')
        ).toList();
        
        if (verseTools.isNotEmpty) {
          // Use the first verse tool as base, combine parameters
          final combinedParams = <String, dynamic>{};
          for (final verseTool in verseTools) {
            combinedParams.addAll(verseTool.parameters);
          }
          
          consolidatedTools.add(ToolCall(
            name: 'verse_lookup',
            parameters: combinedParams,
            startTime: verseTools.first.startTime,
            endTime: verseTools.first.endTime,
            result: verseTools.first.result,
          ));
          processedTypes.add('verse');
        }
      }
      
      // Group chunk/books-related tools
      else if (toolName.contains('chunk') && !processedTypes.contains('chunk')) {
        final chunkTools = toolCalls.where((tc) => 
          tc.name.toLowerCase().contains('chunk')
        ).toList();
        
        if (chunkTools.isNotEmpty) {
          consolidatedTools.add(ToolCall(
            name: 'chunk_search',
            parameters: chunkTools.first.parameters,
            startTime: chunkTools.first.startTime,
            endTime: chunkTools.first.endTime,
            result: chunkTools.first.result,
          ));
          processedTypes.add('chunk');
        }
      }
      
      // Handle other tools individually
      else if (!toolName.contains('dict') && 
               !toolName.contains('word') && 
               !toolName.contains('verse') && 
               !toolName.contains('heritage') && 
               !toolName.contains('chunk')) {
        consolidatedTools.add(toolCall);
      }
    }
    
    return consolidatedTools;
  }
}

/// Expandable citation widget for handling +N expansion
class _ExpandableCitationWidget extends StatefulWidget {
  final List<Map<String, dynamic>> citations;
  
  const _ExpandableCitationWidget({required this.citations});
  
  @override
  _ExpandableCitationWidgetState createState() => _ExpandableCitationWidgetState();
}

class _ExpandableCitationWidgetState extends State<_ExpandableCitationWidget> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    const int maxVisible = 3;
    final bool hasMany = widget.citations.length > maxVisible;
    
    return Wrap(
      spacing: 4,
      children: [
        // Show first 3 citations or all if expanded
        ...widget.citations.take(_isExpanded ? widget.citations.length : maxVisible).map((citation) =>
          _buildInlineCitationChip(citation['number'] as int)
        ),
        
        // Show "+N more" button if there are many citations
        if (hasMany && !_isExpanded)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Text(
                '[+${widget.citations.length - maxVisible}]',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        
        // Show "show less" button if expanded
        if (hasMany && _isExpanded)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Text(
                '[-]',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  /// Build individual citation chip for inline citations with source-type coloring
  Widget _buildInlineCitationChip(int sourceNumber) {
    // We need to find the parent ChatMessageWidget to call _onSourceCitationClick
    final chatMessageWidget = context.findAncestorStateOfType<_ChatMessageWidgetState>();
    final state = chatMessageWidget;
    
    // Find the source for this citation number to determine color
    final citations = state?.widget.message.citations ?? [];
    final source = citations.isNotEmpty 
        ? citations.firstWhere(
            (citation) => citation.id == sourceNumber,
            orElse: () => citations.first,
          )
        : null;
    
    // Get source-type specific color
    MaterialColor sourceColor = Colors.indigo; // Default fallback
    if (source != null) {
      sourceColor = _getSourceColorFromType(source.type);
    }
    
    // Apply theme-aware colors based on source type
    final bgColor = state?.widget.themeColors?.isDark == true 
        ? sourceColor.shade800.withValues(alpha: 0.3)
        : sourceColor.shade50;
    final borderColor = state?.widget.themeColors?.isDark == true 
        ? sourceColor.shade400
        : sourceColor.shade300;
    final textColor = state?.widget.themeColors?.isDark == true 
        ? sourceColor.shade200
        : sourceColor.shade700;
    
    return GestureDetector(
      onTap: () => chatMessageWidget?._onSourceCitationClick(sourceNumber),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          '[$sourceNumber]',
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Get source-type specific color for citation chips
  MaterialColor _getSourceColorFromType(String type) {
    // Use exact colors from WordDefine, QuickVerse modules for consistency
    switch (type.toLowerCase()) {
      case 'verse':
        return MaterialColor(0xFF059669, {
          50: Color(0xFFECFDF5),
          100: Color(0xFFD1FAE5),
          200: Color(0xFFA7F3D0),
          300: Color(0xFF6EE7B7),
          400: Color(0xFF34D399),
          500: Color(0xFF059669),
          600: Color(0xFF047857),
          700: Color(0xFF065F46),
          800: Color(0xFF064E3B),
          900: Color(0xFF022C22),
        });
      case 'defn':
      case 'definition':
        return MaterialColor(0xFFc60000, {
          50: Color(0xFFFEF2F2),
          100: Color(0xFFFEE2E2),
          200: Color(0xFFFECACA),
          300: Color(0xFFFCA5A5),
          400: Color(0xFFF87171),
          500: Color(0xFFc60000),
          600: Color(0xFFDC2626),
          700: Color(0xFFB91C1C),
          800: Color(0xFF991B1B),
          900: Color(0xFF7F1D1D),
        });
      case 'chunk':
        return Colors.blue;
      case 'regex':
        return Colors.purple;
      default:
        return Colors.indigo;
    }
  }
}

/// Expandable source card widget (Perplexity-style)
class _ExpandableSourceCard extends StatefulWidget {
  final SourceCitation source;

  const _ExpandableSourceCard({
    Key? key,
    required this.source,
  }) : super(key: key);

  @override
  State<_ExpandableSourceCard> createState() => _ExpandableSourceCardState();
}

class _ExpandableSourceCardState extends State<_ExpandableSourceCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isHighlighted = false;
  late AnimationController _animationController;
  late AnimationController _highlightController;
  late Animation<double> _expandAnimation;
  late Animation<Color?> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Highlight animation (like webapp's 2 second highlight)
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _highlightAnimation = ColorTween(
      begin: Colors.transparent,
      end: _getSourceTypeColor(widget.source.type).withValues(alpha: 0.1),
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  /// Trigger highlight animation (called when source citation is clicked)
  void highlightSource() {
    if (mounted) {
      _highlightController.forward().then((_) {
        if (mounted) {
          _highlightController.reverse();
        }
      });
    }
  }

  MaterialColor _getSourceTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'verse':
        return Colors.green; // QuickVerse color
      case 'defn':
        return Colors.red; // WordDefine color  
      case 'chunk':
        return Colors.blue; // Chunk color
      default:
        return Colors.indigo;
    }
  }

  IconData _getSourceTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'verse':
        return Icons.auto_stories; // QuickVerse icon
      case 'defn':
        return Icons.translate; // WordDefine icon
      case 'chunk':
        return Icons.article; // Chunk icon
      default:
        return Icons.source;
    }
  }

  String _getSourceTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'verse':
        return 'Verse';
      case 'defn':
        return 'Definition';
      case 'chunk':
        return 'Text';
      default:
        return 'Source';
    }
  }

  @override
  Widget build(BuildContext context) {
    const int previewMaxLength = 150; // Character limit for preview
    final bool hasLongContent = (widget.source.text?.length ?? 0) > previewMaxLength;
    final String previewText = hasLongContent && !_isExpanded
        ? '${widget.source.text!.substring(0, previewMaxLength)}...'
        : widget.source.text ?? '';

    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _highlightAnimation.value ?? Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            // Remove shadow effects for clean Prashna design
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: hasLongContent ? _toggleExpanded : null,
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source header
                Row(
                  children: [
                    // Source number badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _getSourceTypeColor(widget.source.type),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.source.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Source info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Source reference/title
                          Text(
                            widget.source.reference ?? 'Source ${widget.source.id}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 2),
                          
                          // Source type badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getSourceTypeColor(widget.source.type).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getSourceTypeIcon(widget.source.type), 
                                  size: 12, 
                                  color: _getSourceTypeColor(widget.source.type)
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getSourceTypeDisplayName(widget.source.type),
                                  style: TextStyle(
                                    color: _getSourceTypeColor(widget.source.type),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Expand/collapse indicator (only show if content is long)
                    if (hasLongContent)
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                
                // Source content
                if (widget.source.text != null && widget.source.text!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            previewText,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          
                          // Expand/collapse action (only show if content is long)
                          if (hasLongContent) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _toggleExpanded,
                              child: Row(
                                children: [
                                  Text(
                                    _isExpanded ? 'Show less' : 'Show more',
                                    style: TextStyle(
                                      color: _getSourceTypeColor(widget.source.type),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                                    color: _getSourceTypeColor(widget.source.type),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
            ),
          ),
        );
      },
    );
  }
}

/// Expandable simple source card widget
class _ExpandableSimpleSourceCard extends StatefulWidget {
  final SourceCitation source;
  final int sourceNumber;
  final AppThemeColors? themeColors;

  const _ExpandableSimpleSourceCard({
    Key? key,
    required this.source,
    required this.sourceNumber,
    this.themeColors,
  }) : super(key: key);

  @override
  State<_ExpandableSimpleSourceCard> createState() => _ExpandableSimpleSourceCardState();
}

class _ExpandableSimpleSourceCardState extends State<_ExpandableSimpleSourceCard> {
  bool _isExpanded = false;

  MaterialColor _getSourceTypeColor(String type) {
    // Use exact colors from WordDefine, QuickVerse modules for consistency
    switch (type.toLowerCase()) {
      case 'verse':
        // Use sophisticated muted green: #059669
        return MaterialColor(0xFF059669, const <int, Color>{
          50: Color(0xFFe8f5f0),
          100: Color(0xFFd1ebe1),
          200: Color(0xFFa3d7c3),
          300: Color(0xFF75c3a5),
          400: Color(0xFF47af87),
          500: Color(0xFF059669), // Main color
          600: Color(0xFF04875f),
          700: Color(0xFF037854),
          800: Color(0xFF026a4a),
          900: Color(0xFF015b40),
        });
      case 'defn':
      case 'definition':
        // Use sophisticated muted red: #c60000
        return MaterialColor(0xFFc60000, const <int, Color>{
          50: Color(0xFFffeaea),
          100: Color(0xFFffd5d5),
          200: Color(0xFFffabab),
          300: Color(0xFFff8080),
          400: Color(0xFFff5656),
          500: Color(0xFFc60000), // Main color
          600: Color(0xFFb50000),
          700: Color(0xFF9f0000),
          800: Color(0xFF8a0000),
          900: Color(0xFF750000),
        });
      case 'chunk':
        return Colors.blue; // Blue for Chunk
      default:
        return Colors.indigo;
    }
  }

  IconData _getSourceTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'verse':
        return Icons.keyboard_command_key; // QuickVerse icon from dashboard
      case 'defn':
      case 'definition':
        return Icons.local_library_outlined; // WordDefine icon from dashboard
      case 'chunk':
        return Icons.menu_book; // Books/text search icon
      default:
        return Icons.source_outlined;
    }
  }

  String _getSourceTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'verse':
        return 'Verse'; // Match new consistent naming
      case 'defn':
      case 'definition':
        return 'Dict'; // Match new consistent naming
      case 'chunk':
        return 'Books'; // Match new consistent naming
      default:
        return type.toUpperCase();
    }
  }

  /// Get enhanced source title with word context if available
  String _getEnhancedSourceTitle(SourceCitation source) {
    final baseTitle = _getSourceTypeDisplayName(source.type);
    
    switch (source.type.toLowerCase()) {
      case 'defn':
      case 'definition':
        // For definitions, if we have the word in reference, show it
        if (source.reference != null && 
            source.reference!.isNotEmpty && 
            source.reference != 'Definition') {
          // Only show the word if it's a meaningful word (not just "Definition")
          return 'Dict: ${source.reference}';
        }
        break;
        
      case 'verse':
      case 'verses':
        // For verses, if we have verse reference, show it
        if (source.reference != null && 
            source.reference!.isNotEmpty) {
          // Could be verse number, chapter, or verse identifier
          return 'Verse: ${source.reference}';
        }
        break;
        
      case 'chunk':
      case 'book':
      case 'books':
        // For books, if we have book/chapter reference, show it
        if (source.reference != null && 
            source.reference!.isNotEmpty) {
          // Could be book name, chapter, or section
          return 'Books: ${source.reference}';
        }
        break;
    }
    
    return baseTitle;
  }

  /// Trigger highlight animation (called when source citation is clicked)
  void highlightSource() {
    // Simple visual feedback without complex animation
    if (mounted) {
      setState(() {
        // Force a quick rebuild to provide visual feedback
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceColor = _getSourceTypeColor(widget.source.type);
    final sourceIcon = _getSourceTypeIcon(widget.source.type);
    final sourceTitle = _getEnhancedSourceTitle(widget.source);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.themeColors?.isDark == true 
              ? sourceColor.shade800.withOpacity(0.3)
              : sourceColor.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.themeColors?.isDark == true 
                    ? (_isExpanded ? sourceColor.shade500 : sourceColor.shade600)
                    : (_isExpanded ? sourceColor.shade400 : sourceColor.shade300), 
                width: _isExpanded ? 2 : 1,
              ),
          // Remove shadow effects for clean Prashna design
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source number and icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: sourceColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.sourceNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Source info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            sourceIcon,
                            size: 16,
                            color: sourceColor.shade700,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              sourceTitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: sourceColor.shade700,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              maxLines: null,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: sourceColor.shade600,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (widget.source.reference?.isNotEmpty == true)
                        Text(
                          widget.source.reference!,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.themeColors?.isDark == true 
                                ? Colors.grey.shade400 
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: _isExpanded ? null : 1,
                          overflow: _isExpanded ? null : TextOverflow.ellipsis,
                        ),
                      if (widget.source.text?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.source.text!,
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.themeColors?.isDark == true 
                                ? Colors.grey.shade400 
                                : Colors.grey.shade500,
                          ),
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded ? null : TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Show URL when expanded
            if (_isExpanded && widget.source.url?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sourceColor.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 14,
                      color: sourceColor.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.source.url!,
                        style: TextStyle(
                          fontSize: 10,
                          color: sourceColor.shade600,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get source-type specific color for citation chips (static method for use in expandable cards)
  MaterialColor _getSourceTypeColorForCitation(String type) {
    // Use exact colors from WordDefine, QuickVerse modules for consistency
    switch (type.toLowerCase()) {
      case 'verse':
        return MaterialColor(0xFF059669, {
          50: Color(0xFFECFDF5),
          100: Color(0xFFD1FAE5),
          200: Color(0xFFA7F3D0),
          300: Color(0xFF6EE7B7),
          400: Color(0xFF34D399),
          500: Color(0xFF059669),
          600: Color(0xFF047857),
          700: Color(0xFF065F46),
          800: Color(0xFF064E3B),
          900: Color(0xFF022C22),
        });
      case 'defn':
      case 'definition':
        return MaterialColor(0xFFc60000, {
          50: Color(0xFFFEF2F2),
          100: Color(0xFFFEE2E2),
          200: Color(0xFFFECACA),
          300: Color(0xFFFCA5A5),
          400: Color(0xFFF87171),
          500: Color(0xFFc60000),
          600: Color(0xFFDC2626),
          700: Color(0xFFB91C1C),
          800: Color(0xFF991B1B),
          900: Color(0xFF7F1D1D),
        });
      case 'chunk':
        return Colors.blue;
      case 'regex':
        return Colors.purple;
      default:
        return Colors.indigo;
    }
  }
}
