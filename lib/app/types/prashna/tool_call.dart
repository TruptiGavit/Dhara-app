import 'dart:convert';

/// Represents a tool call from the Prashna API response
class ToolCall {
  final String toolName;
  final Map<String, dynamic> toolArgs;
  final double? startTime;
  final double? completionTime;
  final double? duration;

  const ToolCall({
    required this.toolName,
    required this.toolArgs,
    this.startTime,
    this.completionTime,
    this.duration,
  });

  /// Get the query string based on tool type
  String get query {
    switch (toolName) {
      case 'dict_lookup':
        return toolArgs['dict_word'] ?? '';
      case 'verse_lookup':
        return toolArgs['verse_part'] ?? '';
      case 'chunk_lookup':
        return toolArgs['chunk_query'] ?? '';
      default:
        return '';
    }
  }

  /// Get the tool type enum
  ToolType get toolType {
    switch (toolName) {
      case 'dict_lookup':
        return ToolType.dictionary;
      case 'verse_lookup':
        return ToolType.verse;
      case 'chunk_lookup':
        return ToolType.books;
      default:
        return ToolType.unknown;
    }
  }

  /// Get display name for the tool
  String get displayName {
    switch (toolName) {
      case 'dict_lookup':
        return 'Dictionary';
      case 'verse_lookup':
        return 'Verse';
      case 'chunk_lookup':
        return 'Books';
      default:
        return 'Unknown';
    }
  }

  /// Get icon for the tool
  String get iconName {
    switch (toolName) {
      case 'dict_lookup':
        return 'book';
      case 'verse_lookup':
        return 'format_quote';
      case 'chunk_lookup':
        return 'library_books';
      default:
        return 'help';
    }
  }

  @override
  String toString() {
    return 'ToolCall(toolName: $toolName, query: "$query", duration: ${duration?.toStringAsFixed(2)}s)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolCall &&
        other.toolName == toolName &&
        other.toolArgs.toString() == toolArgs.toString();
  }

  @override
  int get hashCode => toolName.hashCode ^ toolArgs.toString().hashCode;
}

/// Tool types supported in the system
enum ToolType {
  dictionary,
  verse,
  books,
  unknown,
}

/// Extension for ToolType utility methods
extension ToolTypeExtension on ToolType {
  String get displayName {
    switch (this) {
      case ToolType.dictionary:
        return 'Dictionary';
      case ToolType.verse:
        return 'Verse';
      case ToolType.books:
        return 'Books';
      case ToolType.unknown:
        return 'Unknown';
    }
  }

  String get iconName {
    switch (this) {
      case ToolType.dictionary:
        return 'book';
      case ToolType.verse:
        return 'format_quote';
      case ToolType.books:
        return 'library_books';
      case ToolType.unknown:
        return 'help';
    }
  }
}



























