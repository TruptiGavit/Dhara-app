import 'package:flutter/material.dart';
import 'plugin_types.dart';

/// Abstract interface for all Dhara modules
/// This wraps existing BLoC controllers without changing them
abstract class DharaPlugin {
  /// Plugin identification
  PluginType get type;
  String get displayName;
  Color get themeColor;
  IconData get icon;
  
  /// Plugin capabilities - what features this module supports
  PluginCapabilities get capabilities;
  
  /// Search functionality - wraps existing controller methods
  Future<void> performSearch(String query, {Map<String, dynamic>? options});
  
  /// UI building methods - returns existing pages/widgets
  Widget buildStandalonePage({bool hideSearchBar = false, bool hideWelcomeMessage = false});
  Widget buildEmbeddedContent();
  Widget buildEmptyState();
  Widget buildLoadingState();
  
  /// Get search hint text for this module
  String get searchHintText;
  
  /// Get welcome title and description
  String get welcomeTitle;
  String get welcomeDescription;
  
  /// Check if this plugin has search results
  bool get hasResults;
  
  /// Check if this plugin is currently loading
  bool get isLoading;
  
  /// Get current search query for this plugin
  String? get currentQuery;
  
  /// Clear search results
  void clearResults();
  
  /// Optional: Get results as standardized format (for unified views)
  List<DharaResult> getStandardizedResults() => [];
}


