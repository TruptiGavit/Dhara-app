import 'package:flutter/material.dart';
import 'dhara_plugin.dart';
import 'plugin_types.dart';

/// Manages all registered plugins and coordinates their interactions
/// Replaces the complex switch statements in SearchLandingPage
class DharaPluginManager {
  static final DharaPluginManager _instance = DharaPluginManager._internal();
  factory DharaPluginManager() => _instance;
  DharaPluginManager._internal();

  final Map<PluginType, DharaPlugin> _plugins = {};

  /// Register a plugin
  void registerPlugin(PluginType type, DharaPlugin plugin) {
    _plugins[type] = plugin;
  }

  /// Get a specific plugin
  DharaPlugin? getPlugin(PluginType type) {
    return _plugins[type];
  }

  /// Get all registered plugins
  List<DharaPlugin> getAllPlugins() {
    return _plugins.values.toList();
  }

  /// Get plugins by capability
  List<DharaPlugin> getPluginsByCapability({
    bool? supportsStreaming,
    bool? supportsLanguageSelection,
    bool? supportsBookmarks,
  }) {
    return _plugins.values.where((plugin) {
      final caps = plugin.capabilities;
      return (supportsStreaming == null || caps.supportsStreaming == supportsStreaming) &&
             (supportsLanguageSelection == null || caps.supportsLanguageSelection == supportsLanguageSelection) &&
             (supportsBookmarks == null || caps.supportsBookmarks == supportsBookmarks);
    }).toList();
  }

  /// Perform search in a specific plugin
  Future<void> searchInPlugin(PluginType type, String query, {Map<String, dynamic>? options}) async {
    final plugin = _plugins[type];
    if (plugin != null) {
      await plugin.performSearch(query, options: options);
    }
  }

  /// Build page for a specific plugin
  Widget buildPluginPage(PluginType type, {bool embedded = false, bool hideWelcomeMessage = false}) {
    final plugin = _plugins[type];
    if (plugin == null) {
      return Center(
        child: Text('Plugin not found: $type'),
      );
    }

    if (embedded) {
      return plugin.buildEmbeddedContent();
    } else {
      return plugin.buildStandalonePage(
        hideSearchBar: embedded,
        hideWelcomeMessage: hideWelcomeMessage,
      );
    }
  }

  /// Build empty state for a specific plugin
  Widget buildPluginEmptyState(PluginType type) {
    final plugin = _plugins[type];
    if (plugin == null) {
      return const Center(child: Text('Plugin not found'));
    }
    return plugin.buildEmptyState();
  }

  /// Build loading state for a specific plugin
  Widget buildPluginLoadingState(PluginType type) {
    final plugin = _plugins[type];
    if (plugin == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return plugin.buildLoadingState();
  }

  /// Get search hint for a specific plugin
  String getSearchHint(PluginType type) {
    final plugin = _plugins[type];
    return plugin?.searchHintText ?? 'Search...';
  }

  /// Check if plugin has results
  bool pluginHasResults(PluginType type) {
    final plugin = _plugins[type];
    return plugin?.hasResults ?? false;
  }

  /// Check if plugin is loading
  bool pluginIsLoading(PluginType type) {
    final plugin = _plugins[type];
    return plugin?.isLoading ?? false;
  }

  /// Clear results for a specific plugin
  void clearPluginResults(PluginType type) {
    final plugin = _plugins[type];
    plugin?.clearResults();
  }

  /// Clear results for all plugins
  void clearAllResults() {
    for (final plugin in _plugins.values) {
      plugin.clearResults();
    }
  }
}


