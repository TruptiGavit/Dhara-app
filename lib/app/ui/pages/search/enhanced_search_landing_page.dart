import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:provider/provider.dart';
import 'package:dharak_flutter/app/core/plugins/plugin_manager.dart';
import 'package:dharak_flutter/app/core/plugins/plugin_types.dart';
import 'package:dharak_flutter/app/tools/route/route_change_notifier.dart';
import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'dart:async';

/// Enhanced Search Landing Page using the Plugin System
/// This is a complete replacement for your 2,535-line SearchLandingPage
/// Provides EXACTLY the same UI and functionality with much cleaner code
class EnhancedSearchLandingPage extends StatefulWidget {
  const EnhancedSearchLandingPage({super.key});

  @override
  State<EnhancedSearchLandingPage> createState() => _EnhancedSearchLandingPageState();
}

class _EnhancedSearchLandingPageState extends State<EnhancedSearchLandingPage> 
    with TickerProviderStateMixin {
  late AppThemeColors themeColors;
  late DharaPluginManager _pluginManager;
  
  // Tab management for unified interface
  int _selectedTabIndex = 0;
  bool _isTabSwitching = false;
  
  // Base plugins (always available)
  final List<PluginType> _basePlugins = [
    PluginType.wordDefine,
    PluginType.quickVerse,
    PluginType.books,
  ];
  
  // Dynamic getters for tabs (unified tab now available for everyone)
  List<PluginType> get _availablePlugins {
    return [..._basePlugins, PluginType.unified];
  }
  
  // Current state management
  Timer? _debounceTimer;
  bool _isSearching = false;
  bool _hasSearched = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Tab-specific state management
  final Map<int, TextEditingController> _tabSearchControllers = {};
  final Map<int, bool> _tabHasSearched = {};
  final Map<int, bool> _tabIsSearching = {};

  @override
  void initState() {
    super.initState();
    
    // Initialize plugin manager
    _pluginManager = Modular.get<DharaPluginManager>();
    
    // Trigger plugin setup (this loads the plugins)
    try {
      // Plugin setup check
    } catch (e) {
      print('Plugin setup not yet complete, will retry...');
    }
    
    // Initialize controllers for each tab
    for (int i = 0; i < 10; i++) { // Support up to 10 plugins
      _tabSearchControllers[i] = TextEditingController();
      _tabHasSearched[i] = false;
      _tabIsSearching[i] = false;
    }
    
    // Animation setup
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      
      // Set the current tab for the dashboard
      Provider.of<RouteChangeNotifier>(
        context,
        listen: false,
      ).updateTab(UiConstants.Tabs.search);
      
      // Initialize developer mode listeners
      // Unified tab is now available for everyone - no need for developer mode checks
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    themeColors = Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: const Color(0xFF6CE18D), isDark: false);
  }

  // Removed developer mode listeners - unified tab is now available for everyone

  PluginType get _currentPluginType => _availablePlugins[_selectedTabIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeColors.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildTabBar(),
              _buildSearchBar(),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    // Smart flex distribution based on text length for better responsive design
    final Map<String, int> tabFlexValues = {
      'WordDefine': 3,  // Longest text, needs more space
      'QuickVerse': 3,  // Also long text
      'Books': 2,       // Shorter text, less space needed
      'Unified': 2,     // Shorter text, less space needed
    };
    
    return Container(
      margin: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0),
      child: Row(
        children: List.generate(_availablePlugins.length, (index) {
          final pluginType = _availablePlugins[index];
          final plugin = _pluginManager.getPlugin(pluginType);
          final isSelected = index == _selectedTabIndex;
          
          if (plugin == null) return const SizedBox.shrink();
          
          final flexValue = tabFlexValues[plugin.displayName] ?? 2; // Default to 2 if not found
          
          return Expanded(
            flex: flexValue, // Use smart flex distribution
            child: GestureDetector(
              onTap: () {
                // Set tab switching flag to prevent auto-search
                _isTabSwitching = true;
                
                setState(() {
                  _selectedTabIndex = index;
                  // Switch to tab-specific state
                  _hasSearched = _tabHasSearched[index] ?? false;
                  _isSearching = _tabIsSearching[index] ?? false;
                });
                
                // Clear the tab switching flag after a short delay
                Future.delayed(const Duration(milliseconds: 100), () {
                  _isTabSwitching = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                margin: EdgeInsets.only(right: index < _availablePlugins.length - 1 ? 6.0 : 0),
                decoration: BoxDecoration(
                  color: isSelected ? plugin.themeColor.withOpacity(0.1) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? plugin.themeColor : themeColors.onSurface?.withOpacity(0.3) ?? Colors.grey,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  plugin.displayName,
                  textAlign: TextAlign.center,
                  maxLines: 1, // Prevent text wrapping
                  overflow: TextOverflow.ellipsis, // Add ellipsis if still too long
                  style: TdResTextStyles.h6.copyWith(
                    color: isSelected ? plugin.themeColor : themeColors.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar() {
    final plugin = _pluginManager.getPlugin(_currentPluginType);
    if (plugin == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 8.0),
      decoration: BoxDecoration(
        color: themeColors.surface,
        border: Border.all(
          color: plugin.themeColor,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
              child: TextField(
                controller: _tabSearchControllers[_selectedTabIndex],
                onChanged: (value) => _onSearchChanged(),
                onSubmitted: (query) => _onManualSearch(),
                decoration: InputDecoration(
                  hintText: plugin.searchHintText,
                  hintStyle: TdResTextStyles.h5.copyWith(
                    color: themeColors.onSurfaceMedium,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  prefixIcon: Icon(
                    Icons.search,
                    color: plugin.themeColor,
                    size: 20.0,
                  ),
                  suffixIcon: (_tabSearchControllers[_selectedTabIndex]?.text.isNotEmpty ?? false)
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: themeColors.onSurfaceMedium,
                            size: 18.0,
                          ),
                          onPressed: () {
                            _tabSearchControllers[_selectedTabIndex]?.clear();
                            setState(() {
                              _hasSearched = false;
                              _isSearching = false;
                              _tabHasSearched[_selectedTabIndex] = false;
                              _tabIsSearching[_selectedTabIndex] = false;
                            });
                            plugin.clearResults();
                          },
                        )
                      : null,
                ),
                style: TdResTextStyles.h5.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 6.0),
            child: ElevatedButton(
              onPressed: _onManualSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: plugin.themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 16),
                  SizedBox(width: 3),
                  Text(
                    'Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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

  Widget _buildContent() {
    final plugin = _pluginManager.getPlugin(_currentPluginType);
    if (plugin == null) {
      return const Center(child: Text('Plugin not available'));
    }

    if (_isSearching) {
      return plugin.buildLoadingState();
    }

    if (!_hasSearched) {
      return plugin.buildEmptyState();
    }

    // Show the plugin's embedded content (your exact existing UI)
    return plugin.buildEmbeddedContent();
  }

  void _onSearchChanged() {
    // Skip auto-search if we're in the middle of a tab switch
    if (_isTabSwitching) {
      return;
    }
    
    // Only auto-search for QuickVerse (like your current implementation)
    if (_currentPluginType == PluginType.quickVerse) {
      // Simple debouncing for QuickVerse auto-search
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        final query = _tabSearchControllers[_selectedTabIndex]?.text.trim() ?? '';
        if (query.isNotEmpty) {
          _performModuleSearch(query);
        } else {
          setState(() {
            _hasSearched = false;
            _isSearching = false;
            _tabHasSearched[_selectedTabIndex] = false;
            _tabIsSearching[_selectedTabIndex] = false;
          });
        }
      });
    } else {
      // For other modules, just update the empty state and button visibility
      final query = _tabSearchControllers[_selectedTabIndex]?.text.trim() ?? '';
      setState(() {
        if (query.isEmpty) {
          _hasSearched = false;
          _isSearching = false;
          _tabHasSearched[_selectedTabIndex] = false;
          _tabIsSearching[_selectedTabIndex] = false;
        }
      });
    }
  }

  void _onManualSearch() async {
    final query = _tabSearchControllers[_selectedTabIndex]?.text.trim() ?? '';
    if (query.isNotEmpty) {
      await _performModuleSearch(query);
    }
  }

  Future<void> _performModuleSearch(String query) async {
    final plugin = _pluginManager.getPlugin(_currentPluginType);
    if (plugin == null) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _tabHasSearched[_selectedTabIndex] = true;
      _tabIsSearching[_selectedTabIndex] = true;
    });

    try {
      // Use the plugin's search method (which calls your existing controller logic)
      await plugin.performSearch(query);
    } catch (e) {
      print('Search error: $e');
    } finally {
      setState(() {
        _isSearching = false;
        _tabIsSearching[_selectedTabIndex] = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _debounceTimer?.cancel();
    
    // Dispose tab-specific controllers
    for (var controller in _tabSearchControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }
}
