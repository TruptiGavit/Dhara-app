import 'package:flutter/foundation.dart';
import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/app/ui/pages/words/controller.dart';
import 'package:dharak_flutter/app/ui/pages/words/cubit_states.dart';
import 'package:dharak_flutter/app/ui/pages/verses/controller.dart';
import 'package:dharak_flutter/app/ui/pages/verses/cubit_states.dart';

import 'package:dharak_flutter/app/ui/pages/prashna/controller.dart';
import 'package:dharak_flutter/app/ui/pages/books/controller.dart';
import 'package:dharak_flutter/app/ui/pages/books/cubit_states.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/controller.dart';
import 'package:dharak_flutter/app/domain/verse/constants.dart';
import 'package:dharak_flutter/app/data/services/supported_languages_service.dart';
import 'package:dharak_flutter/core/services/books_service.dart';
import 'package:dharak_flutter/app/types/books/book_chunk.dart' as new_book_chunk;
import 'package:dharak_flutter/app/ui/widgets/aksharmukha_language_selector.dart';
import 'package:dharak_flutter/app/ui/widgets/verse_text.dart';
import 'package:dharak_flutter/app/ui/pages/unified/controller.dart';
import 'package:dharak_flutter/app/ui/pages/unified/page.dart';
import 'package:flutter_modular/flutter_modular.dart';

// Import actual page components
import 'package:dharak_flutter/app/ui/pages/words/page.dart';
import 'package:dharak_flutter/app/ui/pages/words/args.dart';
import 'package:dharak_flutter/app/ui/pages/verses/page.dart';
import 'package:dharak_flutter/app/ui/pages/verses/args.dart';
import 'package:dharak_flutter/app/ui/pages/books/page.dart';
import 'package:dharak_flutter/app/ui/pages/books/args.dart';
import 'package:dharak_flutter/app/ui/pages/books/parts/item_lightweight.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dharak_flutter/app/types/dictionary/definition.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/types/books/chunk.dart';


import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/app/ui/widgets/aksharmukha_language_selector.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_modular/flutter_modular.dart';
import 'package:provider/provider.dart';
import 'package:dharak_flutter/app/tools/route/route_change_notifier.dart';
import 'dart:async';

extension StringCapitalization on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class SearchLandingPage extends StatefulWidget {
  const SearchLandingPage({super.key});

  @override
  State<SearchLandingPage> createState() => _SearchLandingPageState();
}

// Navigation context to track search-initiated navigation and active search module
class SearchNavigationContext {
  static final Map<String, bool> _fromSearchFlags = {};
  static final Map<String, String> _searchQueries = {};
  static int _activeSearchModule = 0; // 0: WordDefine, 1: QuickVerse, 2: Books
  
  // ValueNotifier to notify listeners about module color changes
  static final ValueNotifier<Color> _activeModuleColorNotifier = ValueNotifier<Color>(
    const Color(0xFFF9140C), // Default to WordDefine color
  );
  
  static void setFromSearch(String route, String query) {
    _fromSearchFlags[route] = true;
    _searchQueries[route] = query;
    print("🏷️ Set navigation context: $route from search with query: '$query'");
  }
  
  static bool isFromSearch(String route) {
    final result = _fromSearchFlags[route] ?? false;
    print("🔍 Checking if $route is from search: $result");
    return result;
  }
  
  static String? getSearchQuery(String route) {
    return _searchQueries[route];
  }
  
  static void clearRoute(String route) {
    _fromSearchFlags.remove(route);
    _searchQueries.remove(route);
    print("🧹 Cleared navigation context for: $route");
  }
  
  static void clearAll() {
    _fromSearchFlags.clear();
    _searchQueries.clear();
    print("🧹 Cleared all navigation contexts");
  }
  
  // New methods for tracking active search module
  static void setActiveSearchModule(int moduleIndex) {
    _activeSearchModule = moduleIndex;
    _activeModuleColorNotifier.value = getActiveSearchModuleColor();
    print("🎨 Set active search module: $moduleIndex with color: ${getActiveSearchModuleColor()}");
  }
  
  static int getActiveSearchModule() {
    return _activeSearchModule;
  }
  
  static Color getActiveSearchModuleColor() {
    const colors = [
      Color(0xFFF9140C), // WordDefine red color (consistent with actual WordDefine theme)
      Color(0xFF189565), // QuickVerse green  
      Colors.blue,       // Books blue
    ];
    return colors[_activeSearchModule.clamp(0, colors.length - 1)];
  }
  
  // Getter for the ValueNotifier to allow listening to color changes
  static ValueNotifier<Color> get activeModuleColorNotifier => _activeModuleColorNotifier;
}

enum SearchType { word, verse, book, mixed }

class SearchResult {
  final String title;        // What to display to user
  final String subtitle;
  final SearchType type;
  final String searchQuery;  // What to actually search for
  final VoidCallback onTap;

  SearchResult({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.searchQuery,
    required this.onTap,
  });
}

class _SearchLandingPageState extends State<SearchLandingPage> 
    with TickerProviderStateMixin {
  late AppThemeColors themeColors;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  // Tab management for unified interface
  int _selectedTabIndex = 0;
  bool _isTabSwitching = false; // Flag to prevent auto-search on tab switch
  
  // Base tab configuration
  final List<String> _baseTabLabels = ['WordDefine', 'QuickVerse', 'Books'];
  final List<Color> _baseTabColors = [
    const Color(0xFFF9140C), // WordDefine red color (consistent with actual WordDefine theme)
    const Color(0xFF189565), // QuickVerse green  
    Colors.blue,             // Books blue
  ];
  
  // Dynamic getters for tabs (unified tab now available for everyone)
  List<String> get _tabLabels {
    return [..._baseTabLabels, 'Unified'];
  }
  
  List<Color> get _tabColors {
    return [..._baseTabColors, Colors.orange];
  }
  
  Timer? _debounceTimer;
  bool _isSearching = false;
  bool _hasSearched = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Store controller instances to ensure consistency
  WordDefineController? _wordDefineController;
  VersesController? _versesController;
  BooksController? _booksController;
  UnifiedSearchController? _unifiedSearchController;
  
  // Stream subscription for language changes
  StreamSubscription? _languageChangeSubscription;
  
  // Track last language to detect changes
  String? _lastLanguage;
  
  // Tab-specific state management
  final Map<int, TextEditingController> _tabSearchControllers = {
    0: TextEditingController(), // WordDefine
    1: TextEditingController(), // QuickVerse  
    2: TextEditingController(), // Books
    3: TextEditingController(), // Unified (when enabled)
  };
  final Map<int, bool> _tabHasSearched = {0: false, 1: false, 2: false, 3: false};
  final Map<int, bool> _tabIsSearching = {0: false, 1: false, 2: false, 3: false};

  /// Get current language from dashboard controller
  String? _getCurrentLanguage() {
    try {
      final dashboardController = Modular.get<DashboardController>();
      return dashboardController.state.verseLanguagePref?.output;
    } catch (e) {
      return null; // fallback if controller not available
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _searchController.addListener(_onSearchChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      
      // Set the current tab for the dashboard
      Provider.of<RouteChangeNotifier>(
        context,
        listen: false,
      ).updateTab(UiConstants.Tabs.search);
      
      // Set initial active search module
      SearchNavigationContext.setActiveSearchModule(_selectedTabIndex);
      
      // Listen for language changes from dashboard controller
      _setupLanguageChangeListener();
      
      // Initialize developer mode listeners
      // Unified tab is now available for everyone - no need for developer mode checks
    });
  }

  // Lazy getters for controllers to ensure they're available when needed
  WordDefineController get wordDefineController {
    _wordDefineController ??= Modular.get<WordDefineController>();
    return _wordDefineController!;
  }

  VersesController get versesController {
    _versesController ??= Modular.get<VersesController>();
    return _versesController!;
  }
  
  void _setupLanguageChangeListener() {
    try {
      // Listen to VersesController state changes for language preference changes
      _languageChangeSubscription = versesController.stream.listen((state) {
        // Only react to language preference changes, not all state changes
        final currentLanguage = state.verseLanguagePref?.output;
        
        if (currentLanguage != null && currentLanguage != _lastLanguage) {
          _lastLanguage = currentLanguage;
          
          print("🌐 VERSES CONTROLLER LISTENER: Language changed to '$currentLanguage'");
          print("🌐 VERSES CONTROLLER LISTENER: Current tab: $_selectedTabIndex");
          
          // Check if we have QuickVerse results to refresh
          final quickVerseQuery = _tabSearchControllers[1]?.text.trim() ?? '';
          final hasQuickVerseResults = (_tabHasSearched[1] ?? false) && quickVerseQuery.isNotEmpty;
          
          if (hasQuickVerseResults) {
            print("🔄 VERSES CONTROLLER LISTENER: Refreshing QuickVerse for query: '$quickVerseQuery'");
            
            // Show loading if currently on QuickVerse tab
            if (_selectedTabIndex == 1 && mounted) {
              setState(() {
                _isSearching = true;
                _tabIsSearching[1] = true;
              });
            }
            
            // Perform silent refresh after a delay
            Future.delayed(const Duration(milliseconds: 500), () async {
              try {
                await _searchInQuickVerse(quickVerseQuery);
                print("✅ VERSES CONTROLLER LISTENER: QuickVerse refresh completed");
              } catch (e) {
                print("❌ VERSES CONTROLLER LISTENER: Error refreshing QuickVerse: $e");
              } finally {
                if (_selectedTabIndex == 1 && mounted) {
                  setState(() {
                    _isSearching = false;
                    _tabIsSearching[1] = false;
                  });
                }
              }
            });
          } else {
            print("🔄 VERSES CONTROLLER LISTENER: No QuickVerse results to refresh");
          }
        }
      });
      
      print("✅ Language change listener setup successfully");
    } catch (e) {
      print("❌ Error setting up language change listener: $e");
    }
  }

  BooksController get booksController {
    _booksController ??= Modular.get<BooksController>();
    return _booksController!;
  }
  
  UnifiedSearchController get unifiedSearchController {
    _unifiedSearchController ??= Modular.get<UnifiedSearchController>();
    return _unifiedSearchController!;
  }
  
  // Removed developer mode listeners - unified tab is now available for everyone

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    themeColors = Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: const Color(0xFF6CE18D), isDark: false);
  }

  void _onSearchChanged() {
    // Skip auto-search if we're in the middle of a tab switch
    if (_isTabSwitching) {
      return;
    }
    
    // Only auto-search for QuickVerse (index 1), others require manual search
    if (_selectedTabIndex == 1) { // QuickVerse
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
          });
        }
      });
    } else {
      // For WordDefine and Books, just update the empty state and button visibility
      final query = _tabSearchControllers[_selectedTabIndex]?.text.trim() ?? '';
      setState(() {
        if (query.isEmpty) {
          _hasSearched = false;
          _isSearching = false;
        }
        // This setState will trigger rebuild to show/hide search button
      });
    }
  }

  void _performModuleSearch(String query) async {
          setState(() {
        _isSearching = true;
        _hasSearched = true;
        // Save state to current tab
        _tabHasSearched[_selectedTabIndex] = true;
        _tabIsSearching[_selectedTabIndex] = true;
        _tabSearchControllers[_selectedTabIndex]?.text = query;
      });

    // Perform search in the respective module controller
    switch (_selectedTabIndex) {
      case 0: // WordDefine
        await _searchInWordDefine(query);
        break;
      case 1: // QuickVerse
        await _searchInQuickVerse(query);
        break;
      case 2: // Books
        await _searchInBooks(query);
        break;
      case 3: // Unified (when enabled)
        await _searchInUnified(query);
        break;
    }

    setState(() {
      _isSearching = false;
      // Update tab-specific state
      _tabIsSearching[_selectedTabIndex] = false;
    });
  }

  Future<void> _searchInWordDefine(String query) async {
    try {
      print("🔍 WordDefine: Starting search for '$query'");
      print("🔍 WordDefine: Controller instance: ${wordDefineController.hashCode}, current state: ${wordDefineController.state}");
      
      // Sync the search text with the module controller
      wordDefineController.mSearchController.text = query;
      wordDefineController.onFormSearchTextChanged(query);
      
      await wordDefineController.onSearchDirectQuery(query);
      print("🔍 WordDefine: Search completed, new state: ${wordDefineController.state}");
    } catch (e) {
      print("❌ Error searching in WordDefine: $e");
    }
  }

  Future<void> _searchInQuickVerse(String query) async {
    try {
      print("🔍 QuickVerse: Starting search for '$query'");
      print("🔍 QuickVerse: Controller instance: ${versesController.hashCode}");
      print("🔍 QuickVerse: Current state before search:");
      print("  - isLoading: ${versesController.state.isLoading}");
      print("  - formSearchText: '${versesController.state.formSearchText}'");
      print("  - searchQuery: '${versesController.state.searchQuery}'");
      print("  - verseList.length: ${versesController.state.verseList.length}");
      print("  - searchSequestCounter: ${versesController.state.searchSequestCounter}");
      
      // Sync the search text with the module controller (but skip the debounced search)
      versesController.mSearchController.text = query;
      
      // Also update form search text to ensure controller has the query
      versesController.onFormSearchTextChanged(query);
      
      // Only use direct query to avoid conflicts with debounced search
      print("🔄 QuickVerse: Calling onSearchDirectQuery...");
      await versesController.onSearchDirectQuery(query);
      
      print("✅ QuickVerse: Search completed!");
      print("🔍 QuickVerse: Final state after search:");
      print("  - isLoading: ${versesController.state.isLoading}");
      print("  - formSearchText: '${versesController.state.formSearchText}'");
      print("  - searchQuery: '${versesController.state.searchQuery}'");
      print("  - verseList.length: ${versesController.state.verseList.length}");
      print("  - searchSequestCounter: ${versesController.state.searchSequestCounter}");
    } catch (e) {
      print("❌ Error searching in QuickVerse: $e");
      print("❌ Stack trace: ${StackTrace.current}");
    }
  }

  Future<void> _searchInBooks(String query) async {
    try {
      print("🔍 Books: Starting search for '$query'");
      print("🔍 Books: Controller instance: ${booksController.hashCode}, current state: ${booksController.state}");
      
      // Sync the search text with the module controller
      booksController.mSearchController.text = query;
      booksController.onFormSearchTextChanged(query);
      
      await booksController.onSearchDirectQuery(query);
      print("🔍 Books: Search completed, new state: ${booksController.state}");
    } catch (e) {
      print("❌ Error searching in Books: $e");
    }
  }

  Future<void> _searchInUnified(String query) async {
    try {
      print("🔍 Unified: Starting search for '$query'");
      print("🔍 Unified: Controller instance: ${unifiedSearchController.hashCode}");
      
      // Use streaming search for instant results - no more duplicate calls!
      await unifiedSearchController.searchStreaming(query);
      print("🔍 Unified: Search completed");
    } catch (e) {
      print("❌ Error searching in Unified: $e");
    }
  }

  List<SearchResult> _generateSmartResults(String query) {
    List<SearchResult> results = [];
    String cleanQuery = query.trim();
    
    // Enhanced detection logic
    bool hasDevanagari = cleanQuery.contains(RegExp(r'[\u0900-\u097F]'));
    bool hasQuestionWords = cleanQuery.toLowerCase().contains(RegExp(r'\b(what|how|why|when|where|who|which|tell|explain|meaning)\b'));
    bool hasPersonQuery = cleanQuery.toLowerCase().contains(RegExp(r'\b(who is|what is|tell me about)\b'));
    bool hasVerseKeywords = cleanQuery.toLowerCase().contains(RegExp(r'\b(verse|shloka|mantra|hymn|stanza|chapter)\b'));
    bool hasBookKeywords = cleanQuery.toLowerCase().contains(RegExp(r'\b(book|text|gita|upanishad|purana|veda|ramayana|mahabharata)\b'));
    bool isShortName = cleanQuery.length <= 12 && !cleanQuery.contains(' ') && !hasQuestionWords;
    bool isLikelyName = RegExp(r'^[a-z]+$').hasMatch(cleanQuery.toLowerCase()) && cleanQuery.length >= 3;
    
    // Smart entity extraction for multi-entity queries
    List<String> extractedEntities = _extractEntities(cleanQuery);
    
    // SMART PRIORITY SYSTEM:
    
    // 1. Word Dictionary (ALWAYS show for most queries - as you said!)
    if (cleanQuery.length >= 2) { // Much lower threshold!
      if (extractedEntities.length > 1) {
        // Multiple entities: create separate cards for each entity
        for (String entity in extractedEntities) {
                  results.add(SearchResult(
          title: entity,
          subtitle: "Dictionary", 
          type: SearchType.word,
          searchQuery: entity,
          onTap: () => _navigateToFeature(UiConstants.Routes.wordDefine, query: entity),
        ));
        }
      } else {
        // Single entity or general query
        String searchQuery = cleanQuery;
        
        if (hasPersonQuery) {
          // For "who is rama", extract just "rama"
          String cleaned = cleanQuery.replaceAll(RegExp(r'\b(who is|what is|tell me about)\s*', caseSensitive: false), '');
          searchQuery = cleaned.trim();
        } else if (extractedEntities.length == 1 && extractedEntities[0] != cleanQuery.toLowerCase()) {
          // Single extracted entity different from query
          searchQuery = extractedEntities[0];
        }
        
        results.add(SearchResult(
          title: searchQuery,
          subtitle: "Dictionary",
          type: SearchType.word,
          searchQuery: searchQuery,
          onTap: () => _navigateToFeature(UiConstants.Routes.wordDefine, query: searchQuery),
        ));
      }
    }
    
    // 2. Verses (ALWAYS show for meaningful queries - you're right!)
    if (cleanQuery.length >= 3) { // Much more inclusive!
      if (extractedEntities.length > 1) {
        // Multiple entities: create separate cards for each entity in verses
        for (String entity in extractedEntities) {
          results.add(SearchResult(
            title: entity,
            subtitle: "Verses",
            type: SearchType.verse,
            searchQuery: entity,
            onTap: () => _navigateToFeature(UiConstants.Routes.verse, query: entity),
          ));
        }
      } else {
        // Single entity or general query
        String searchQuery = cleanQuery;
        
        if (extractedEntities.length == 1 && extractedEntities[0] != cleanQuery.toLowerCase()) {
          // Single extracted entity
          searchQuery = extractedEntities[0];
        }
        
        results.add(SearchResult(
          title: searchQuery,
          subtitle: "Verses",
          type: SearchType.verse,
          searchQuery: searchQuery,
          onTap: () => _navigateToFeature(UiConstants.Routes.verse, query: searchQuery),
        ));
      }
    }
    
    // AI Questions are now handled by the AI Assistant card - no separate result needed
    
    // 4. Books/Scriptures (For longer queries or specific texts)
    if (hasBookKeywords || cleanQuery.split(' ').length >= 2) {
      results.add(SearchResult(
        title: cleanQuery,
        subtitle: "Books",
        type: SearchType.book,
        searchQuery: cleanQuery,
        onTap: () => _navigateToFeature('/books', query: cleanQuery),
      ));
    }
    
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeColors.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Tab buttons
              _buildTabBar(),
              // Search bar with colored border
              _buildSearchBar(),
              // Content area (results or empty state)
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredLayout() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                    MediaQuery.of(context).padding.top - 
                    kBottomNavigationBarHeight - 100, // Account for bottom nav and some padding
        ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top padding (minimal)
              const SizedBox(height: TdResDimens.dp_32),
              
              // Welcome section (compact)
              _buildCompactWelcomeSection(),
              
              const SizedBox(height: TdResDimens.dp_32),
              
              // Prominent Search Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: TdResDimens.dp_24),
                child: _buildSearchBar(),
              ),
              
              const SizedBox(height: TdResDimens.dp_24),
              
              // Quick Access Modules
              _buildQuickAccessModules(),
              
              // Bottom padding
              const SizedBox(height: TdResDimens.dp_32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsLayout() {
    return Column(
      children: [
        // Compact Search Header for results
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TdResDimens.dp_20,
            vertical: TdResDimens.dp_16,
          ),
          child: _buildSearchBar(),
        ),
        
        // Search Results
        Expanded(
          child: _buildDynamicContent(),
        ),
      ],
    );
  }



  Widget _buildWelcomeSection() {
    return Column(
      children: [
        // App Logo/Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.withOpacity(0.1),
                Colors.blue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: themeColors.onSurface?.withOpacity(0.08) ?? Colors.grey.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.auto_stories,
            size: 36,
            color: Colors.orange.withOpacity(0.8),
          ),
        ),
        
        const SizedBox(height: TdResDimens.dp_24),
        
        // Welcome Text
        Text(
          "Welcome to Dhārā",
          style: TdResTextStyles.h1.copyWith(
            color: themeColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: TdResDimens.dp_12),
        
        Text(
          "Discover the wisdom of Sanskrit\ntexts, verses, and meanings",
          textAlign: TextAlign.center,
          style: TdResTextStyles.h5.copyWith(
            color: themeColors.onSurface?.withOpacity(0.7),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactWelcomeSection() {
    return Column(
      children: [
        // Dhara Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/img/dhara_logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
        ),
        
        const SizedBox(height: TdResDimens.dp_16),
        
        // Welcome Text (more compact)
        Text(
          "Welcome to Dhārā",
          style: TdResTextStyles.h2.copyWith(
            color: themeColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: TdResDimens.dp_8),
        
        Text(
          "Discover Sanskrit wisdom",
          textAlign: TextAlign.center,
          style: TdResTextStyles.h6.copyWith(
            color: themeColors.onSurface?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicContent() {
    if (_isSearching) {
      return _buildSearchingState();
    } else if (_hasSearched) {
      return _buildSearchResults();
    } else if (false) { // Old logic: _hasSearched && _searchResults.isEmpty
      return _buildNoResults();
    } else {
      return _buildDefaultState();
    }
  }

  Widget _buildSearchingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                themeColors.primary ?? Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: TdResDimens.dp_16),
          Text(
            "Searching across all sources...",
            style: TdResTextStyles.h5.copyWith(
              color: themeColors.onSurface?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // Group results by category
    final quickSearchResults = <SearchResult>[]; // Removed old search results logic
    // Old search results logic removed for simplified tabbed interface
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: TdResDimens.dp_20),
      children: [
        // QuickSearch Section - Database Results
        if (quickSearchResults.isNotEmpty) ...[
          _buildSectionHeader("Shodh (शोध)", Icons.electric_bolt, Colors.blue),
          const SizedBox(height: TdResDimens.dp_4),
          Text(
            "Direct results from our database",
            style: TdResTextStyles.caption.copyWith(
              color: themeColors.onSurface?.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: TdResDimens.dp_8),
          ...quickSearchResults.map((result) => _buildResultItem(result, 0)),
          const SizedBox(height: TdResDimens.dp_20),
        ],
        
        // AI Assistant Section - Always show if we have a query
        if (_searchController.text.trim().isNotEmpty) ...[
          _buildSectionHeader("AI Assistant", Icons.chat_bubble_outline, Colors.indigo),
          const SizedBox(height: TdResDimens.dp_4),
          Text(
            "Get AI-powered answers and insights",
            style: TdResTextStyles.caption.copyWith(
              color: themeColors.onSurface?.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: TdResDimens.dp_8),
          _buildAIAssistantCard(),
          const SizedBox(height: TdResDimens.dp_16),
        ],
      ],
    );
  }

  Widget _buildAIAssistantCard() {
    final query = _searchController.text.trim();
    
    return Container(
      padding: const EdgeInsets.all(TdResDimens.dp_16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TdResDimens.dp_16),
        border: Border.all(
          color: Colors.indigo.withOpacity(0.2),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.withOpacity(0.08),
            Colors.purple.withOpacity(0.04),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Assistant Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(TdResDimens.dp_8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TdResDimens.dp_8),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.indigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: TdResDimens.dp_12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ask Prashna About \"$query\"",
                      style: TdResTextStyles.h6.copyWith(
                        color: themeColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Get personalized explanations and insights",
                      style: TdResTextStyles.caption.copyWith(
                        color: themeColors.onSurface?.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TdResDimens.dp_12),
          
          // AI Tools Quick Access - Context Aware
          Text(
            "Choose AI Tool:",
            style: TdResTextStyles.caption.copyWith(
              color: themeColors.onSurface?.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: TdResDimens.dp_8),
          
          Row(
            children: _buildContextAwareAITools(query),
          ),
        ],
      ),
    );
  }

  Widget _buildAIToolChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(TdResDimens.dp_8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: TdResDimens.dp_8,
            horizontal: TdResDimens.dp_6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TdResDimens.dp_8),
            color: color.withOpacity(0.08),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(height: TdResDimens.dp_4),
              Text(
                label,
                style: TdResTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContextAwareAITools(String query) {
    final lowercaseQuery = query.toLowerCase();
    List<Widget> tools = [];
    
    // Always show "Ask Prashna" - this is the main Q&A
    tools.add(
      Expanded(
        child: _buildAIToolChip(
          label: "Ask Prashna",
          icon: Icons.chat_bubble_outline,
          color: Colors.indigo,
          onTap: () => _navigateToAITool('/prashna', query),
        ),
      ),
    );
    
    // Context-aware suggestions
    if (_isNamingQuery(lowercaseQuery)) {
      // Show name generator for naming queries
      tools.add(const SizedBox(width: TdResDimens.dp_8));
      tools.add(
        Expanded(
          child: _buildAIToolChip(
            label: "Generate",
            icon: Icons.search,
            color: Colors.purple,
            onTap: () => _navigateToAITool('/naming', query),
          ),
        ),
      );
    }
    
    if (_isWritingQuery(lowercaseQuery)) {
      // Show essay writer for writing/explanation queries
      tools.add(const SizedBox(width: TdResDimens.dp_8));
      tools.add(
        Expanded(
          child: _buildAIToolChip(
            label: "Write Essay",
            icon: Icons.edit_note,
            color: Colors.teal,
            onTap: () => _navigateToAITool('/essay', query),
          ),
        ),
      );
    }
    
    // If only Ask AI is shown, add a generic "More Tools" option
    if (tools.length == 1) {
      tools.add(const SizedBox(width: TdResDimens.dp_8));
      tools.add(
        Expanded(
          child: _buildAIToolChip(
            label: "More Tools",
            icon: Icons.apps,
            color: Colors.grey,
            onTap: () => _switchToChatTab(),
          ),
        ),
      );
    }
    
    return tools;
  }
  
  bool _isNamingQuery(String query) {
    // Check if query is about naming/generating names
    final namingKeywords = [
      'name', 'names', 'generate', 'suggest', 'baby', 'child', 
      'boy', 'girl', 'hindu', 'sanskrit', 'meaning', 'choose'
    ];
    
    // Check for naming patterns
    if (query.contains('name') && 
        (query.contains('suggest') || query.contains('generate') || query.contains('baby'))) {
      return true;
    }
    
    return namingKeywords.any((keyword) => query.contains(keyword)) && 
           query.split(' ').length >= 2; // Multi-word naming queries
  }
  
  bool _isWritingQuery(String query) {
    // Check if query is about writing/essays/explanations
    final writingKeywords = [
      'write', 'essay', 'explain', 'describe', 'elaborate', 
      'analysis', 'compare', 'discuss', 'article', 'story'
    ];
    
    // Check for writing patterns
    if (query.contains('write') || query.contains('essay') || query.contains('explain')) {
      return true;
    }
    
    return writingKeywords.any((keyword) => query.contains(keyword));
  }
  
  void _switchToChatTab() {
    // Navigate to Chat tab for more AI tools
    print("🔄 Switching to Chat tab for more AI tools");
    Modular.to.navigate('/chat');
  }

  void _navigateToAITool(String tool, String query) {
    // Navigate to specific AI tool
    print("🤖 Navigating to AI tool: $tool with query: $query");
    
    if (context.mounted) {
      switch (tool) {
        case '/prashna':
          _navigateToFeature('/prashna', query: query);
          break;
        case '/naming':
          // TODO: Navigate to naming app when built
          _showComingSoon("Name Generator");
          break;
        case '/essay':
          // TODO: Navigate to essay writer when built
          _showComingSoon("Essay Writer");
          break;
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: TdResDimens.dp_8, bottom: TdResDimens.dp_4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: TdResDimens.dp_8),
          Text(
            title,
            style: TdResTextStyles.p2.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: TdResDimens.dp_12),
              height: 1,
              color: color.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(SearchResult result, int index) {
    // Get consistent tool info
    IconData icon = Icons.search;
    Color color = Colors.grey;
    String toolName = "Unknown";
    
    switch (result.type) {
      case SearchType.word:
        icon = Icons.local_library_outlined; // WordDefine icon from login page
        color = const Color(0xFFF9140C); // WordDefine red color (consistent)
        toolName = "Dictionary";
        break;
      case SearchType.verse:
        icon = Icons.keyboard_command_key; // QuickVerse icon from login page
        color = const Color(0xFF189565); // TdResColors.colorPrimary40
        toolName = "Verses";
        break;
      case SearchType.book:
        icon = Icons.menu_book; // Books icon as requested
        color = Colors.blue; // Blue color as requested
        toolName = "Books";
        break;
      case SearchType.mixed:
        icon = Icons.chat_bubble_outline; // Chat icon for AI/Prashna
        color = Colors.indigo; // Indigo color used in Prashna empty state
        toolName = "Prashna (प्रश्न)";
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: TdResDimens.dp_12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TdResDimens.dp_12),
          onTap: result.onTap,
          child: Container(
            padding: const EdgeInsets.all(TdResDimens.dp_16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TdResDimens.dp_12),
              border: Border.all(
                color: themeColors.onSurface?.withOpacity(0.08) ?? Colors.grey.withOpacity(0.08),
              ),
              color: color.withOpacity(0.02),
            ),
            child: Row(
              children: [
                // Tool icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                TdResGaps.h_16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tool name
                      Text(
                        toolName,
                        style: TdResTextStyles.h5.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TdResGaps.v_4,
                      // Smart result title
                      Text(
                        result.title,
                        style: TdResTextStyles.p3.copyWith(
                          color: themeColors.onSurface?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: themeColors.onSurface?.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: themeColors.onSurface?.withOpacity(0.3),
          ),
          const SizedBox(height: TdResDimens.dp_16),
          Text(
            "No results found",
            style: TdResTextStyles.h4.copyWith(
              color: themeColors.onSurface?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: TdResDimens.dp_8),
          Text(
            "Try different keywords or check spelling",
            style: TdResTextStyles.p2.copyWith(
              color: themeColors.onSurface?.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TdResDimens.dp_24),
        child: Column(
          children: [
            TdResGaps.v_44,
            
            // Beautiful Welcome Section
            Column(
              children: [
                // App Logo/Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.withOpacity(0.1),
                        Colors.blue.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: themeColors.onSurface?.withOpacity(0.08) ?? Colors.grey.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.auto_stories,
                    size: 36,
                    color: Colors.orange.withOpacity(0.8),
                  ),
                ),
                
                TdResGaps.v_24,
                
                // Welcome Text
                Text(
                  "Welcome to Dhārā",
                  style: TdResTextStyles.h1.copyWith(
                    color: themeColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                TdResGaps.v_12,
                
                Text(
                  "Discover the wisdom of Sanskrit\ntexts, verses, and meanings",
                  textAlign: TextAlign.center,
                  style: TdResTextStyles.h5.copyWith(
                    color: themeColors.onSurface?.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: TdResDimens.dp_32),
                
                // Quick Access Modules
                _buildQuickAccessModules(),
              ],
            ),
            
            const SizedBox(height: TdResDimens.dp_50),
            

            
            const SizedBox(height: TdResDimens.dp_50),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHint(String emoji, String title, String subtitle) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: TdResDimens.dp_8),
        Text(
          title,
          style: TdResTextStyles.h6.copyWith(
            color: themeColors.onSurface?.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        TdResGaps.v_4,
        Text(
          subtitle,
          style: TdResTextStyles.caption.copyWith(
            color: themeColors.onSurface?.withOpacity(0.5),
          ),
        ),
      ],
    );
  }







  void _navigateToFeature(String route, {String? query}) async {
    // Navigate to feature with query context
    final fullRoute = UiConstants.Routes.getRoutePath(route);
    
    if (query != null && query.isNotEmpty) {
      // Set navigation context to indicate this came from search
      SearchNavigationContext.setFromSearch(route, query);
      
      // Navigate to module first
      Modular.to.pushNamed(fullRoute);
      
      // Schedule search execution after a delay to allow module to load
      Future.delayed(const Duration(milliseconds: 1000), () async {
        try {
          switch (route) {
            case '/word-define':
              print("🔍 Executing WordDefine search for: '$query'");
              final wordDefineController = Modular.get<WordDefineController>();
              await wordDefineController.onSearchDirectQuery(query);
              print("✅ WordDefine search completed");
              break;
              
            case '/verses':
              print("🔍 Executing Verses search for: '$query'");
              final versesController = Modular.get<VersesController>();
              await versesController.onSearchDirectQuery(query);
              print("✅ Verses search completed");
              break;
              
            case '/prashna':
              print("🔍 Executing Prashna search for: '$query'");
              final prashnaController = Modular.get<PrashnaController>();
              prashnaController.messageController.text = query;
              prashnaController.onMessageChanged(query);
              await prashnaController.sendMessage();
              print("✅ Prashna search completed");
              break;
              
            case '/books':
              print("🔍 Executing Books search for: '$query'");
              final booksController = Modular.get<BooksController>();
              await booksController.onSearchDirectQuery(query);
              print("✅ Books search completed");
              break;
              
            default:
              print("❌ No search handler for route: $route");
          }
        } catch (e) {
          print("Error executing search for $route: $e");
        }
      });
    } else {
      // Just navigate without search
      Modular.to.pushNamed(fullRoute);
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature - Coming Soon!"),
        backgroundColor: themeColors.primary,
      ),
    );
  }

  Widget _buildQuickAccessModules() {
    return Column(
      children: [
        // Section Title (smaller)
        Text(
          "Quick Access",
          style: TdResTextStyles.h5.copyWith(
            color: themeColors.onSurface?.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: TdResDimens.dp_12),
        
        // Module Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildModuleButton(
              icon: Icons.local_library_outlined,
              label: "Dictionary",
              color: const Color(0xFFE9A08E),
              onTap: () {
                // Set context for FAB to appear
                SearchNavigationContext.setFromSearch('/word-define', '');
                _navigateToFeature(UiConstants.Routes.wordDefine);
              },
            ),
            _buildModuleButton(
              icon: Icons.keyboard_command_key,
              label: "Verses",
              color: const Color(0xFF189565),
              onTap: () {
                // Set context for FAB to appear
                SearchNavigationContext.setFromSearch('/verses', '');
                _navigateToFeature(UiConstants.Routes.verse);
              },
            ),
            _buildModuleButton(
              icon: Icons.menu_book,
              label: "Books",
              color: Colors.blue,
              onTap: () => _navigateToFeature('/books'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
            color: color.withOpacity(0.04),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: TdResDimens.dp_6),
              Text(
                label,
                style: TdResTextStyles.p3.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Smart entity extraction for multi-entity queries
  List<String> _extractEntities(String query) {
    String cleanQuery = query.toLowerCase();
    
    // Remove question words and common phrases
    cleanQuery = cleanQuery.replaceAll(RegExp(r'\b(who is|what is|tell me about|and|the|of|in)\b'), ' ');
    cleanQuery = cleanQuery.replaceAll(RegExp(r'[^\w\s]'), ' '); // Remove punctuation
    cleanQuery = cleanQuery.replaceAll(RegExp(r'\s+'), ' ').trim(); // Clean spaces
    
    // Split into potential entities
    List<String> words = cleanQuery.split(' ').where((word) => word.length >= 3).toList();
    
    // Filter for likely Sanskrit/Hindu names and concepts
    List<String> entities = words.where((word) => _isLikelyEntity(word)).toList();
    
    return entities.isEmpty ? [cleanQuery] : entities;
  }
  
  bool _isLikelyEntity(String word) {
    // Common Sanskrit/Hindu names and concepts
    Set<String> knownEntities = {
      'rama', 'sita', 'krishna', 'hanuman', 'ganesha', 'shiva', 'vishnu', 'brahma',
      'lakshmi', 'saraswati', 'durga', 'kali', 'parvati', 'radha', 'arjuna', 'yudhishthira',
      'bhima', 'nakula', 'sahadeva', 'draupadi', 'dharma', 'karma', 'moksha', 'ahimsa',
      'yoga', 'vedas', 'gita', 'upanishad', 'ramayana', 'mahabharata', 'purana',
      'mantra', 'sanskrit', 'ayurveda', 'guru', 'ashrama', 'brahmin', 'kshatriya'
    };
    
    // Check if it's a known entity or looks like a Sanskrit name
    return knownEntities.contains(word.toLowerCase()) || 
           (word.length >= 3 && word.length <= 12 && RegExp(r'^[a-z]+$').hasMatch(word));
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
      margin: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0), // Reduced margin: left/right 12, top 8, bottom 4
      child: Row(
        children: List.generate(_tabLabels.length, (index) {
          final isSelected = index == _selectedTabIndex;
          final tabLabel = _tabLabels[index];
          final flexValue = tabFlexValues[tabLabel] ?? 2; // Default to 2 if not found
          
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
                
                // Update the active search module for navbar theming
                SearchNavigationContext.setActiveSearchModule(index);
                
                // Clear the tab switching flag after a short delay
                Future.delayed(const Duration(milliseconds: 100), () {
                  _isTabSwitching = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0), // Reduced from 12 to 8
                margin: EdgeInsets.only(right: index < _tabLabels.length - 1 ? 6.0 : 0), // Reduced from 8 to 6
                decoration: BoxDecoration(
                  color: isSelected ? _tabColors[index].withOpacity(0.1) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? _tabColors[index] : themeColors.onSurface?.withOpacity(0.3) ?? Colors.grey,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(6.0), // Reduced from 8 to 6
                ),
                child: Text(
                  _tabLabels[index],
                  textAlign: TextAlign.center,
                  maxLines: 1, // Prevent text wrapping
                  overflow: TextOverflow.ellipsis, // Add ellipsis if still too long
                  style: TdResTextStyles.h6.copyWith( // Changed from h5 to h6 for smaller text
                    color: isSelected ? _tabColors[index] : themeColors.onSurface,
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
    // Check if this module needs a search button (All modules now need search button)
    bool needsSearchButton = true; // All modules now require manual search
    
    return Container(
      margin: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 8.0), // Reduced margin and spacing
      decoration: BoxDecoration(
        color: themeColors.surface,
        border: Border.all(
          color: _tabColors[_selectedTabIndex],
          width: 1.5, // Reduced border width from 2.0 to 1.5
        ),
        borderRadius: BorderRadius.circular(10.0), // Reduced from 12.0 to 10.0
      ),
      child: Row(
        children: [
          // Search input field
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0), // Equal padding top/bottom
                              child: TextField(
                controller: _tabSearchControllers[_selectedTabIndex] ?? _searchController,
                focusNode: _searchFocus,
                onSubmitted: needsSearchButton ? (query) => _onManualSearch() : null,
                decoration: InputDecoration(
                  hintText: _getSearchHintText(_selectedTabIndex),
                  hintStyle: TdResTextStyles.h5.copyWith( // Changed from h4 to h5 for smaller text
                    color: themeColors.onSurfaceMedium,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0), // Equal top/bottom padding
                  prefixIcon: Icon(
                    Icons.search,
                    color: _tabColors[_selectedTabIndex],
                    size: 20.0, // Reduced icon size
                  ),
                  suffixIcon: (_tabSearchControllers[_selectedTabIndex]?.text.isNotEmpty ?? false)
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: themeColors.onSurfaceMedium,
                            size: 18.0, // Reduced icon size
                          ),
                          onPressed: () {
                            _tabSearchControllers[_selectedTabIndex]?.clear();
                            setState(() {
                              _hasSearched = false;
                              _isSearching = false;
                              _tabHasSearched[_selectedTabIndex] = false;
                              _tabIsSearching[_selectedTabIndex] = false;
                            });
                          },
                        )
                      : null,
                ),
                style: TdResTextStyles.h5.copyWith( // Changed from h4 to h5 for smaller text
                  color: themeColors.onSurface,
                ),
              ),
            ),
          ),
                     // Search button - always available
           if (needsSearchButton)
            Container(
              margin: const EdgeInsets.only(right: 6.0), // Reduced margin
              child: ElevatedButton(
                onPressed: _onManualSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tabColors[_selectedTabIndex],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, // Reduced from 16 to 12
                    vertical: 8.0,   // Reduced from 12 to 8
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0), // Reduced from 8 to 6
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 16), // Reduced icon size
                    SizedBox(width: 3), // Reduced spacing
                    Text(
                      'Search',
                      style: TdResTextStyles.h6.copyWith( // Smaller text
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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

  void _onManualSearch() {
    final query = _tabSearchControllers[_selectedTabIndex]?.text.trim() ?? '';
    if (query.isNotEmpty) {
      _performModuleSearch(query);
    }
  }

  Widget _buildContent() {
    final currentQuery = _tabSearchControllers[_selectedTabIndex]?.text ?? '';
    if (kDebugMode) {
      print("📱 _buildContent called: _isSearching=$_isSearching, _hasSearched=$_hasSearched, query='$currentQuery'");
    }
    
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: _tabColors[_selectedTabIndex],
            ),
            const SizedBox(height: 16.0),
            Text(
              'Searching in ${_tabLabels[_selectedTabIndex]}...',
              style: TdResTextStyles.h4.copyWith(
                color: themeColors.onSurfaceMedium,
              ),
            ),
          ],
        ),
      );
    }

         if (!_hasSearched || currentQuery.isEmpty) {
      if (kDebugMode) print("📱 _buildContent: Showing empty state");
       return _buildEmptyState();
     }

    if (kDebugMode) print("📱 _buildContent: Showing embedded page for tab $_selectedTabIndex");
    return _buildEmbeddedPage();
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32.0),
            
            // Welcome title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _getWelcomeTitle(_selectedTabIndex),
                textAlign: TextAlign.center,
                textScaler: const TextScaler.linear(1.0), // Prevent overflow
                style: TdResTextStyles.h1Bold.copyWith(
                  color: _tabColors[_selectedTabIndex],
                ),
              ),
            ),
            
            const SizedBox(height: 24.0),
            
            // Welcome description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _getWelcomeDescription(_selectedTabIndex),
                textAlign: TextAlign.center,
                textScaler: const TextScaler.linear(1.0), // Prevent overflow
                style: TdResTextStyles.h4Medium.copyWith(
                  color: themeColors.onSurfaceHigh,
                ),
              ),
            ),
            
            const SizedBox(height: 40.0),
            
            // Module icon
            Icon(
              _getModuleIcon(_selectedTabIndex),
              size: 48.0,
              color: _tabColors[_selectedTabIndex].withOpacity(0.6),
            ),
            
            const SizedBox(height: 32.0),
            
            // Language selection bar for QuickVerse (only show when QuickVerse tab is selected)
            if (_selectedTabIndex == 1) ...[
              _buildLanguageSelectionBar(),
              const SizedBox(height: 24.0),
            ],
          ],
        ),
      ),
    );
  }

  String _getWelcomeTitle(int tabIndex) {
    switch (tabIndex) {
      case 0: return "Welcome to \nWordDefine";
      case 1: return "Welcome to \nQuickVerse";
      case 2: return "Welcome to \nBooks";
      default: return "Welcome";
    }
  }

  String _getWelcomeDescription(int tabIndex) {
    switch (tabIndex) {
      case 0: return "Discover the depth and meaning of Sanskrit words. Search for definitions, etymology, and contextual usage.";
      case 1: return "Do you have a shloka, mantra, verse or a kriti humming in your mind? Search for it here. Just enter the parts you remember to get started!";
      case 2: return "Search and explore ancient texts and scriptures from various traditions and sources.";
      default: return "Start your search journey";
    }
  }

  String _getSearchHintText(int tabIndex) {
    switch (tabIndex) {
      case 0: return "Type a single word to search...";
      case 1: return "Type partial verse to search...";
      case 2: return "Ask a question...";
      default: return "Search...";
    }
  }

  Widget _buildEmbeddedPage() {
    print("📱 _buildEmbeddedPage called for tab index: $_selectedTabIndex");
    
    // After search is performed, show the embedded page component with hidden search bar and welcome message
    switch (_selectedTabIndex) {
      case 0: // WordDefine
        print("📱 Building embedded WordDefinePage");
        return WordDefinePage(
          mRequestArgs: WordDefineArgsRequest(
            default1: "embedded_search",
            hideSearchBar: true,
            hideWelcomeMessage: true,
          ),
        );
      case 1: // QuickVerse
        print("📱 Building embedded VersesPage");
        return VersesPage(
          mRequestArgs: VersesArgsRequest(
            default1: "embedded_search",
            hideSearchBar: true,
            hideWelcomeMessage: true,
          ),
        );
      case 2: // Books
        print("📱 Building embedded BooksPage");
        return BooksPage(
          mRequestArgs: BooksArgsRequest(
            default1: "embedded_search",
            hideSearchBar: true,
            hideWelcomeMessage: true,
          ),
        );
      case 3: // Unified
        print("📱 Building embedded Unified Page");
        return _buildUnifiedPage();
      default:
        print("📱 Building default module message");
        return Center(
          child: Text(
            'Select a module to search',
            style: TdResTextStyles.h4.copyWith(
              color: themeColors.onSurfaceMedium,
            ),
          ),
        );
    }
  }

  Widget _buildModuleResults() {
    print("📱 _buildModuleResults called for tab index: $_selectedTabIndex");
    
    switch (_selectedTabIndex) {
      case 0: // WordDefine
        print("📱 Building WordDefine results");
        return _buildWordDefineResults();
      case 1: // QuickVerse
        if (kDebugMode) print("📱 Building QuickVerse results");  
        return _buildQuickVerseResults();
      case 2: // Books
        print("📱 Building Books results");
        return _buildBooksResults();
      case 3: // Unified
        print("📱 Building Unified results");
        return _buildUnifiedResults();
      default:
        print("📱 Building default module message");
        return Center(
          child: Text(
            'Select a module to search',
            style: TdResTextStyles.h4.copyWith(
              color: themeColors.onSurfaceMedium,
            ),
          ),
        );
    }
  }

  Widget _buildWordDefineResults() {
    try {
      // 🚀 PERFORMANCE FIX: Debug logging only in debug mode
      if (kDebugMode) {
        print("📱 _buildWordDefineResults called");
        print("📱 WordDefine Controller Instance: ${wordDefineController.hashCode}");
        print("📱 WordDefine Controller State: isLoading=${wordDefineController.state.isLoading}");
        print("📱 WordDefine Controller State: definitions count=${wordDefineController.state.dictWordDefinitions?.details.definitions?.length ?? 0}");
      }
      
      return BlocBuilder<WordDefineController, WordDefineCubitState>(
        bloc: wordDefineController,
        buildWhen: (previous, current) {
          // 🚀 PERFORMANCE FIX: Optimized rebuild conditions and debug logging
          final shouldRebuild = previous.isLoading != current.isLoading ||
                 previous.dictWordDefinitions != current.dictWordDefinitions ||
                 previous.searchCounter != current.searchCounter;
          
          if (kDebugMode && shouldRebuild) {
            print("📱 WordDefine BlocBuilder rebuilding: loading=${current.isLoading}, defs=${current.dictWordDefinitions?.details.definitions?.length}");
          }
          
          return shouldRebuild;
        },
        builder: (context, state) {
          if (kDebugMode) {
            print("📱 WordDefine BlocBuilder: isLoading=${state.isLoading}, definitions=${state.dictWordDefinitions?.details.definitions?.length ?? 0}");
          }
          
          if (state.isLoading == true) {
            return Center(
              child: CircularProgressIndicator(
                color: _tabColors[0],
              ),
            );
          }

          final definitions = state.dictWordDefinitions?.details.definitions ?? [];
          print("📱 WordDefine: Found ${definitions.length} definitions");
          
          if (definitions.isEmpty) {
            print("📱 WordDefine: Showing empty state");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: themeColors.onSurfaceMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No definitions found',
                    style: TdResTextStyles.h4.copyWith(
                      color: themeColors.onSurfaceMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'State: ${state.dictWordDefinitions != null ? "Has data" : "No data"}',
                    style: TdResTextStyles.h6.copyWith(
                      color: themeColors.onSurfaceMedium,
                    ),
                  ),
                ],
              ),
            );
          }
          
          print("📱 WordDefine: Building results list with ${definitions.length} items");

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: definitions.length,
            itemBuilder: (context, index) {
              final definition = definitions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        definition.text,
                        style: TdResTextStyles.h3.copyWith(
                          color: _tabColors[0],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        definition.shortText,
                        style: TdResTextStyles.h4.copyWith(
                          color: themeColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      return Center(
        child: Text(
          'WordDefine module not available',
          style: TdResTextStyles.h4.copyWith(
            color: themeColors.onSurfaceMedium,
          ),
        ),
      );
    }
  }

  Widget _buildQuickVerseResults() {
    try {
      return BlocBuilder<VersesController, VersesCubitState>(
        bloc: versesController,
        buildWhen: (previous, current) {
          // 🚀 PERFORMANCE FIX: Optimized rebuild conditions 
          final shouldRebuild = previous.isLoading != current.isLoading ||
                 previous.verseList != current.verseList ||
                 previous.verseLanguagePref != current.verseLanguagePref ||
                 previous.searchSequestCounter != current.searchSequestCounter;
          
          if (kDebugMode && shouldRebuild) {
            print("📱 QuickVerse rebuilding: loading=${current.isLoading}, verses=${current.verseList.length}, lang=${current.verseLanguagePref?.output}");
          }
          
          return shouldRebuild;
        },
        builder: (context, state) {
          if (kDebugMode) {
            print("📱 QuickVerse BlocBuilder: isLoading=${state.isLoading}, verses=${state.verseList.length}, lang=${state.verseLanguagePref?.output}");
          }
          
          if (state.isLoading == true || (_selectedTabIndex == 1 && _isSearching)) {
            return Center(
              child: CircularProgressIndicator(
                color: _tabColors[1],
              ),
            );
          }

          if (state.verseList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: themeColors.onSurfaceMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No verses found',
                    style: TdResTextStyles.h4.copyWith(
                      color: themeColors.onSurfaceMedium,
                    ),
                  ),
                ],
              ),
            );
          }

          if (kDebugMode) print("🟢 QUICKVERSE: Building QuickVerse results with ${state.verseList.length} verses");
          return Column(
            children: [
              // Verses list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.verseList.length,
                  itemBuilder: (context, index) {
                    final verse = state.verseList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (verse.verseRef.isNotEmpty)
                              Text(
                                verse.verseRef,
                                style: TdResTextStyles.h5.copyWith(
                                  color: _tabColors[1],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 8),
                      VerseText(
                        verse.verseText,
                        style: TdResTextStyles.h4.copyWith(
                          color: themeColors.onSurface,
                        ),
                        language: _getCurrentLanguage(),
                      ),
                      if (verse.verseLetText != null && verse.verseLetText!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        VerseText(
                          verse.verseLetText!,
                          style: TdResTextStyles.h5.copyWith(
                            color: themeColors.onSurfaceMedium,
                            fontStyle: FontStyle.italic,
                          ),
                          language: _getCurrentLanguage(),
                        ),
                      ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      return Center(
        child: Text(
          'QuickVerse module not available',
          style: TdResTextStyles.h4.copyWith(
            color: themeColors.onSurfaceMedium,
          ),
        ),
      );
    }
  }

  Widget _buildBooksResults() {
    try {
      return BlocBuilder<BooksController, BooksCubitState>(
        bloc: booksController,
        builder: (context, state) {
          if (state.isLoading == true) {
            return Center(
              child: CircularProgressIndicator(
                color: _tabColors[2],
              ),
            );
          }

          if (state.bookChunks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: themeColors.onSurfaceMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No books found',
                    style: TdResTextStyles.h4.copyWith(
                      color: themeColors.onSurfaceMedium,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.bookChunks.length,
            itemBuilder: (context, index) {
              final book = state.bookChunks[index];
              return BookChunkItemLightweightWidget(
                chunk: _convertChunk(book),
                onSourceClick: (url) async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                onNavigateNext: () => _handleNextChunk(book),
                onNavigatePrevious: () => _handlePreviousChunk(book),
              );
            },
          );
        },
      );
    } catch (e) {
      return Center(
        child: Text(
          'Books module not available',
          style: TdResTextStyles.h4.copyWith(
            color: themeColors.onSurfaceMedium,
          ),
        ),
      );
    }
  }

  IconData _getModuleIcon(int index) {
    switch (index) {
      case 0: return Icons.local_library_outlined; // WordDefine
      case 1: return Icons.keyboard_command_key; // QuickVerse (command key)
      case 2: return Icons.menu_book; // Books
      default: return Icons.search;
    }
  }

  String _getModuleDescription(int index) {
    switch (index) {
      case 0: return 'Find definitions and meanings';
      case 1: return 'Discover verses and quotes';
      case 2: return 'Explore books and texts';
      default: return 'Start searching';
    }
  }

  /// Language selection bar for QuickVerse welcome screen - exactly like QuickVerse page
  Widget _buildLanguageSelectionBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: EdgeInsets.symmetric(
        horizontal: TdResDimens.dp_8,
        vertical: TdResDimens.dp_6, // Minimal vertical padding
      ),
      decoration: BoxDecoration(
        color: themeColors.primary.withAlpha(0x20), // Faint green background
        borderRadius: BorderRadius.circular(TdResDimens.dp_6),
        border: Border.all(
          color: themeColors.primary.withAlpha(0x1A), // Faint green border
          width: 0.5,
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
                  color: themeColors.primary, // Faint green icon
                ),
                SizedBox(width: TdResDimens.dp_4),
                Flexible(
                  child: Text(
                    "Transcription by Aksharamukha",
                    style: TdResTextStyles.caption.copyWith(
                      color: themeColors.primary, // Faint green text
                      fontWeight: FontWeight.w600, // Normal weight, not bold
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: TdResDimens.dp_8),
          
          // Right side: Language selector (fixed width)
          _buildCompactLanguageSelector(),
        ],
      ),
    );
  }

  /// Compact language selector for the Aksharamukha bar - exactly like QuickVerse page
  Widget _buildCompactLanguageSelector() {
    final dashboardController = Modular.get<DashboardController>();

    return BlocBuilder<VersesController, VersesCubitState>(
      bloc: versesController,
      buildWhen: (previous, current) =>
          current.verseLanguagePref != previous.verseLanguagePref,
      builder: (context, state) {
        final currentLanguage = state.verseLanguagePref?.output ?? VersesConstants.LANGUAGE_DEFAULT;
        
        return PopupMenuButton<String>(
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
                  _getLanguageLabel(currentLanguage),
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
          onSelected: (String value) async {
            print("🌐 LANGUAGE SELECTOR: User selected language '$value'");
            print("🌐 LANGUAGE SELECTOR: Current tab index: $_selectedTabIndex");
            print("🌐 LANGUAGE SELECTOR: Tab search states: $_tabHasSearched");
            print("🌐 LANGUAGE SELECTOR: Tab search queries: ${_tabSearchControllers.map((k, v) => MapEntry(k, v.text))}");
            
            // If we have verse results cached (regardless of current tab),
            // silently refresh the search with the new language BEFORE dashboard change
            final quickVerseQuery = _tabSearchControllers[1]?.text.trim() ?? '';
            final hasQuickVerseResults = (_tabHasSearched[1] ?? false) && quickVerseQuery.isNotEmpty;
            
            if (hasQuickVerseResults) {
              print("🔄 Language changing to '$value', refreshing verse search silently");
              print("🔄 QuickVerse query: '$quickVerseQuery', isOnQuickVerseTab: ${_selectedTabIndex == 1}");
              
              // Show loading state only if currently on QuickVerse tab
              if (_selectedTabIndex == 1) {
                setState(() {
                  _isSearching = true;
                  _tabIsSearching[1] = true;
                });
              }
              
              try {
                // First trigger the language change
                dashboardController.onVerseLanguageChange(value);
                print("🌐 LANGUAGE SELECTOR: Dashboard language change triggered");
                
                // Wait for language change to propagate
                await Future.delayed(const Duration(milliseconds: 500));
                
                // Perform silent search in background with updated language
                print("🔄 Performing silent verse search for query: '$quickVerseQuery'");
                await _searchInQuickVerse(quickVerseQuery);
                print("✅ Verse search refreshed for new language: $value");
              } catch (e) {
                print("❌ Error refreshing verse search: $e");
              } finally {
                // Reset searching state only if currently on QuickVerse tab
                if (_selectedTabIndex == 1 && mounted) {
                  setState(() {
                    _isSearching = false;
                    _tabIsSearching[1] = false;
                  });
                } else if (mounted) {
                  // Update tab-specific state even if not on current tab
                  _tabIsSearching[1] = false;
                }
              }
            } else {
              // No cached results, just change language normally
              dashboardController.onVerseLanguageChange(value);
              print("🌐 LANGUAGE SELECTOR: Dashboard language change triggered (no cached results)");
            }
          },
          itemBuilder: (context) => _getSupportedLanguages().entries.map<PopupMenuItem<String>>((entry) {
            return PopupMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: TdResTextStyles.buttonSmall.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
            );
          }).toList(),
          offset: Offset(0, 25),
          color: themeColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        );
      },
    );
  }

  /// Get supported languages with fallback (copied from VersesPage)
  Map<String, String> _getSupportedLanguages() {
    try {
      return Modular.get<SupportedLanguagesService>().getSupportedLanguages();
    } catch (e) {
      // Fallback to sorted static list if service unavailable
      return Map.fromEntries(
        VersesConstants.LANGUAGE_LABELS_MAP.entries
          .where((entry) => entry.value != null)
          .map((entry) => MapEntry(entry.key, entry.value!))
          .toList()
          ..sort((a, b) => a.value.compareTo(b.value))
      );
    }
  }

  /// Get language label from constants (copied from VersesPage)
  String _getLanguageLabel(String language) {
    return VersesConstants.LANGUAGE_LABELS_MAP[language] ?? language;
  }
  
  // Unified tab methods
  Widget _buildUnifiedPage() {
    final currentQuery = _tabSearchControllers[_selectedTabIndex]?.text ?? _searchController.text;
    return UnifiedSearchPage(
      hideSearchBar: true,
      hideWelcomeMessage: false,
      query: currentQuery.isNotEmpty ? currentQuery : null,
    );
  }
  
  Widget _buildUnifiedResults() {
    final currentQuery = _tabSearchControllers[_selectedTabIndex]?.text ?? _searchController.text;
    return UnifiedSearchPage(
      hideSearchBar: true,
      hideWelcomeMessage: true,
      query: currentQuery.isNotEmpty ? currentQuery : null,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _fadeController.dispose();
    _debounceTimer?.cancel();
    
    // Dispose tab-specific controllers
    for (var controller in _tabSearchControllers.values) {
      controller.dispose();
    }
    
    // Cancel language change subscription
    _languageChangeSubscription?.cancel();
    
    super.dispose();
  }

  /// Convert old BookChunkRM format to new format for the widget
  new_book_chunk.BookChunkRM _convertChunk(book) {
    return new_book_chunk.BookChunkRM(
      text: book.text,
      chunkRefId: book.chunkRefId,
      score: book.score,
      reference: book.reference,
      // Old format doesn't have these fields, so set to null for now
      sourceTitle: null,
      sourceUrl: null,
      sourceType: null,
    );
  }

  /// 🔄 Handle previous chunk navigation
  void _handlePreviousChunk(book) {
    if (book.chunkRefId == null) return;
    
    print('🔍 Search: Navigate to previous chunk from: ${book.chunkRefId}');
    
    // Use BooksService to handle navigation
    final booksService = BooksService.instance;
    booksService.navigateChunk(book.chunkRefId!, false);
  }

  /// ⏭️ Handle next chunk navigation  
  void _handleNextChunk(book) {
    if (book.chunkRefId == null) return;
    
    print('🔍 Search: Navigate to next chunk from: ${book.chunkRefId}');
    
    // Use BooksService to handle navigation
    final booksService = BooksService.instance;
    booksService.navigateChunk(book.chunkRefId!, true);
  }
}