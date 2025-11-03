import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:dharak_flutter/app/core/plugins/plugin_manager.dart';
import 'package:dharak_flutter/app/core/plugins/plugin_types.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';

/// Simplified search page using the plugin system
/// This demonstrates how your 2,535-line search page could be reduced to ~200 lines
/// While keeping EXACTLY the same UI and functionality
class PluginSearchPage extends StatefulWidget {
  const PluginSearchPage({super.key});

  @override
  State<PluginSearchPage> createState() => _PluginSearchPageState();
}

class _PluginSearchPageState extends State<PluginSearchPage> 
    with TickerProviderStateMixin {
  late AppThemeColors themeColors;
  late DharaPluginManager _pluginManager;
  
  // Current state
  int _selectedTabIndex = 0;
  bool _isSearching = false;
  bool _hasSearched = false;
  
  // Tab configuration from plugins
  List<PluginType> _availablePlugins = [
    PluginType.wordDefine,
    PluginType.quickVerse,
    PluginType.books,
    PluginType.prashna,
    PluginType.unified,
  ];
  
  // Tab-specific controllers
  final Map<int, TextEditingController> _tabControllers = {};
  final Map<int, bool> _tabHasSearched = {};
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize plugin manager
    _pluginManager = Modular.get<DharaPluginManager>();
    
    // Trigger plugin setup (this loads the plugins)
    Modular.get<void>();
    
    // Initialize controllers for each tab
    for (int i = 0; i < _availablePlugins.length; i++) {
      _tabControllers[i] = TextEditingController();
      _tabHasSearched[i] = false;
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
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    themeColors = Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: const Color(0xFF6CE18D), isDark: false);
  }

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
    return Container(
      margin: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0),
      child: Row(
        children: List.generate(_availablePlugins.length, (index) {
          final pluginType = _availablePlugins[index];
          final plugin = _pluginManager.getPlugin(pluginType);
          final isSelected = index == _selectedTabIndex;
          
          if (plugin == null) return const SizedBox.shrink();
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                  _hasSearched = _tabHasSearched[index] ?? false;
                  _isSearching = _pluginManager.pluginIsLoading(pluginType);
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
                controller: _tabControllers[_selectedTabIndex],
                onSubmitted: _onManualSearch,
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
                  suffixIcon: (_tabControllers[_selectedTabIndex]?.text.isNotEmpty ?? false)
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: themeColors.onSurfaceMedium,
                            size: 18.0,
                          ),
                          onPressed: () {
                            _tabControllers[_selectedTabIndex]?.clear();
                            setState(() {
                              _hasSearched = false;
                              _isSearching = false;
                              _tabHasSearched[_selectedTabIndex] = false;
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

  void _onManualSearch() async {
    final query = _tabControllers[_selectedTabIndex]?.text.trim() ?? '';
    if (query.isEmpty) return;

    final plugin = _pluginManager.getPlugin(_currentPluginType);
    if (plugin == null) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _tabHasSearched[_selectedTabIndex] = true;
    });

    try {
      // Use the plugin's search method (which calls your existing controller logic)
      await plugin.performSearch(query);
    } catch (e) {
      print('Search error: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (var controller in _tabControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
