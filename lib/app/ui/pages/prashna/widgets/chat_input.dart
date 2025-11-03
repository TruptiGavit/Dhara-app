import 'package:dharak_flutter/app/types/prashna/ai_model.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isStreaming;
  final bool canSend;
  final VoidCallback onSend;
  final Function(String) onChanged;
  final VoidCallback onSubmitted;
  final AiModel selectedModel;
  final String? currentTool;
  final AppThemeColors? themeColors;
  final AppThemeDisplay? appThemeDisplay;
  final bool isDeveloperMode;

  const ChatInput({
    super.key,
    required this.controller,
    required this.isStreaming,
    required this.canSend,
    required this.onSend,
    required this.onChanged,
    required this.onSubmitted,
    required this.selectedModel,
    this.currentTool,
    this.themeColors,
    this.appThemeDisplay,
    this.isDeveloperMode = false,
  });

  /// Get dynamic streaming message based on current tool
  String _getStreamingMessage(String? currentTool) {
    if (currentTool == null) {
      return isDeveloperMode ? '${selectedModel.displayName} is thinking...' : 'AI is thinking...';
    }

    // Extract tool name and parameters if available
    String toolName = currentTool;
    String? queryParam;
    
    // Parse tool name for parameters
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
            if (queryParam!.length > 20) {
              queryParam = '${queryParam!.substring(0, 20)}...';
            }
          }
        }
      } catch (e) {
        // If parsing fails, use default messages
      }
    }
    
    if (kDebugMode) print('🔧 STREAMING DEBUG: Checking toolName.toLowerCase() = "${toolName.toLowerCase()}"');
    switch (toolName.toLowerCase()) {
      case 'dict_lookup':
        if (kDebugMode) print('🔧 STREAMING DEBUG: Matched dict_lookup case');
        return queryParam != null 
            ? 'Searching meaning of [$queryParam]'
            : 'Searching word meanings...';
      case 'verse_lookup':
        if (kDebugMode) print('🔧 STREAMING DEBUG: Matched verse_lookup case');
        return queryParam != null 
            ? 'Looking up verse for [$queryParam]'
            : 'Looking up verses...';
      case 'chunk_search':
      case 'chunk_lookup':
        if (kDebugMode) print('🔧 STREAMING DEBUG: Matched chunk_search/chunk_lookup case');
        return queryParam != null 
            ? 'Searching books for [$queryParam]'
            : 'Searching texts...';
      case 'regex_word_search':
        if (kDebugMode) print('🔧 STREAMING DEBUG: Matched regex_word_search case');
        return 'Finding patterns...';
      default:
        if (kDebugMode) print('🔧 STREAMING DEBUG: No match found, using default case');
        return isDeveloperMode ? '${selectedModel.displayName} is working...' : 'AI is working...';
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Container(
      decoration: BoxDecoration(
        color: themeColors?.surface ?? Colors.white,
        border: Border(
          top: BorderSide(
            color: themeColors?.primaryLight ?? Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Streaming Indicator
              if (isStreaming)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: themeColors?.primaryLight ?? Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            themeColors?.primaryHigh ?? Colors.indigo.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStreamingMessage(currentTool),
                        style: TextStyle(
                          fontSize: 12,
                          color: themeColors?.primaryHigh ?? Colors.indigo.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Input Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Text Input
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        maxHeight: 120,
                      ),
                      decoration: BoxDecoration(
                        color: themeColors?.surface ?? Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: themeColors?.primary ?? Colors.indigo.shade400,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (themeColors?.primary ?? Colors.indigo.shade400).withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: controller,
                        onChanged: onChanged,
                        onSubmitted: (_) => onSubmitted(),
                        enabled: !isStreaming,
                        maxLines: null,
                                                  decoration: InputDecoration(
                            hintText: isStreaming 
                                ? 'Please wait...' 
                                : 'Ask a question...',
                            hintStyle: TextStyle(
                              color: themeColors?.onSurfaceDisable ?? Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: themeColors?.onSurface ?? Colors.black,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Send Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: canSend ? () {
                        onSend();
                      } : null,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: canSend 
                              ? themeColors?.primaryHigh ?? Colors.indigo.shade600 
                              : themeColors?.onSurfaceDisable ?? Colors.grey.shade300,
                          shape: BoxShape.circle,
                          boxShadow: canSend ? [
                            BoxShadow(
                              color: (themeColors?.primary ?? Colors.indigo.shade200).withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: Icon(
                          isStreaming ? Icons.stop : Icons.send,
                          color: canSend 
                              ? themeColors?.surface ?? Colors.white 
                              : themeColors?.onSurfaceLowest ?? Colors.grey.shade500,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Model Indicator - COMMENTED OUT AS REQUESTED
              /*
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      _getModelIcon(selectedModel),
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDeveloperMode ? 'Powered by ${selectedModel.displayName}' : 'Powered by AI',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Press Enter to send',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              */
            ],
          ),
        ),
      ),
    );
  }

  IconData _getModelIcon(AiModel model) {
    switch (model) {
      case AiModel.gemini:
        return Icons.flash_on;
      case AiModel.qwen:
        return Icons.chat_bubble_outline;
    }
  }
}

