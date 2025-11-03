import 'package:flutter/material.dart';
import 'package:dharak_flutter/app/types/prashna/tool_call.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/dictionary_tool_card.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/verse_tool_card.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/books_tool_card.dart';
/// Factory class for creating tool cards based on tool calls
class ToolCardFactory {

  /// Create tool cards from a list of tool calls
  static List<Widget> createToolCards(List<ToolCall> toolCalls) {
    if (toolCalls.isEmpty) {
      return [];
    }

    final widgets = <Widget>[];
    
    for (int i = 0; i < toolCalls.length; i++) {
      final toolCall = toolCalls[i];
      final widget = createToolCard(toolCall, index: i);
      
      if (widget != null) {
        widgets.add(widget);
      }
    }
    
    return widgets;
  }

  /// Create a single tool card based on tool call type
  static Widget? createToolCard(ToolCall toolCall, {int? index}) {
    try {
      switch (toolCall.toolType) {
        case ToolType.dictionary:
          return DictionaryToolCard(
            key: ValueKey('dict_${index ?? 0}_${toolCall.query}'),
            toolCall: toolCall,
          );
          
        case ToolType.verse:
          return VerseToolCard(
            key: ValueKey('verse_${index ?? 0}_${toolCall.query}'),
            toolCall: toolCall,
          );
          
        case ToolType.books:
          return BooksToolCard(
            key: ValueKey('books_${index ?? 0}_${toolCall.query}'),
            toolCall: toolCall,
          );
          
        case ToolType.unknown:
          return _createUnknownToolCard(toolCall, index);
      }
    } catch (e) {
      return _createErrorToolCard(toolCall, e.toString(), index);
    }
  }

  /// Create a card for unknown tool types
  static Widget _createUnknownToolCard(ToolCall toolCall, int? index) {
    return Card(
      key: ValueKey('unknown_${index ?? 0}_${toolCall.query}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Unknown Tool: ${toolCall.toolName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Query: ${toolCall.query}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This tool type is not yet supported in the UI.',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Create a card for tools that failed to load
  static Widget _createErrorToolCard(ToolCall toolCall, String error, int? index) {
    return Card(
      key: ValueKey('error_${index ?? 0}_${toolCall.query}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Error: ${toolCall.displayName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Query: ${toolCall.query}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Error: $error',
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get statistics about the tool calls
  static Map<String, int> getToolCallStats(List<ToolCall> toolCalls) {
    final stats = <String, int>{};
    
    for (final toolCall in toolCalls) {
      final displayName = toolCall.displayName;
      stats[displayName] = (stats[displayName] ?? 0) + 1;
    }
    
    return stats;
  }

  /// Get unique tool types from tool calls
  static Set<ToolType> getUniqueToolTypes(List<ToolCall> toolCalls) {
    return toolCalls.map((tc) => tc.toolType).toSet();
  }

  /// Group tool calls by type
  static Map<ToolType, List<ToolCall>> groupToolCallsByType(List<ToolCall> toolCalls) {
    final groups = <ToolType, List<ToolCall>>{};
    
    for (final toolCall in toolCalls) {
      groups.putIfAbsent(toolCall.toolType, () => []).add(toolCall);
    }
    
    return groups;
  }
}






















