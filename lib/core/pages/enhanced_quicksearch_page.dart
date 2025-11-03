import 'package:dharak_flutter/app/data/services/supported_languages_service.dart';
import 'package:dharak_flutter/res/values/colors.dart';
import 'package:dharak_flutter/app/domain/verse/constants.dart';
import 'package:dharak_flutter/app/types/unified/unified_response.dart';
import 'package:dharak_flutter/app/types/verse/bookmarks/verse_bookmark.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/controller.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/cubit_states.dart';
import 'dart:async';
import 'package:dharak_flutter/core/components/tool_card.dart';
import 'package:dharak_flutter/core/components/word_definition_card.dart';
import 'package:dharak_flutter/core/components/verse_card.dart';
import 'package:dharak_flutter/app/ui/pages/books/parts/item_lightweight.dart';
import 'package:dharak_flutter/app/ui/sections/books/bookmarks/modal.dart';
import 'package:dharak_flutter/app/ui/sections/books/bookmarks/args.dart';
import 'package:dharak_flutter/app/ui/pages/verses/parts/item.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:dharak_flutter/core/controllers/unified_controller.dart';
import 'package:dharak_flutter/core/controllers/quicksearch_controller.dart';
import 'package:dharak_flutter/core/services/dictionary_service.dart';
import 'package:dharak_flutter/core/services/verse_service.dart';
import 'package:dharak_flutter/core/services/unified_service.dart';
import 'package:dharak_flutter/core/services/books_service.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/layouts/containers.dart';
import 'package:dharak_flutter/res/styles/decorations.dart';
import 'package:dharak_flutter/app/types/dictionary/word_definitions.dart';
import 'package:dharak_flutter/core/components/word_definition_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:provider/provider.dart';
import 'package:dharak_flutter/app/ui/providers/active_section_provider.dart';

enum QuickSearchTab {
  unified,
}

enum QuickSearchMode {
  unified,
  dictionary,
  verse,
  books,
}

extension QuickSearchTabExtension on QuickSearchTab {
  String get label {
    switch (this) {
      case QuickSearchTab.unified:
        return 'Unified';
    }
  }

  IconData get icon {
    switch (this) {
      case QuickSearchTab.unified:
        return Icons.search;
    }
  }

  Color get color {
    switch (this) {
      case QuickSearchTab.unified:
        return const Color(0xFFFF6B35); // Dutch orange for Shodh
    }
  }
}

extension QuickSearchModeExtension on QuickSearchMode {
  String get label {
    switch (this) {
      case QuickSearchMode.unified:
        return 'Shodh (शोध)';
      case QuickSearchMode.dictionary:
        return 'WordDefine';
      case QuickSearchMode.verse:
        return 'QuickVerse';
      case QuickSearchMode.books:
        return 'Books';
    }
  }

  IconData get icon {
    switch (this) {
      case QuickSearchMode.unified:
        return Icons.electric_bolt;
      case QuickSearchMode.dictionary:
        return Icons.local_library_outlined;
      case QuickSearchMode.verse:
        return Icons.keyboard_command_key;
      case QuickSearchMode.books:
        return Icons.menu_book;
    }
  }

  Color get color {
    switch (this) {
      case QuickSearchMode.unified:
        return const Color(0xFFFF6B35); // Dutch orange for Shodh
      case QuickSearchMode.dictionary:
        return const Color(0xFFF9140C); // Red (from unified plugin)
      case QuickSearchMode.verse:
        return const Color(0xFF189565); // Green (from unified plugin)
      case QuickSearchMode.books:
        return Colors.blue; // Blue (from unified plugin)
    }
  }

  String get searchHint {
    switch (this) {
      case QuickSearchMode.unified:
        return 'e.g.\n• Who was the son of Abhimanyu,\n• find verse "agnimede purohitam",\n• Story of dhaumya';
      case QuickSearchMode.dictionary:
        return 'Type a single word to search...';
      case QuickSearchMode.verse:
        return 'Type partial verse to search...';
      case QuickSearchMode.books:
        return 'Enter phrase to search or Ask a question ...';
    }
  }
}

class EnhancedQuickSearchPage extends StatefulWidget {
  const EnhancedQuickSearchPage({Key? key}) : super(key: key);

  @override
  State<EnhancedQuickSearchPage> createState() => _EnhancedQuickSearchPageState();
}

class _EnhancedQuickSearchPageState extends State<EnhancedQuickSearchPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  QuickSearchTab _currentTab = QuickSearchTab.unified;
  QuickSearchMode _currentSearchMode = QuickSearchMode.unified; // Current search mode
  String _currentQuery = '';
  bool _hasTextInSearchField = false; // Track if search field has text
  
  // State preservation for each mode
  final Map<QuickSearchMode, String> _savedQueries = {
    QuickSearchMode.unified: '',
    QuickSearchMode.dictionary: '',
    QuickSearchMode.verse: '',
    QuickSearchMode.books: '',
  };
  
  final Map<QuickSearchMode, bool> _hasSearchedByMode = {
    QuickSearchMode.unified: false,
    QuickSearchMode.dictionary: false,
    QuickSearchMode.verse: false,
    QuickSearchMode.books: false,
  };

  // Language change management
  StreamSubscription<DashboardCubitState>? _languageSubscription;
  String? _previousLanguage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // Only Unified tab
    _tabController.addListener(_handleTabChange);
    
    // Initialize language change listening
    _setupLanguageChangeListener();
    
    // Add listener to track search field text changes for send button color
    _searchController.addListener(() {
      final hasText = _searchController.text.trim().isNotEmpty;
      if (hasText != _hasTextInSearchField) {
        setState(() {
          _hasTextInSearchField = hasText;
        });
      }
    });
    
    // Set initial active section
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<ActiveSectionProvider>(context, listen: false);
        provider.setActiveSection(_currentTab.label.toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    // Save current query before disposing
    if (_searchController.text.isNotEmpty) {
      _savedQueries[_currentSearchMode] = _searchController.text;
    }
    
    _tabController.dispose();
    _searchController.dispose();
    _languageSubscription?.cancel();
    super.dispose();
  }

  /// Setup language change listener for refreshing search results
  void _setupLanguageChangeListener() {
    final dashboardController = Modular.get<DashboardController>();
    _languageSubscription = dashboardController.stream.listen((state) {
      final currentLanguage = state.verseLanguagePref?.output;
      
      // Check if language actually changed
      if (currentLanguage != null && 
          _previousLanguage != null && 
          currentLanguage != _previousLanguage) {
        
        // Language changed
        _handleLanguageChange(currentLanguage);
      }
      
      _previousLanguage = currentLanguage;
    });
    
    // Initialize previous language
    _previousLanguage = dashboardController.state.verseLanguagePref?.output;
  }

  /// Handle language change by refreshing current search results
  void _handleLanguageChange(String newLanguage) async {
    // Use current search controller text or saved query, whichever is available
    final currentSearchText = _searchController.text.trim();
    final savedQuery = _savedQueries[_currentSearchMode] ?? '';
    final queryToUse = currentSearchText.isNotEmpty ? currentSearchText : savedQuery;
    final hasSearched = _hasSearchedByMode[_currentSearchMode] ?? false;
    
    // Language change detected for search mode
    
    // Check if we have searched in this mode OR if we have current results to refresh
    final shouldRefresh = hasSearched && queryToUse.isNotEmpty;
    
    if (shouldRefresh) {
      // Refreshing search for language change
      
      // Don't clear search field focus or change UI state
      // Clear cache first to ensure fresh results
      _clearCacheForMode(_currentSearchMode);
      
      // Add small delay to ensure language preference has propagated
      await Future.delayed(Duration(milliseconds: 150));
      
      // Force new search with same query without affecting UI
      _forceSearchForModeQuietly(_currentSearchMode, queryToUse);
    } else {
      // Skipping refresh - no previous searches to refresh
    }
  }

  /// Clear cache for specific search mode
  void _clearCacheForMode(QuickSearchMode mode) {
    switch (mode) {
      case QuickSearchMode.verse:
        final verseService = VerseService.instance;
        verseService.clearCache();
        break;
      case QuickSearchMode.dictionary:
        final dictionaryService = DictionaryService.instance;
        dictionaryService.clearCache();
        break;
      case QuickSearchMode.unified:
        try {
          final unifiedService = UnifiedService.instance;
          unifiedService.clearCache();
          // Cleared unified cache for language change
        } catch (e) {
          // Error clearing unified cache
        }
        break;
      case QuickSearchMode.books:
        // Books service will handle its own cache
        break;
    }
  }

  /// Force search for specific mode (bypassing restrictions)
  void _forceSearchForMode(QuickSearchMode mode, String query) {
    // Force search for mode called
    
    switch (mode) {
      case QuickSearchMode.unified:
        // Triggering unified search refresh
        final controller = BlocProvider.of<UnifiedController>(context);
        controller.searchUnified(query);
        break;
      case QuickSearchMode.dictionary:
        // Triggering dictionary search refresh
        final controller = BlocProvider.of<QuickSearchController>(context);
        controller.switchSearchType(SearchType.wordDefine);
        controller.forceSearch(query); // Use new forceSearch method
        break;
      case QuickSearchMode.verse:
        // Triggering verse search refresh
        final controller = BlocProvider.of<QuickSearchController>(context);
        controller.switchSearchType(SearchType.quickVerse);
        controller.forceSearch(query); // Use new forceSearch method
        break;
      case QuickSearchMode.books:
        // Triggering books search refresh
        final controller = BlocProvider.of<QuickSearchController>(context);
        controller.switchSearchType(SearchType.books);
        controller.forceSearch(query); // Use new forceSearch method
        break;
    }
    
    // Force search triggered
  }

  /// Force search quietly (for language changes) - doesn't affect UI or focus keyboard
  void _forceSearchForModeQuietly(QuickSearchMode mode, String query) {
    // Force search quietly called
    
    // Don't unfocus or change UI state - use Modular.get for all controllers
    try {
      switch (mode) {
        case QuickSearchMode.unified:
          // Triggering quiet unified search refresh
          final controller = Modular.get<UnifiedController>();
          controller.searchUnified(query);
          break;
        case QuickSearchMode.dictionary:
          // Triggering quiet dictionary search refresh
          final controller = Modular.get<QuickSearchController>();
          controller.switchSearchType(SearchType.wordDefine);
          controller.forceSearch(query);
          break;
        case QuickSearchMode.verse:
          // Triggering quiet verse search refresh
          final controller = Modular.get<QuickSearchController>();
          controller.switchSearchType(SearchType.quickVerse);
          controller.forceSearch(query);
          break;
        case QuickSearchMode.books:
          // Triggering quiet books search refresh
          final controller = Modular.get<QuickSearchController>();
          controller.switchSearchType(SearchType.books);
          controller.forceSearch(query);
          break;
      }
      
      // Quiet force search triggered
    } catch (e) {
      // Error in quiet force search
    }
  }
  
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
        setState(() {
        _currentTab = QuickSearchTab.values[_tabController.index];
      });
      
      // Notify the provider about the active section change
      if (mounted) {
        try {
          final provider = Provider.of<ActiveSectionProvider>(context, listen: false);
          final sectionName = _currentTab.label.toLowerCase();
          // Changing section
          provider.setActiveSection(sectionName);
        } catch (e) {
          // Provider error
        }
      }
    }
  }

  /// Switch to a specific search mode (used by drawer)
  void _switchSearchMode(QuickSearchMode mode) {
    // Save current state before switching
    _savedQueries[_currentSearchMode] = _searchController.text;
    
    setState(() {
      _currentSearchMode = mode;
    });
    
    // Restore the saved query for the new mode
    final savedQuery = _savedQueries[mode] ?? '';
    _searchController.text = savedQuery;
    
    // Update text field state for send button color
    _hasTextInSearchField = savedQuery.isNotEmpty;
    
    // If this mode has been searched before and has a saved query, restore the results
    if (_hasSearchedByMode[mode] == true && savedQuery.isNotEmpty) {
      // Restoring previous results
      _performSearchForMode(mode, savedQuery);
    }
    
    // Update the provider about the active section change
    if (mounted) {
      try {
        final provider = Provider.of<ActiveSectionProvider>(context, listen: false);
        final sectionName = mode.label.toLowerCase().replaceAll(' ', '');
        provider.setActiveSection(sectionName);
      } catch (e) {
        // Handle error silently
      }
    }
  }

  void _clearSearch() {
    // Don't dismiss keyboard when clearing
    _searchController.clear();
    setState(() {
      _hasTextInSearchField = false;
    });
    // Keep the search results and UI state - don't navigate back to welcome
  }

  void _performSearch() {
    
    final query = _searchController.text.trim();
    print("🔍 QUICKSEARCH: Search controller text: '$query'");
    print("🔍 QUICKSEARCH: Query is empty: ${query.isEmpty}");
    
    if (query.isEmpty) {
      print("❌ QUICKSEARCH: Search aborted - query is empty");
      return;
    }

    setState(() {
      _currentQuery = query;
    });

    // Mark that this mode has been searched and save the query
    _hasSearchedByMode[_currentSearchMode] = true;
    _savedQueries[_currentSearchMode] = query;
    
    print("🔍 QUICKSEARCH: Performing search - mode: ${_currentSearchMode.label}, query: '$query'");

    _performSearchForMode(_currentSearchMode, query);
  }
  
  void _performSearchForMode(QuickSearchMode mode, String query) {
    // Mark that this mode has been searched (important for language change detection)
    _hasSearchedByMode[mode] = true;
    _savedQueries[mode] = query;
    
    print("🔍 QUICKSEARCH: _performSearchForMode - mode: ${mode.label}, query: '$query'");
    print("🔍 QUICKSEARCH: Updated _hasSearchedByMode[${mode.label}] = true");
    
    // Call the appropriate search based on current search mode
    try {
      switch (mode) {
        case QuickSearchMode.unified:
          print("🔍 QUICKSEARCH: Getting UnifiedController via Modular");
          final controller = Modular.get<UnifiedController>();
          controller.searchUnified(query, forceRefresh: true);
          break;
        case QuickSearchMode.dictionary:
          print("🔍 QUICKSEARCH: Getting QuickSearchController via Modular for dictionary");
          final controller = Modular.get<QuickSearchController>();
          controller.switchSearchType(SearchType.wordDefine);
          controller.performSearch(query);
          break;
        case QuickSearchMode.verse:
          print("🔍 QUICKSEARCH: Getting QuickSearchController via Modular for verse");
          final controller = Modular.get<QuickSearchController>();
          controller.switchSearchType(SearchType.quickVerse);
          controller.performSearch(query);
          break;
        case QuickSearchMode.books:
          print("🔍 QUICKSEARCH: Getting QuickSearchController via Modular for books");
          final controller = Modular.get<QuickSearchController>();
          controller.switchSearchType(SearchType.books);
          controller.performSearch(query);
          break;
      }
      print("✅ QUICKSEARCH: Search executed successfully for ${mode.label}");
    } catch (e) {
      print("❌ QUICKSEARCH: Error executing search for ${mode.label}: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;

    return MultiBlocProvider(
      providers: [
        BlocProvider<UnifiedController>(
          create: (context) => Modular.get<UnifiedController>(),
        ),
        BlocProvider<QuickSearchController>(
          create: (context) => Modular.get<QuickSearchController>(),
        ),
      ],
        child: _EnhancedQuickSearchContent(
          searchController: _searchController,
          tabController: _tabController,
          currentTab: _currentTab,
          currentSearchMode: _currentSearchMode,
          currentQuery: _currentQuery,
          onTabChanged: () {},
          onPerformSearch: _performSearch,
          onSearchModeChanged: _switchSearchMode,
        ),
    );
  }

  Widget _buildQuickSearchBody(AppThemeColors themeColors) {
    // Check if we have any search results to determine layout
    final hasSearchResults = _hasSearchResults();
    
    if (!hasSearchResults) {
      // Empty state with centered search bar (like Prashna)
      return _buildEmptyState(themeColors);
    } else {
      // Results state with search at bottom (like Prashna with messages)
      return Column(
        children: [
          // Header with hamburger menu
          _buildResultsHeader(themeColors),
          
          // Content area
          Expanded(
            child: _buildTabContent(),
          ),
          
          // Bottom search bar (like Prashna ChatInput)
          _buildBottomSearchBar(themeColors),
        ],
      );
    }
  }

  bool _hasSearchResults() {
    // Check if current search mode has any results
    switch (_currentSearchMode) {
      case QuickSearchMode.unified:
      case QuickSearchMode.dictionary:
      case QuickSearchMode.verse:
      case QuickSearchMode.books:
        // For all modes, check if we've performed a search
        return _currentQuery.isNotEmpty;
    }
  }

  Widget _buildEmptyState(AppThemeColors themeColors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Welcome Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _currentSearchMode.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _currentSearchMode.icon,
              size: 48,
              color: _currentSearchMode.color,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Welcome Title
          Text(
            _getWelcomeTitle(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: themeColors.onSurface, // Theme-aware text color
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Welcome Subtitle (Prashna style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: 16,
                color: themeColors.onSurface, // Theme-aware text color
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Centered Search Bar (Prashna style)
          _buildCenteredSearchBar(themeColors),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(AppThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: themeColors.surface,
        boxShadow: [
          BoxShadow(
            color: themeColors.onSurface.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hamburger menu button
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: Icon(
              Icons.menu,
              color: _currentSearchMode.color,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Mode title
          Expanded(
            child: Text(
              '${_currentSearchMode.label} Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeColors.onSurface,
              ),
            ),
          ),
          
          // Dropdown menu
          _buildDropdownMenu(themeColors),
        ],
      ),
    );
  }

  Widget _buildCenteredSearchBar(AppThemeColors themeColors) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 56,
        maxHeight: 160,
      ),
              decoration: BoxDecoration(
        color: themeColors.surface,
        borderRadius: BorderRadius.circular(28),
                border: Border.all(
          color: _getSendButtonColor(),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _currentSearchMode.color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: themeColors.onSurface.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text Input
          Expanded(
      child: TextField(
        controller: _searchController,
              onSubmitted: (_) => _performSearch(),
              maxLines: null,
        decoration: InputDecoration(
                  hintText: _getSearchHint(),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400, // Light grey placeholder
                  fontSize: 12, // Smaller to prevent overflow
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: InputBorder.none,
                suffixIcon: _hasTextInSearchField
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        onPressed: _clearSearch,
                        tooltip: 'Clear text',
                      )
                    : null,
              ),
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: themeColors.onSurface,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          
          // Send Button
          Padding(
                      padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: _performSearch,
              child: Container(
                width: 40,
                height: 40,
                      decoration: BoxDecoration(
                  color: _getSendButtonColor(),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getSendButtonColor().withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                      ),
                      child: Icon(
                        Icons.send,
                        color: themeColors.surface,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSearchBar(AppThemeColors themeColors) {
    return Container(
      decoration: BoxDecoration(
        color: themeColors.surface,
        border: Border(
          top: BorderSide(
            color: _currentSearchMode.color.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text Input
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    maxHeight: 160,
                  ),
                  decoration: BoxDecoration(
                    color: themeColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _currentSearchMode.color,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _currentSearchMode.color.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _performSearch(),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: _getSearchHint(),
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400, // Light grey placeholder
                        fontSize: 11, // Even smaller for compact variant
                  ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                  border: InputBorder.none,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: themeColors.onSurface,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send Button
              GestureDetector(
                onTap: _performSearch,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getSendButtonColor(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getSendButtonColor().withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), // More compact vertical padding
      decoration: BoxDecoration(
        color: themeColors.surface,
        boxShadow: [
          BoxShadow(
            color: themeColors.onSurface.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search bar (Prashna style)
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 48,
                maxHeight: 120,
              ),
              decoration: BoxDecoration(
                color: themeColors.surface,
                borderRadius: BorderRadius.circular(24), // More rounded like Prashna
                border: Border.all(
                  color: _currentSearchMode.color, // Mode-specific color for QuickSearch
                  width: 2, // Thicker border like Prashna
                ),
                boxShadow: [
                  BoxShadow(
                    color: _currentSearchMode.color.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _performSearch(),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: _getSearchHint(),
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400, // Light grey placeholder
                    fontSize: 11, // Smaller hint text to prevent overflow
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: themeColors.onSurface,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send Button (Prashna style)
          GestureDetector(
            onTap: _performSearch,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _currentSearchMode.color, // Mode-specific color
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _currentSearchMode.color.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 8),

          // Dropdown menu
          _buildDropdownMenu(themeColors),
        ],
      ),
    );
  }

  Widget _buildDropdownMenu(AppThemeColors themeColors) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeColors.onSurface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.more_vert,
          color: themeColors.onSurface.withOpacity(0.7),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'words',
          child: Row(
            children: [
              const Icon(Icons.book_outlined),
              const SizedBox(width: 12),
              Text('Words (Legacy)', style: TdResTextStyles.p2),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'verses',
          child: Row(
            children: [
              const Icon(Icons.keyboard_command_key),
              const SizedBox(width: 12),
              Text('Verses (Legacy)', style: TdResTextStyles.p2),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'bookmarks',
          child: Row(
            children: [
              const Icon(Icons.bookmark_outline),
              const SizedBox(width: 12),
              Text('Bookmarks', style: TdResTextStyles.p2),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'words':
            Modular.to.pushNamed('/word-define');
            break;
          case 'verses':
            Modular.to.pushNamed('/verses');
            break;
          case 'bookmarks':
            // TODO: Navigate to bookmarks
            break;
        }
      },
    );
  }

  Widget _buildTabBar(AppThemeColors themeColors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // More compact vertical margin
      decoration: BoxDecoration(
        color: themeColors.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: _currentTab.color,
        ),
        labelColor: themeColors.surface,
        unselectedLabelColor: themeColors.onSurface.withOpacity(0.6),
        labelStyle: TdResTextStyles.p2.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TdResTextStyles.p2.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        tabs: QuickSearchTab.values.map((tab) => Tab(
          icon: Icon(tab.icon, size: 14), // Even smaller icons
          text: tab.label,
          height: 32, // Compact tab height that works well with padding
        )).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
          children: [
        // Unified tab
        BlocProvider(
          create: (_) => Modular.get<UnifiedController>(),
          child: _buildUnifiedContent(),
        ),
        
        // Dictionary tab
        _buildComingSoonContent('Dictionary Search', Icons.local_library_outlined, const Color(0xFFF9140C)),
        
        // Verse tab
        _buildComingSoonContent('Verse Search', Icons.keyboard_command_key, const Color(0xFF189565)),
        
        // Books tab
        _buildComingSoonContent('Books Search', Icons.menu_book, Colors.blue),
      ],
    );
  }

  Widget _buildUnifiedContent() {
    return BlocBuilder<UnifiedController, UnifiedState>(
      builder: (context, state) {
        if (state.searchResults.isEmpty && !state.isLoading) {
          return _buildEmptySearchState('Unified Search', 'Start searching across all content', Icons.search);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16), // More spacious padding
          itemCount: state.searchResults.length,
          itemBuilder: (context, index) {
            final result = state.searchResults[index];
            final controller = BlocProvider.of<UnifiedController>(context);
            final tools = controller.getExpandableTools(result);

            return Column(
              children: [
                // Tool cards for each available tool type
                ...tools.map((toolType) => ToolCard(
                  result: result,
                  toolType: toolType,
                  themeColors: Theme.of(context).extension<AppThemeColors>()!,
                  isGreyedOut: _shouldGreyOutResult(result, state.searchResults),
                  onCopy: (text) => _handleCopy(text),
                  onShare: (text) => _handleShare(text),
                  onReferenceClick: (reference) => _handleReferenceClick(reference),
                )).toList(),

                if (index < state.searchResults.length - 1)
                  const SizedBox(height: 16), // More spacious results
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptySearchState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _currentSearchMode.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              icon,
              size: 40,
              color: _currentSearchMode.color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _currentSearchMode.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonContent(String title, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              icon,
              size: 40,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TdResTextStyles.h3.copyWith(
              color: Theme.of(context).extension<AppThemeColors>()!.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon!',
            style: TdResTextStyles.p2.copyWith(
              color: Theme.of(context).extension<AppThemeColors>()!.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              _tabController.animateTo(0); // Go back to Unified
            },
            child: Text(
              'Try Unified Search',
              style: TdResTextStyles.p2.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }


  String _getSearchHint() {
    return _currentSearchMode.searchHint;
  }
  
  /// Get send button color - grey when empty, mode color when has text
  Color _getSendButtonColor() {
    if (_hasTextInSearchField) {
      return _currentSearchMode.color;
    } else {
      return Colors.grey.shade400; // Light grey when no text
    }
  }

  String _getWelcomeTitle() {
    switch (_currentSearchMode) {
      case QuickSearchMode.unified:
        return 'Welcome to Shodh';
      case QuickSearchMode.dictionary:
        return 'Welcome to WordDefine';
      case QuickSearchMode.verse:
        return 'Welcome to QuickVerse';
      case QuickSearchMode.books:
        return 'Welcome to Books';
    }
  }

  String _getEmptyStateMessage() {
    switch (_currentSearchMode) {
      case QuickSearchMode.unified:
        return 'Ask a question or enter a phrase to search the world of Indic Knowledge';
      case QuickSearchMode.dictionary:
        return 'Explore names, words, places or concepts. Enter a single word & discover the world of Indic Knowledge with our smart AI word lookup.';
      case QuickSearchMode.verse:
        return 'Do you have a shloka, mantra, verse or a kriti humming in your mind? Search for it here. Just enter the parts you remember to get started!';
      case QuickSearchMode.books:
        return 'Dive deep into sacred texts and spiritual literature. Search through chapters, find specific passages, or explore the vast library of Indic wisdom.';
    }
  }

  Color _getBackgroundColor(AppThemeColors themeColors) {
    // Use theme-aware background color
    return themeColors.surface;
  }

  bool _shouldGreyOutResult(UnifiedSearchResult result, List<UnifiedSearchResult> allResults) {
    if (allResults.isEmpty) return false;
    
    final sessionIds = allResults.map((r) => r.searchSessionId);
    final mostRecentSessionId = sessionIds.reduce((a, b) => a > b ? a : b);
    
    return result.searchSessionId < mostRecentSessionId;
  }

  void _handleCopy(String text) {
    // TODO: Implement copy functionality
  }

  void _handleShare(String text) {
    // TODO: Implement share functionality
  }

  void _handleReferenceClick(String reference) {
    _launchQuickSearchExternalUrl(reference);
  }
  
  void _launchQuickSearchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening source link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _EnhancedQuickSearchContent extends StatefulWidget {
  final TextEditingController searchController;
  final TabController tabController;
  final QuickSearchTab currentTab;
  final QuickSearchMode currentSearchMode; // Add search mode
  final String currentQuery;
  final VoidCallback onTabChanged;
  final VoidCallback onPerformSearch;
  final Function(QuickSearchMode) onSearchModeChanged; // Add callback for search mode changes
  final VoidCallback? onClearSearch; // Add callback for clearing search

  const _EnhancedQuickSearchContent({
    required this.searchController,
    required this.tabController,
    required this.currentTab,
    required this.currentSearchMode,
    required this.currentQuery,
    required this.onTabChanged,
    required this.onPerformSearch,
    required this.onSearchModeChanged,
    this.onClearSearch,
  });

  @override
  State<_EnhancedQuickSearchContent> createState() => _EnhancedQuickSearchContentState();
}

class _EnhancedQuickSearchContentState extends State<_EnhancedQuickSearchContent> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearching = false;
  UnifiedState? _currentUnifiedState;

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: _getBackgroundColor(themeColors),
        appBar: _buildAppBar(themeColors), // Add AppBar like Prashna
        drawer: _buildQuickSearchDrawer(themeColors), // Add drawer while keeping existing functionality
        body: SafeArea(
          child: BlocBuilder<UnifiedController, UnifiedState>(
            builder: (context, unifiedState) {
              _currentUnifiedState = unifiedState; // Store current state for _hasSearchResults
              return BlocBuilder<QuickSearchController, QuickSearchState>(
                builder: (context, quickSearchState) {
                  return _buildQuickSearchBody(themeColors);
                },
              );
            },
          ),
        ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppThemeColors themeColors) {
    return AppBar(
      backgroundColor: Color.alphaBlend(
        widget.currentSearchMode.color.withAlpha(0x02),
        themeColors.surface,
      ),
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(
        color: widget.currentSearchMode.color, // This controls the hamburger icon color
      ),
      title: Row(
        children: [
          // Shodh logo/badge - flexible
          Flexible(
            flex: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.currentSearchMode.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.currentSearchMode.icon,
                    size: 16,
                    color: widget.currentSearchMode.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.currentSearchMode.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.currentSearchMode.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_hasSearchResults()) ...[
            const SizedBox(width: 8),
            // Dynamic title based on search - takes remaining space
            Expanded(
              child: Text(
                _getSearchQuery(),
                style: TextStyle(
                  fontSize: 13,
                  color: themeColors.onSurfaceMedium,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
      actions: [
        // Show Clear Screen Button only for unified mode, more_vert menu for others
        if (widget.currentSearchMode == QuickSearchMode.unified)
          IconButton(
            onPressed: () {
              _clearSearchAndReturnToWelcome();
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.currentSearchMode.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.clear_all,
                size: 20,
                color: themeColors.surface,
              ),
            ),
            tooltip: 'Clear Screen',
          )
        else
          PopupMenuButton<String>(
            onSelected: _handleBookmarkAction,
            icon: Icon(
              Icons.more_vert,
              color: widget.currentSearchMode.color,
            ),
            color: Theme.of(context).cardColor,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) {
              return _getMenuItemsForMode(widget.currentSearchMode);
            },
          ),
      ],
    );
  }

  String _getSearchQuery() {
    // Get the current search query to display in the header
    return widget.searchController.text.isNotEmpty 
        ? widget.searchController.text 
        : 'Search Results';
  }

  List<PopupMenuEntry<String>> _getMenuItemsForMode(QuickSearchMode mode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    switch (mode) {
      case QuickSearchMode.dictionary:
        return [
          PopupMenuItem<String>(
            value: 'word_history',
            child: Row(
              children: [
                Icon(Icons.history, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text('Word History', style: TextStyle(color: textColor)),
              ],
            ),
          ),
        ];
      case QuickSearchMode.verse:
        return [
          PopupMenuItem<String>(
            value: 'verse_history',
            child: Row(
              children: [
                Icon(Icons.history, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text('Verse History', style: TextStyle(color: textColor)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'saved_verses',
            child: Row(
              children: [
                Icon(Icons.bookmark, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text('Saved Verses', style: TextStyle(color: textColor)),
              ],
            ),
          ),
        ];
      case QuickSearchMode.books:
        return [
          PopupMenuItem<String>(
            value: 'saved_chapters',
            child: Row(
              children: [
                Icon(Icons.bookmark, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text('Bookmarks', style: TextStyle(color: textColor)),
              ],
            ),
          ),
        ];
      case QuickSearchMode.unified:
      default:
        return []; // Unified mode uses clear screen button instead
    }
  }

  void _clearSearchAndReturnToWelcome() {
    // Clear search text
    widget.searchController.clear();
    
    // Clear all search results based on current mode
    switch (widget.currentSearchMode) {
      case QuickSearchMode.unified:
        Modular.get<UnifiedController>().clearAllResults();
        break;
      case QuickSearchMode.dictionary:
      case QuickSearchMode.verse:
      case QuickSearchMode.books:
        Modular.get<QuickSearchController>().clearSearch();
        break;
    }
    
    // Update state to refresh UI
    setState(() {});
  }

  Widget _buildQuickSearchBody(AppThemeColors themeColors) {
    // Check if we have any search results to determine layout
    final hasSearchResults = _hasSearchResults();
    
    if (!hasSearchResults) {
      // Empty state with centered search bar (like Prashna)
      return _buildEmptyState(themeColors);
    } else {
      // Results state with search at bottom (like Prashna with messages)
      return Column(
        children: [
          // Content area (AppBar now handles the header)
          Expanded(
            child: _buildTabContent(),
          ),
          
          // Bottom search bar (like Prashna ChatInput)
          _buildBottomSearchBar(themeColors),
        ],
      );
    }
  }

  bool _hasPerformedSearchInCurrentMode() {
    // Check if we have any search results stored for the current mode
    try {
      switch (widget.currentSearchMode) {
        case QuickSearchMode.unified:
          final state = BlocProvider.of<UnifiedController>(context, listen: false).state;
          return state.searchResults.isNotEmpty;
        case QuickSearchMode.dictionary:
          final state = BlocProvider.of<QuickSearchController>(context, listen: false).state;
          return state.wordDefineResult != null;
        case QuickSearchMode.verse:
          final state = BlocProvider.of<QuickSearchController>(context, listen: false).state;
          return state.verseResults.isNotEmpty;
        case QuickSearchMode.books:
          final state = BlocProvider.of<QuickSearchController>(context, listen: false).state;
          return state.bookResults.isNotEmpty;
      }
    } catch (e) {
      print('⚠️ Error checking search history: $e');
      return false;
    }
  }

  bool _hasSearchResults() {
    // Don't immediately show welcome state when text is cleared
    // Only show welcome state when user hasn't performed any searches yet
    final query = widget.searchController.text.trim();
    
    // If we have text, continue with normal checks
    if (query.isNotEmpty) {
      // Continue with existing logic...
    } else {
      // If text is empty, check if we've performed searches in this mode before
      final hasPerformedSearches = _hasPerformedSearchInCurrentMode();
      if (hasPerformedSearches) {
        print('🔍 Text cleared but keeping results state');
        return true; // Keep showing results state, not welcome
      } else {
        print('🔍 No search query and no previous searches, showing welcome state');
        return false;
      }
    }
    
    // Check if current search mode has any results
    try {
      switch (widget.currentSearchMode) {
        case QuickSearchMode.unified:
          // CRITICAL FIX: Check if we're inside a BlocBuilder and can access the current state
          if (_currentUnifiedState != null) {
            final hasResults = _currentUnifiedState!.searchResults.isNotEmpty;
            print('🔍 Unified mode - query: "$query", hasResults: $hasResults, resultsCount: ${_currentUnifiedState!.searchResults.length}');
            print('🔍 UnifiedState searchCounter: ${_currentUnifiedState!.searchCounter}');
            return hasResults;
          } else {
            // Fallback to Modular.get
            final unifiedController = Modular.get<UnifiedController>();
            final hasResults = unifiedController.state.searchResults.isNotEmpty;
            print('🔍 Unified mode (fallback) - query: "$query", hasResults: $hasResults, resultsCount: ${unifiedController.state.searchResults.length}');
            return hasResults;
          }
        case QuickSearchMode.dictionary:
          final quickSearchController = Modular.get<QuickSearchController>();
          final hasResults = quickSearchController.state.wordDefineResult != null;
          print('🔍 Dictionary mode - query: "$query", hasResults: $hasResults');
          return hasResults;
        case QuickSearchMode.verse:
          final quickSearchController = Modular.get<QuickSearchController>();
          final hasResults = quickSearchController.state.verseResults.isNotEmpty;
          print('🔍 Verse mode - query: "$query", hasResults: $hasResults');
          return hasResults;
        case QuickSearchMode.books:
          final quickSearchController = Modular.get<QuickSearchController>();
          final hasResults = quickSearchController.state.bookResults.isNotEmpty;
          print('🔍 Books mode - query: "$query", hasResults: $hasResults');
          return hasResults;
      }
    } catch (e) {
      print('🔍 Error checking results: $e');
      // If controllers aren't available yet, default to false
      return false;
    }
  }

  Widget _buildEmptyState(AppThemeColors themeColors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Mode-specific icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.currentSearchMode.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.currentSearchMode.icon,
              size: 48,
              color: widget.currentSearchMode.color,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Welcome Title
          Text(
            _getWelcomeTitle(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: themeColors.onSurface, // Theme-aware text color
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Welcome Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: 16,
                color: themeColors.onSurface, // Theme-aware text color
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Centered Search Bar
          _buildCenteredSearchBar(themeColors),
        ],
      ),
    );
  }

  Widget _buildCenteredSearchBar(AppThemeColors themeColors) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(
          maxWidth: 400,
          minHeight: 56,
          maxHeight: 160,
        ),
        decoration: BoxDecoration(
          color: themeColors.surface,
          borderRadius: BorderRadius.circular(28), // More rounded for centered
          border: Border.all(
            color: _getSendButtonColor(),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.currentSearchMode.color.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: themeColors.onSurface.withOpacity(0.08),
              blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: TextField(
              controller: widget.searchController,
              decoration: InputDecoration(
                hintText: _getSearchHint(),
                hintStyle: TextStyle(
                  color: themeColors.onSurfaceDisable ?? Colors.grey.shade500,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: themeColors.onSurface,
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (query) => _performSearch(),
            ),
          ),
          
          // Send button (Prashna style)
          Container(
            margin: const EdgeInsets.all(8),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getSendButtonColor(),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getSendButtonColor().withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => _performSearch(),
              icon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildResultsHeader(AppThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      decoration: BoxDecoration(
        color: themeColors.surface,
        boxShadow: [
          BoxShadow(
            color: widget.currentSearchMode.color.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hamburger menu button
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: Icon(
              Icons.menu,
              color: widget.currentSearchMode.color,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Mode title with icon
          Expanded(
            child: Row(
              children: [
                Icon(
                  widget.currentSearchMode.icon,
                  color: widget.currentSearchMode.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.currentSearchMode.label} Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.currentSearchMode.color,
                  ),
                ),
              ],
            ),
          ),
          
          // Dropdown menu
          _buildDropdownMenu(themeColors),
        ],
      ),
    );
  }

  Widget _buildBottomSearchBar(AppThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColors.surface,
        boxShadow: [
          BoxShadow(
            color: widget.currentSearchMode.color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
            child: Container(
        constraints: const BoxConstraints(
          minHeight: 48,
          maxHeight: 80, // Much smaller height for bottom bar like Prashna
        ),
              decoration: BoxDecoration(
          color: themeColors.surface,
          borderRadius: BorderRadius.circular(24),
                border: Border.all(
            color: widget.currentSearchMode.color,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.currentSearchMode.color.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Text field
            Expanded(
              child: TextField(
                controller: widget.searchController,
                decoration: InputDecoration(
                  hintText: 'Ask another question...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8, // Much less padding for bottom bar
                  ),
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                  ),
                ),
                style: const TextStyle(fontSize: 15),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (query) => _performSearch(),
              ),
            ),
            
            // Send button
            Container(
              margin: const EdgeInsets.all(6),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.currentSearchMode.color,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                onPressed: () => _performSearch(),
                icon: Icon(
                        Icons.send,
                        color: themeColors.surface,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2), // Ultra compact vertical padding
      decoration: BoxDecoration(
        color: themeColors.surface,
        boxShadow: [
          BoxShadow(
            color: widget.currentSearchMode.color.withOpacity(0.1), // Mode-tinted shadow
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hamburger menu button
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: Icon(
              Icons.menu,
              color: widget.currentSearchMode.color,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Search bar (Enhanced Prashna style)
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 48,
                maxHeight: 120,
              ),
              decoration: BoxDecoration(
                color: themeColors.surface,
                borderRadius: BorderRadius.circular(24), // More rounded like Prashna
                border: Border.all(
                  color: widget.currentSearchMode.color, // Use mode-specific color
                  width: 2, // Thicker border like Prashna
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.currentSearchMode.color.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: themeColors.onSurface.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: widget.searchController,
                onSubmitted: (_) => _performSearch(),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: _getSearchHint(),
                  hintStyle: TextStyle(
                    color: themeColors.onSurfaceDisable ?? Colors.grey.shade500,
                    fontSize: 14, // Better readability like Prashna
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, // More padding like Prashna
                    vertical: 14,
                  ),
                ),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: themeColors.onSurface,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send Button (Prashna style)
          GestureDetector(
            onTap: _performSearch,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.currentSearchMode.color, // Mode-specific color
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.currentSearchMode.color.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkButton(AppThemeColors themeColors) {
    return Container(
      decoration: BoxDecoration(
        color: themeColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: themeColors.onSurface.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.bookmark_outline,
          color: themeColors.onSurface.withOpacity(0.7),
          size: 20,
        ),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        onSelected: (String value) {
          _handleBookmarkAction(value);
        },
        itemBuilder: (BuildContext context) {
          return _getBookmarkMenuItems();
        },
      ),
    );
  }

  List<PopupMenuEntry<String>> _getBookmarkMenuItems() {
    final List<PopupMenuEntry<String>> items = [];
    
    switch (widget.currentTab) {
      case QuickSearchTab.unified:
        items.addAll([
          const PopupMenuItem<String>(
            value: 'unified_history',
            child: Row(
              children: [
                Icon(Icons.history, size: 18),
                SizedBox(width: 8),
                Text('Search History'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'all_bookmarks',
            child: Row(
              children: [
                Icon(Icons.bookmarks, size: 18),
                SizedBox(width: 8),
                Text('All Bookmarks'),
              ],
            ),
          ),
        ]);
        break;
    }
    
    return items;
  }

  void _handleBookmarkAction(String action) {
    switch (action) {
      case 'word_history':
        _showWordHistory();
        break;
      case 'verse_history':
        _showVerseHistory();
        break;
      case 'saved_verses':
        _showSavedVerses();
        break;
      case 'saved_chapters':
        _showBookmarkedChapters();
        break;
    }
  }

  // Bookmark/History functionality implementations
  void _showUnifiedHistory() async {
    await _showHistoryBottomSheet(['All Search History'], []);
  }

  void _showAllBookmarks() async {
    await _showBookmarksBottomSheet('All Bookmarks', []);
  }

  void _showWordHistory() async {
    try {
      final dictionaryService = Modular.get<DictionaryService>();
      final historyResult = await dictionaryService.getSearchHistory();
      
      if (historyResult != null && historyResult.history.isNotEmpty) {
        await _showHistoryBottomSheet(historyResult.history, ['word']);
      } else {
        _showEmptyHistorySnackbar('Word History');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to load word history');
    }
  }

  void _showSavedWords() {
    // Dictionary doesn't have bookmarks API yet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Word bookmarks not available in API yet')),
    );
  }

  void _showVerseHistory() async {
    try {
      final verseService = Modular.get<VerseService>();
      final historyResult = await verseService.getSearchHistory();
      
      if (historyResult != null && historyResult.history.isNotEmpty) {
        await _showHistoryBottomSheet(historyResult.history, ['verse']);
      } else {
        _showEmptyHistorySnackbar('Verse History');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to load verse history');
    }
  }

  void _showSavedVerses() async {
    try {
      final verseService = Modular.get<VerseService>();
      final bookmarksResult = await verseService.getBookmarks();
      
      if (bookmarksResult != null && bookmarksResult.verse.isNotEmpty) {
        await _showBookmarksBottomSheet(
          'Saved Verses (${bookmarksResult.verse.length})',
          bookmarksResult.verse,
        );
      } else {
        _showEmptyBookmarksSnackbar('Saved Verses');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to load saved verses');
    }
  }

  void _showBooksHistory() {
    // Books history not implemented in API yet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Books history not available in API yet')),
    );
  }

  void _showBookChunkBookmarks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookChunkBookmarksModal(
        mRequestArgs: BookChunkBookmarksArgsRequest(),
      ),
    );
  }

  void _showBookmarkedChapters() async {
    // Use the existing books bookmarks modal
    final args = BookChunkBookmarksArgsRequest();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => BookChunkBookmarksModal(
          mRequestArgs: args,
        ),
      ),
    );
  }

  void _showEmptyHistorySnackbar(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No $type found')),
    );
  }

  Future<void> _showHistoryBottomSheet(List<String> history, List<String> types) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade600 
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                '${types.first.toUpperCase()} History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              
              // History list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: Theme.of(context).cardColor,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          Icons.history,
                          color: widget.currentSearchMode.color,
                        ),
                        title: Text(
                          history[index],
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          widget.searchController.text = history[index];
                          widget.onPerformSearch();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmptyBookmarksSnackbar(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No $type found')),
    );
  }

  Future<void> _showBookmarksBottomSheet(String title, List<VerseBookmarkRM> bookmarks) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade600 
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              
              // Bookmarks list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    return Card(
                      color: Theme.of(context).cardColor,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          Icons.bookmark,
                          color: widget.currentSearchMode.color,
                        ),
                        title: Text(
                          bookmark.text ?? 'No text',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          bookmark.key ?? '',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // Handle bookmark tap - could navigate to verse details
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).extension<AppThemeColors>()!.errorColor,
      ),
    );
  }



  // Helper methods for the VerseItemWidget callbacks in QuickSearch
  void _handleQuickSearchCopy(String message) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text copied to clipboard!'),
      ),
    );
  }

  void _launchQuickSearchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening source link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getSearchHint() {
    return widget.currentSearchMode.searchHint;
  }

  String _getWelcomeTitle() {
    switch (widget.currentSearchMode) {
      case QuickSearchMode.unified:
        return 'Welcome to Shodh';
      case QuickSearchMode.dictionary:
        return 'Welcome to WORDefine';
      case QuickSearchMode.verse:
        return 'Welcome to QuickVerse';
      case QuickSearchMode.books:
        return 'Welcome to Books';
    }
  }

  String _getEmptyStateMessage() {
    switch (widget.currentSearchMode) {
      case QuickSearchMode.unified:
        return 'Ask a question or enter a phrase to search the world of Indic Knowledge';
      case QuickSearchMode.dictionary:
        return 'Explore names, words, places or concepts. Enter a single word & discover the world of Indic Knowledge with our smart AI word lookup.';
      case QuickSearchMode.verse:
        return 'Do you have a shloka, mantra, verse or a kriti humming in your mind? Search for it here. Just enter the parts you remember to get started!';
      case QuickSearchMode.books:
        return 'Ask a question or enter a phrase to search the world of Indic Knowledge';
    }
  }

  Color _getSendButtonColor() {
    // For the content state, we'll check if search controller has text
    if (widget.searchController.text.trim().isNotEmpty) {
      return widget.currentSearchMode.color;
    } else {
      return Colors.grey.shade400;
    }
  }

  Color _getBackgroundColor(AppThemeColors themeColors) {
    // Use theme-aware background color
    return themeColors.surface;
  }

  void _performSearch() {
    print("🔍 CONTENT: _performSearch() called in content widget!");
    
    final query = widget.searchController.text.trim();
    print("🔍 CONTENT: Search controller text: '$query'");
    print("🔍 CONTENT: Query is empty: ${query.isEmpty}");
    print("🔍 CONTENT: Is searching: $_isSearching");
    
    if (query.isEmpty) {
      print("❌ CONTENT: Search aborted - query is empty");
      return;
    }

    // Reset the search flag if it's stuck from a previous search
    if (_isSearching) {
      print("⚠️ CONTENT: _isSearching was true, resetting to false");
      _isSearching = false;
    }

    _isSearching = true;
    print('🔍 CONTENT: Performing ${widget.currentSearchMode.label} search: "$query"');
    
    // Notify parent about the search (IMPORTANT for tracking)
    widget.onPerformSearch();
    
    // Reset the search flag after a short delay to prevent multiple rapid searches
    Future.delayed(const Duration(milliseconds: 300), () {
      _isSearching = false;
      print("🔍 CONTENT: Search flag reset - ready for next search");
    });

    // Call the appropriate search based on current search mode
    try {
      switch (widget.currentSearchMode) {
        case QuickSearchMode.unified:
          print("🔍 CONTENT: Calling UnifiedController.searchUnified via Modular");
          final controller = Modular.get<UnifiedController>();
          controller.searchUnified(query, forceRefresh: true);
          break;
        case QuickSearchMode.dictionary:
          print("🔍 CONTENT: Calling QuickSearchController.performSearch for dictionary via Modular");
          final controller = Modular.get<QuickSearchController>();
          controller.switchSearchType(SearchType.wordDefine);
          controller.performSearch(query);
          break;
        case QuickSearchMode.verse:
          print("🔍 CONTENT: Calling QuickSearchController.performSearch for verse via Modular");
          final controller = Modular.get<QuickSearchController>();
          controller.switchSearchType(SearchType.quickVerse);
          controller.performSearch(query);
          break;
        case QuickSearchMode.books:
          print("🔍 CONTENT: Calling QuickSearchController.performSearch for books via Modular");
          final controller = Modular.get<QuickSearchController>();
          controller.switchSearchType(SearchType.books);
          controller.performSearch(query);
          break;
      }
      print("✅ CONTENT: Search executed successfully for ${widget.currentSearchMode.label}");
    } catch (e) {
      print("❌ CONTENT: Error executing search for ${widget.currentSearchMode.label}: $e");
    }
  }

  Widget _buildDropdownMenu(AppThemeColors themeColors) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: widget.currentSearchMode.color,
      ),
      itemBuilder: (context) => _getDropdownMenuItems(),
      onSelected: (value) => _handleDropdownSelection(value),
    );
  }

  List<PopupMenuEntry<String>> _getDropdownMenuItems() {
    switch (widget.currentSearchMode) {
      case QuickSearchMode.unified:
        // Keep empty for now as requested
        return [];
        
      case QuickSearchMode.dictionary:
        return [
        const PopupMenuItem(
            value: 'history',
            child: Text('History'),
        ),
        ];
        
      case QuickSearchMode.verse:
        return [
        const PopupMenuItem(
            value: 'history',
            child: Text('History'),
        ),
        const PopupMenuItem(
          value: 'bookmarks',
          child: Text('Bookmarks'),
        ),
        ];
        
      case QuickSearchMode.books:
        return [
          const PopupMenuItem(
            value: 'bookmarks',
            child: Row(
              children: [
                Icon(Icons.bookmarks, size: 20),
                SizedBox(width: 12),
                Text('My Bookmarks'),
              ],
            ),
          ),
        ];
    }
  }

  void _handleDropdownSelection(String value) {
        switch (value) {
      case 'history':
        if (widget.currentSearchMode == QuickSearchMode.dictionary) {
          _showWordHistory();
        } else if (widget.currentSearchMode == QuickSearchMode.verse) {
          _showVerseHistory();
        }
            break;
          case 'bookmarks':
        if (widget.currentSearchMode == QuickSearchMode.verse) {
          _showSavedVerses();
        } else if (widget.currentSearchMode == QuickSearchMode.books) {
          _showBookChunkBookmarks();
        }
            break;
        }
  }

  void _copyAllDefinitions(DictWordDefinitionsRM wordDefineResult) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Word: ${wordDefineResult.givenWord}');
    buffer.writeln();
    
    for (int i = 0; i < wordDefineResult.details.definitions.length; i++) {
      final definition = wordDefineResult.details.definitions[i];
      buffer.writeln('Definition ${i + 1}:');
      buffer.writeln(definition.text);
      buffer.writeln();
    }
    
    _handleCopy(buffer.toString());
  }

  void _launchExternalUrl(String? urlLink) {
    if (urlLink != null) {
      _launchQuickSearchExternalUrl(urlLink);
    }
  }


  Widget _buildTabBar(AppThemeColors themeColors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.all(4), // Add internal padding for better indicator spacing
      decoration: BoxDecoration(
        color: themeColors.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: widget.tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: widget.currentTab.color,
        ),
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.05), // More vertical padding for better spacing
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: themeColors.surface,
        unselectedLabelColor: themeColors.onSurface.withOpacity(0.6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        dividerColor: Colors.transparent,
        labelStyle: TdResTextStyles.p2.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TdResTextStyles.p2.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        tabs: QuickSearchTab.values.map((tab) => Tab(
          icon: Icon(tab.icon, size: 14), // Even smaller icons
          text: tab.label,
          height: 32, // Compact tab height that works well with padding
        )).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    // Show content based on search mode instead of tabs
    switch (widget.currentSearchMode) {
      case QuickSearchMode.unified:
        return _buildUnifiedContent();
      case QuickSearchMode.dictionary:
        return _buildDictionaryContent();
      case QuickSearchMode.verse:
        return _buildVerseContent();
      case QuickSearchMode.books:
        return _buildBooksContent();
    }
  }

  Widget _buildUnifiedContent() {
    return BlocBuilder<UnifiedController, UnifiedState>(
      builder: (context, state) {
        if (state.searchResults.isEmpty && !state.isLoading) {
          return const Center(
            child: Text(
              'Start your unified search above',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // Separate current and previous results
        final sessionIds = state.searchResults.map((r) => r.searchSessionId);
        final mostRecentSessionId = sessionIds.isNotEmpty 
            ? sessionIds.reduce((a, b) => a > b ? a : b) 
            : 0;
        
        final currentResults = state.searchResults
            .where((result) => result.searchSessionId == mostRecentSessionId)
            .toList();
        
        final previousResults = state.searchResults
            .where((result) => result.searchSessionId < mostRecentSessionId)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current Search Results Section
            if (currentResults.isNotEmpty) ...[
              _buildUnifiedSectionHeader('Current Search', Icons.search, currentResults.length),
              const SizedBox(height: 8),
              ...currentResults.map((result) => _buildUnifiedResultItem(result, false)),
            ],
            
            // Previous Searches Section (Expandable)
            if (previousResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildUnifiedPreviousSearchesSection(previousResults),
            ],
          ],
        );
      },
    );
  }

  Widget _buildUnifiedSectionHeader(String title, IconData icon, int count) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: themeColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TdResTextStyles.h6.copyWith(
              color: themeColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: themeColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TdResTextStyles.caption.copyWith(
                color: themeColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedPreviousSearchesSection(List<UnifiedSearchResult> previousResults) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent, // Remove expansion tile divider
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.only(top: 8),
        leading: Icon(
          Icons.history,
          size: 16,
          color: themeColors.onSurface.withOpacity(0.7),
        ),
        title: Row(
          children: [
            Text(
              'Previous Searches',
              style: TdResTextStyles.h6.copyWith(
                color: themeColors.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: themeColors.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${previousResults.length}',
                style: TdResTextStyles.caption.copyWith(
                  color: themeColors.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.expand_more,
          color: themeColors.onSurface.withOpacity(0.7),
        ),
        children: [
          ...previousResults.map((result) => _buildUnifiedResultItem(result, true)),
        ],
      ),
    );
  }

  Widget _buildUnifiedResultItem(UnifiedSearchResult result, bool isGreyedOut) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    final controller = BlocProvider.of<UnifiedController>(context);
    final tools = controller.getExpandableTools(result);

    return Column(
      children: [
        // Tool cards for each available tool type
        ...tools.map((toolType) => ToolCard(
          result: result,
          toolType: toolType,
          themeColors: themeColors,
          isGreyedOut: isGreyedOut,
          onCopy: (text) => _handleCopy(text),
          onShare: (text) => _handleShare(text),
          onReferenceClick: (reference) => _handleReferenceClick(reference),
        )).toList(),

        const SizedBox(height: 16),
      ],
    );
  }

  bool _shouldGreyOutResult(UnifiedSearchResult result, List<UnifiedSearchResult> allResults) {
    if (allResults.isEmpty) return false;
    final sessionIds = allResults.map((r) => r.searchSessionId);
    final mostRecentSessionId = sessionIds.reduce((a, b) => a > b ? a : b);
    return result.searchSessionId < mostRecentSessionId;
  }

  Widget _buildComingSoonContent(String title, IconData icon, Color color) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TdResTextStyles.h3.copyWith(
              color: Theme.of(context).extension<AppThemeColors>()!.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon!',
            style: TdResTextStyles.p2.copyWith(
              color: Theme.of(context).extension<AppThemeColors>()!.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              // Switch to unified tab for now
              widget.tabController.animateTo(0);
            },
            style: TextButton.styleFrom(
              backgroundColor: color.withOpacity(0.1),
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Use Unified Search',
              style: TdResTextStyles.p2.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDictionaryContent() {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    final appThemeDisplay = TdThemeHelper.prepareThemeDisplay(context);
    
    return BlocBuilder<QuickSearchController, QuickSearchState>(
      buildWhen: (previous, current) => 
        previous.currentSearchType != current.currentSearchType ||
        previous.wordDefineResult != current.wordDefineResult ||
        previous.isLoading != current.isLoading ||
        previous.error != current.error ||
        previous.searchCounter != current.searchCounter,
      builder: (context, state) {
        return Container(
          color: Color.alphaBlend(
            themeColors.secondaryColor.withAlpha(0x12),
            themeColors.surface,
          ),
          child: CustomScrollView(
            slivers: [
              _buildWordDefineOverview(state, themeColors, appThemeDisplay),
              _buildWordDetailsSection(state, themeColors, appThemeDisplay),
              _buildDefinitionsHeader(state, themeColors, appThemeDisplay),
              _buildDefinitionsList(state, themeColors, appThemeDisplay),
              _buildSimilarWordsSection(state, themeColors, appThemeDisplay),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWordDefineOverview(QuickSearchState state, AppThemeColors themeColors, AppThemeDisplay appThemeDisplay) {
    return BlocBuilder<QuickSearchController, QuickSearchState>(
      buildWhen: (previous, current) => current.searchCounter != previous.searchCounter,
      builder: (context, state) {
        if (state.searchCounter != 0) {
          return SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: CommonContainer(
            appThemeDisplay: appThemeDisplay,
            child: Container(
              constraints: BoxConstraints(maxWidth: 700),
      child: Column(
                spacing: appThemeDisplay.isSamllHeight ? TdResDimens.dp_24 : TdResDimens.dp_64,
                crossAxisAlignment: CrossAxisAlignment.center,
        children: [
                  SizedBox(height: 40),
          Text(
                    "Welcome to WORDefine",
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.linear(1.0),
                    style: (appThemeDisplay.isSamllHeight
                            ? TdResTextStyles.h1Bold
                            : TdResTextStyles.h1Bold)
                        .copyWith(
                      color: themeColors.onSurface,
                    ),
                  ),
          Text(
                    "Discover the depth and meaning of Sanskrit words. Search for definitions, etymology, and contextual usage.",
            textAlign: TextAlign.center,
                    textScaler: TextScaler.linear(1.0),
                    style: TdResTextStyles.p1.copyWith(
                      color: themeColors.onSurface.withAlpha(0xb3),
                      height: 1.5,
          ),
                  ),
                  SizedBox(height: 40),
        ],
              ),
            ),
      ),
        );
      },
    );
  }

  Widget _buildWordDetailsSection(QuickSearchState state, AppThemeColors themeColors, AppThemeDisplay appThemeDisplay) {
    return BlocBuilder<QuickSearchController, QuickSearchState>(
      buildWhen: (previous, current) => 
          current.isLoading != previous.isLoading ||
          current.wordDefineResult != previous.wordDefineResult,
      builder: (context, state) {
        if (state.isLoading == true ||
            state.wordDefineResult?.details == null ||
            (state.wordDefineResult?.details.word == null &&
                state.wordDefineResult?.details.llmDef == null)) {
          return SliverToBoxAdapter(child: SizedBox.shrink());
        }
        
        final wordDetails = state.wordDefineResult!.details;

        return SliverToBoxAdapter(
          child: CommonContainer(
            appThemeDisplay: appThemeDisplay,
            child: Container(
              width: double.maxFinite,
                    child: Column(
                spacing: TdResDimens.dp_18,
                      children: [
                  SizedBox(height: 16),
                  
                  // Word title
                  if (wordDetails.word != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        wordDetails.word!,
                        textAlign: TextAlign.left,
                        style: TdResTextStyles.h4Medium.copyWith(
                          color: themeColors.onSurface,
                        ),
                      ),
                    ),
                  
                  // Other scripts
                  if (wordDetails.otherScripts.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildWordScripts(wordDetails.otherScripts, themeColors),
                    ),
                  
                  // LLM Summary
                  if (wordDetails.llmDef != null && wordDetails.llmDef!.isNotEmpty)
                          Container(
                      decoration: TdResDecorations.decorationCardOutlined(
                        Color.alphaBlend(
                          themeColors.secondaryColor.withAlpha(0x12),
                          themeColors.onSurfaceLowest,
                        ),
                        themeColors.onSurface.withAlpha(0x06),
                        isElevated: false,
                      ).copyWith(
                        borderRadius: BorderRadius.circular(TdResDimens.dp_12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: TdResDimens.dp_16,
                        vertical: TdResDimens.dp_16,
                            ),
                            child: Column(
                              children: [
                                Row(
                            spacing: TdResDimens.dp_16,
                                  children: [
                              Container(
                                height: TdResDimens.dp_36,
                                width: TdResDimens.dp_36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(TdResDimens.dp_12),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color.alphaBlend(
                                        themeColors.secondaryColor.withAlpha(0xa0),
                                        themeColors.surface,
                                      ),
                                      Color.alphaBlend(
                                        themeColors.secondaryColor.withAlpha(0x64),
                                        themeColors.surface,
                                    ),
                                  ],
                                ),
                                ),
                                child: Icon(Icons.chat_bubble_outline),
                              ),
                                Text(
                                "LLM Summary",
                                textAlign: TextAlign.start,
                                style: TdResTextStyles.h4Medium.copyWith(
                                  color: themeColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          _buildMarkdown(wordDetails.llmDef!, themeColors),
                        ],
                      ),
                    ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWordScripts(Map<String, String?> otherScripts, AppThemeColors themeColors) {
    if (otherScripts.isEmpty) return SizedBox.shrink();
    
    // Filter to show only Devanagari script, exclude English
    final devanagariEntries = otherScripts.entries.where((entry) {
      return entry.key.toLowerCase() != 'english' && 
             entry.value != null && 
             entry.value!.isNotEmpty;
    }).toList();
    
    if (devanagariEntries.isEmpty) return SizedBox.shrink();
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: devanagariEntries.map((entry) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: themeColors.onSurface.withAlpha(0x0a),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${entry.value}',
            style: TdResTextStyles.caption.copyWith(
              color: themeColors.onSurface.withAlpha(0xb6),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMarkdown(String message, AppThemeColors themeColors) {
    return Container(
      padding: EdgeInsets.only(top: 12),
      child: Text(
        message,
        style: TdResTextStyles.p2.copyWith(
          color: themeColors.onSurface.withAlpha(0xcc),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildDefinitionsHeader(QuickSearchState state, AppThemeColors themeColors, AppThemeDisplay appThemeDisplay) 
  {
    return BlocBuilder<QuickSearchController, QuickSearchState>(
      buildWhen: (previous, current) =>
          current.isLoading != previous.isLoading ||
          current.wordDefineResult != previous.wordDefineResult,
      builder: (context, state) {
        if (state.isLoading == true || (state.wordDefineResult?.details.definitions.isEmpty ?? true)) {
          return SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: CommonContainer(
            appThemeDisplay: appThemeDisplay,
            child: Container(
              margin: EdgeInsets.only(top: TdResDimens.dp_24),
              height: TdResDimens.dp_48,
              child: Row(
                          children: [
                  Flexible(
                    flex: 1,
                    fit: FlexFit.tight,
                    child: Text(
                      "Definitions",
                      textAlign: TextAlign.start,
                      style: TdResTextStyles.h4Medium.copyWith(
                        color: themeColors.onSurface.withAlpha(0xb6),
                      ),
                    ),
                  ),
                            TextButton.icon(
                    onPressed: () {
                      _copyAllDefinitions(state.wordDefineResult!);
                    },
                              style: TextButton.styleFrom(
                      backgroundColor: themeColors.secondaryLight.withAlpha(0x22),
                    ),
                    label: Text(
                      "Copy All",
                      textAlign: TextAlign.start,
                      style: TdResTextStyles.buttonSmall.copyWith(
                        color: Color.alphaBlend(
                          themeColors.onSurface.withAlpha(0x96),
                          themeColors.secondaryLight,
                        ),
                      ),
                    ),
                    icon: Icon(
                      Icons.copy_all,
                      color: Color.alphaBlend(
                        themeColors.onSurface.withAlpha(0x96),
                        themeColors.secondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefinitionsList(QuickSearchState state, AppThemeColors themeColors, AppThemeDisplay appThemeDisplay) { 
    return BlocBuilder<QuickSearchController, QuickSearchState>(
      buildWhen: (previous, current) =>
          current.isLoading != previous.isLoading ||
          current.wordDefineResult != previous.wordDefineResult ||
          current.searchCounter != previous.searchCounter,
      builder: (context, state) {
        if (state.isLoading == true) {
          return SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: TdResDimens.dp_12),
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        } else if ((state.wordDefineResult?.details.definitions.isEmpty ?? true) &&
            state.searchCounter != 0) {
          return SliverToBoxAdapter(
            child: Container(
              constraints: BoxConstraints(maxWidth: 200, minHeight: 100),
              alignment: Alignment.center,
              child: Text(
                "No result found",
                style: TdResTextStyles.h3.copyWith(
                  color: themeColors.onSurface.withAlpha(0xb6),
                ),
              ),
            ),
          );
        } else if (state.wordDefineResult != null && state.wordDefineResult!.details.definitions.isNotEmpty) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return WordDefinitionCard(
                  definition: state.wordDefineResult!.details.definitions[index],
                  themeColors: themeColors,
                  appThemeDisplay: appThemeDisplay,
                  showLLMSummary: false, // LLM summary shown at page level
                  onSourceClick: _launchQuickSearchExternalUrl,
                );
              },
              childCount: state.wordDefineResult!.details.definitions.length,
            ),
          );
        }
        return SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildSimilarWordsSection(QuickSearchState state, AppThemeColors themeColors, AppThemeDisplay appThemeDisplay) {
    return BlocBuilder<QuickSearchController, QuickSearchState>(
      buildWhen: (previous, current) =>
          current.isLoading != previous.isLoading ||
          current.wordDefineResult != previous.wordDefineResult,
      builder: (context, state) {
        if (state.isLoading == true ||
            state.wordDefineResult?.similarWords == null ||
            state.wordDefineResult!.similarWords.isEmpty) {
          return SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: CommonContainer(
            appThemeDisplay: appThemeDisplay,
            child: Container(
              margin: EdgeInsets.only(top: TdResDimens.dp_24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Similar Words",
                    style: TdResTextStyles.h4Medium.copyWith(
                      color: themeColors.onSurface.withAlpha(0xb6),
                    ),
                  ),
                  SizedBox(height: TdResDimens.dp_12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.wordDefineResult!.similarWords.map((word) {
                      return Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          onTap: () => _searchSimilarWord(word),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: TdResDimens.dp_12,
                              vertical: TdResDimens.dp_6,
                            ),
                            decoration: BoxDecoration(
                              color: themeColors.secondaryLight.withAlpha(0x22),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: themeColors.secondaryLight.withAlpha(0x44),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              word,
                              style: TdResTextStyles.buttonSmall.copyWith(
                                color: Color.alphaBlend(
                                  themeColors.onSurface.withAlpha(0x96),
                                  themeColors.secondaryLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: TdResDimens.dp_40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _searchSimilarWord(String word) {
    // Update search controller and perform search
    widget.searchController.text = word;
    final controller = BlocProvider.of<QuickSearchController>(context);
    controller.performSearch(word);
  }

  Widget _buildVerseContent() {
    return BlocBuilder<QuickSearchController, QuickSearchState>(
      buildWhen: (previous, current) => 
        previous.currentSearchType != current.currentSearchType ||
        previous.verseResults != current.verseResults ||
        previous.isLoading != current.isLoading ||
        previous.error != current.error,
      builder: (context, state) {
        if (state.currentSearchType != SearchType.quickVerse) {
          return _buildEmptySearchState('QuickVerse', 'Find verses by partial text', Icons.keyboard_command_key);
        }

        if (state.isLoading) {
          return _buildLoadingState('Searching verses...');
        }

        if (state.error != null) {
          return _buildErrorState(state.error!, () {
            final query = widget.searchController.text.trim();
            if (query.isNotEmpty) {
              final controller = BlocProvider.of<QuickSearchController>(context);
              controller.performSearch(query);
            }
          });
        }

        if (state.verseResults.isEmpty) {
          return _buildEmptySearchState('QuickVerse', 'No verses found for your search', Icons.keyboard_command_key);
        }

        return Column(
          children: [
            // Language selector for verse results
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withAlpha(0x33),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Left side: Transcription credit (flexible to prevent overflow)
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.translate,
                          size: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: TdResDimens.dp_4),
                        Flexible(
                          child: Text(
                            "Transcription by Aksharamukha",
                            style: TdResTextStyles.caption.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${state.verseResults.length} verses',
                          style: TdResTextStyles.caption.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(0xAA),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: TdResDimens.dp_8),
                  
              // Right side: Language selector (fixed width)
              BlocBuilder<DashboardController, DashboardCubitState>(
                bloc: Modular.get<DashboardController>(),
                buildWhen: (previous, current) {
                  print("🔄 QUICKVERSE: buildWhen - prev: ${previous.verseLanguagePref?.output}, curr: ${current.verseLanguagePref?.output}");
                  return current.verseLanguagePref != previous.verseLanguagePref;
                },
                builder: (context, state) {
                  final currentLanguage = state.verseLanguagePref?.output ?? VersesConstants.LANGUAGE_DEFAULT;
                  print("🔄 QUICKVERSE: BlocBuilder rebuilding - currentLanguage: $currentLanguage");
                  print("🔄 QUICKVERSE: Raw state.verseLanguagePref: ${state.verseLanguagePref}");
                  print("🔄 QUICKVERSE: State verseLanguagePref output: ${state.verseLanguagePref?.output}");
                  print("🔄 QUICKVERSE: Using fallback to default: ${state.verseLanguagePref?.output == null}");
                  
                  final themeColors = AppThemeColors.seedColor(
                    seedColor: Theme.of(context).colorScheme.primary,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  );
                  
                  return PopupMenuButton<String>(
                    key: ValueKey('quickverse_language_dropdown_$currentLanguage'), // Force rebuild on language change
                    icon: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(TdResDimens.dp_6),
                        color: themeColors.primary,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            VersesConstants.LANGUAGE_LABELS_MAP[currentLanguage] ?? currentLanguage,
                            style: TdResTextStyles.caption.copyWith(
                              color: themeColors.surface,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 12,
                            color: themeColors.surface,
                          ),
                        ],
                      ),
                    ),
                    onSelected: (String value) {
                      print("🎯 QUICKVERSE: User selected language '$value' from dropdown");
                      Modular.get<DashboardController>().onVerseLanguageChange(value);
                    },
                    itemBuilder: (context) {
                      try {
                        final supportedLanguages = SupportedLanguagesService().getSupportedLanguages();
                        return supportedLanguages.entries.map<PopupMenuItem<String>>((entry) {
                          return PopupMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: TdResTextStyles.buttonSmall.copyWith(
                                color: themeColors.onSurface,
                              ),
                            ),
                          );
                        }).toList();
                      } catch (e) {
                        final fallbackLanguages = VersesConstants.LANGUAGE_LABELS_MAP.map((k, v) => MapEntry(k, v ?? k));
                        return fallbackLanguages.entries.map<PopupMenuItem<String>>((entry) {
                          return PopupMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: TdResTextStyles.buttonSmall.copyWith(
                                color: themeColors.onSurface,
                              ),
                            ),
                          );
                        }).toList();
                      }
                    },
                  );
                },
              ),
                ],
              ),
            ),
            // Verses list
            Expanded(
              child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.verseResults.length,
          itemBuilder: (context, index) {
            final verse = state.verseResults[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index < state.verseResults.length - 1 ? 16 : 0),
              child: VerseCard(
                verse: verse,
                onCopy: () => _handleCopy(verse.verseText ?? ''),
                onBookmark: () {
                  // TODO: Implement bookmark functionality
                },
              ),
            );
          },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBooksContent() {
    return BlocBuilder<QuickSearchController, QuickSearchState>(
      buildWhen: (previous, current) => 
        previous.currentSearchType != current.currentSearchType ||
        previous.bookResults != current.bookResults ||
        previous.isLoading != current.isLoading ||
        previous.error != current.error,
      builder: (context, state) {
        if (state.currentSearchType != SearchType.books) {
          return _buildEmptySearchState('Books', 'Search through book contents', Icons.menu_book);
        }

        if (state.isLoading) {
          return _buildLoadingState('Searching books...');
        }

        if (state.error != null) {
          return _buildErrorState(state.error!, () {
            final query = widget.searchController.text.trim();
            if (query.isNotEmpty) {
              final controller = BlocProvider.of<QuickSearchController>(context);
              controller.performSearch(query);
            }
          });
        }

        if (state.bookResults.isEmpty) {
          return _buildEmptySearchState('Books', 'No book content found for your search', Icons.menu_book);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.bookResults.length,
          itemBuilder: (context, index) {
            final bookChunk = state.bookResults[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index < state.bookResults.length - 1 ? 16 : 0),
              child: BookChunkItemLightweightWidget(
                chunk: bookChunk,
                onSourceClick: (url) async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                onNavigateNext: () => _handleNextChunk(bookChunk),
                onNavigatePrevious: () => _handlePreviousChunk(bookChunk),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptySearchState(String title, String subtitle, IconData icon) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: themeColors.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TdResTextStyles.h4.copyWith(
              color: themeColors.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TdResTextStyles.p2.copyWith(
              color: themeColors.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: themeColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TdResTextStyles.p2.copyWith(
              color: themeColors.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: themeColors.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Search Error',
            style: TdResTextStyles.h4.copyWith(
              color: themeColors.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TdResTextStyles.p2.copyWith(
              color: themeColors.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _handleCopy(String text) {
    // TODO: Implement copy functionality
  }

  void _handleShare(String text) {
    // TODO: Implement share functionality
  }

  void _handleReferenceClick(String reference) {
    _launchQuickSearchExternalUrl(reference);
  }

  /// Build QuickSearch side drawer (following Prashna pattern)
  Widget _buildQuickSearchDrawer(AppThemeColors themeColors) {
    return Drawer(
      backgroundColor: _getBackgroundColor(themeColors),
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(themeColors),
            _buildDrawerDivider(themeColors),
            _buildQuickSearchAppsSection(themeColors),
            _buildDrawerDivider(themeColors),
            // TODO: Add search history section later
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(AppThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      child: Row(
        children: [
          // QuickSearch icon with orange theme
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withAlpha(0x15), // Orange
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.electric_bolt,
              size: 18,
              color: const Color(0xFFFF6B35), // Orange
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Shodh (शोध)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: themeColors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          // Close button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                color: themeColors.onSurfaceMedium,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerDivider(AppThemeColors themeColors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      height: 1,
      color: themeColors.onSurface?.withAlpha(0x10) ?? Colors.grey.withAlpha(0x10),
    );
  }

  Widget _buildQuickSearchAppsSection(AppThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Search Types',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: themeColors.onSurfaceMedium,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          // Shodh App
          _buildDrawerAppItem(
            icon: Icons.electric_bolt,
            title: 'Shodh (शोध)',
            subtitle: 'Search across all sources',
            color: const Color(0xFFFF6B35), // Orange
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              widget.onSearchModeChanged(QuickSearchMode.unified);
            },
            themeColors: themeColors,
          ),
          
          const SizedBox(height: 8),
          
          // WordDefine App
          _buildDrawerAppItem(
            icon: Icons.local_library_outlined,
            title: 'WordDefine',
            subtitle: 'Dictionary definitions & meanings',
            color: const Color(0xFFF9140C), // Red
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              widget.onSearchModeChanged(QuickSearchMode.dictionary);
            },
            themeColors: themeColors,
          ),
          
          const SizedBox(height: 8),
          
          // QuickVerse App
          _buildDrawerAppItem(
            icon: Icons.keyboard_command_key,
            title: 'QuickVerse',
            subtitle: 'Verse search with translations',
            color: const Color(0xFF189565), // Green
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              widget.onSearchModeChanged(QuickSearchMode.verse);
            },
            themeColors: themeColors,
          ),

          const SizedBox(height: 8),
          
          // Books App
          _buildDrawerAppItem(
            icon: Icons.menu_book,
            title: 'Books',
            subtitle: 'Search through book contents',
            color: Colors.blue, // Blue
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              widget.onSearchModeChanged(QuickSearchMode.books);
            },
            themeColors: themeColors,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerAppItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required AppThemeColors themeColors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: themeColors.onSurface?.withAlpha(0x08) ?? Colors.grey.withAlpha(0x08),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withAlpha(0x20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: themeColors.onSurfaceMedium,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: themeColors.onSurfaceMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// 🔄 Handle previous chunk navigation
  void _handlePreviousChunk(bookChunk) {
    if (bookChunk.chunkRefId == null) return;
    
    print('⚡ Enhanced QuickSearch: Navigate to previous chunk from: ${bookChunk.chunkRefId}');
    
    // Use BooksService to handle navigation
    final booksService = BooksService.instance;
    booksService.navigateChunk(bookChunk.chunkRefId!, false);
  }

  /// ⏭️ Handle next chunk navigation  
  void _handleNextChunk(bookChunk) {
    if (bookChunk.chunkRefId == null) return;
    
    print('⚡ Enhanced QuickSearch: Navigate to next chunk from: ${bookChunk.chunkRefId}');
    
    // Use BooksService to handle navigation
    final booksService = BooksService.instance;
    booksService.navigateChunk(bookChunk.chunkRefId!, true);
  }

}
