/// Core types for the Dhara plugin system
/// This allows us to organize modules better without changing existing BLoC logic

enum PluginType {
  wordDefine,
  quickVerse,
  books,
  prashna,
  unified,
}

/// Standard result format that all plugins can optionally use
/// Original data is preserved for module-specific UI components
class DharaResult {
  final String id;
  final PluginType source;
  final String title;
  final String content;
  final String? subtitle;
  
  /// Keep the original response data for existing UI components
  /// This ensures we don't break any existing card layouts
  final dynamic originalData;
  
  /// Additional metadata for filtering, sorting, etc.
  final Map<String, dynamic> metadata;

  const DharaResult({
    required this.id,
    required this.source,
    required this.title,
    required this.content,
    this.subtitle,
    required this.originalData,
    this.metadata = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DharaResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          source == other.source;

  @override
  int get hashCode => id.hashCode ^ source.hashCode;
}

/// Plugin capabilities - allows each module to declare what it supports
class PluginCapabilities {
  final bool supportsStreaming;
  final bool supportsLanguageSelection;
  final bool supportsBookmarks;
  final bool supportsCitation;
  final bool supportsSharing;

  const PluginCapabilities({
    this.supportsStreaming = false,
    this.supportsLanguageSelection = false,
    this.supportsBookmarks = true,
    this.supportsCitation = true,
    this.supportsSharing = true,
  });
}


