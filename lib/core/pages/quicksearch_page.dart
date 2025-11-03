import 'dart:async';
import 'package:dharak_flutter/app/tools/route/route_change_notifier.dart';
import 'package:dharak_flutter/app/types/dictionary/definition.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/types/books/book_chunk.dart';
import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/core/components/verse_card.dart';
import 'package:dharak_flutter/core/components/word_definition_card.dart';
import 'package:dharak_flutter/app/ui/pages/books/parts/item_lightweight.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dharak_flutter/core/controllers/quicksearch_controller.dart';
import 'package:dharak_flutter/core/services/verse_service.dart';
import 'package:dharak_flutter/core/services/books_service.dart';
import 'package:dharak_flutter/app/ui/widgets/code_wrapper.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:provider/provider.dart';

/// QuickSearch page with optimized search for WordDefine and QuickVerse
class QuickSearchPage extends StatefulWidget {
  const QuickSearchPage({super.key});

  @override
  State<QuickSearchPage> createState() => _QuickSearchPageState();
}

class _QuickSearchPageState extends State<QuickSearchPage> {
  late QuickSearchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Modular.get<QuickSearchController>();
    
    // Update tab to notify dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RouteChangeNotifier>(
        context,
        listen: false,
      ).updateTab(UiConstants.Tabs.quicksearch);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _controller,
      child: const _QuickSearchView(),
    );
  }
}

class _QuickSearchView extends StatefulWidget {
  const _QuickSearchView();

  @override
  State<_QuickSearchView> createState() => _QuickSearchViewState();
}

class _QuickSearchViewState extends State<_QuickSearchView> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasText = false;
  SearchType? _lastSearchType;
  
  @override
  void initState() {
    super.initState();
    // Listen to text changes to show/hide clear button
    _searchController.addListener(() {
      final hasText = _searchController.text.isNotEmpty;
      if (hasText != _hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    });
  }
  late AppThemeColors themeColors;
  late AppThemeDisplay appThemeDisplay;
  Timer? _debounceTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prepareTheme();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _prepareTheme() {
    themeColors = Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: const Color(0xFF6CE18D), isDark: false);
    appThemeDisplay = TdThemeHelper.prepareThemeDisplay(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeColors.surface,
      body: Column(
        children: [
          // Search type selector
          _buildSearchTypeSelector(),
          
          // Search bar
          _buildSearchBar(),
          
          // Results area
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchTypeSelector() {
    return BlocBuilder<QuickSearchController, QuickSearchState>(
      buildWhen: (prev, curr) => prev.currentSearchType != curr.currentSearchType,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildSearchTypeButton(
                  searchType: SearchType.wordDefine,
                  label: 'WordDefine',
                  icon: Icons.book_outlined,
                  selectedIcon: Icons.book,
                  isSelected: state.currentSearchType == SearchType.wordDefine,
                  onTap: () => BlocProvider.of<QuickSearchController>(context)
                      .switchSearchType(SearchType.wordDefine),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSearchTypeButton(
                  searchType: SearchType.quickVerse,
                  label: 'QuickVerse',
                  icon: Icons.format_quote_outlined,
                  selectedIcon: Icons.format_quote,
                  isSelected: state.currentSearchType == SearchType.quickVerse,
                  onTap: () => BlocProvider.of<QuickSearchController>(context)
                      .switchSearchType(SearchType.quickVerse),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSearchTypeButton(
                  searchType: SearchType.books,
                  label: 'Books',
                  icon: Icons.menu_book_outlined,
                  selectedIcon: Icons.menu_book,
                  isSelected: state.currentSearchType == SearchType.books,
                  onTap: () => BlocProvider.of<QuickSearchController>(context)
                      .switchSearchType(SearchType.books),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchTypeButton({
    required SearchType searchType,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected 
        ? themeColors.primary 
        : themeColors.onSurfaceDisable;
    
    final backgroundColor = isSelected
        ? themeColors.primary.withAlpha(0x20)
        : Colors.transparent;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? themeColors.primary : themeColors.onSurfaceDisable,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TdResTextStyles.button.copyWith(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return BlocBuilder<QuickSearchController, QuickSearchState>(
      buildWhen: (prev, curr) => 
          prev.currentSearchType != curr.currentSearchType,
      builder: (context, state) {
        // Only clear text when search type changes (not on every rebuild)
        if (_lastSearchType != null && _lastSearchType != state.currentSearchType) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _searchController.clear();
            setState(() {
              _hasText = false;
            });
          });
        }
        _lastSearchType = state.currentSearchType;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              // Just update text, don't trigger search automatically
            },
            onSubmitted: (value) {
              // Trigger search when user presses enter
              if (value.trim().isNotEmpty) {
                BlocProvider.of<QuickSearchController>(context).performSearch(value.trim());
              }
            },
            decoration: InputDecoration(
              hintText: _getSearchHint(state.currentSearchType),
              prefixIcon: Icon(
                Icons.search,
                color: themeColors.onSurfaceDisable,
              ),
              suffixIcon: SizedBox(
                width: _hasText ? 96 : 48, // Dynamic width based on buttons
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Search button - always visible
                    IconButton(
                      icon: Icon(
                        Icons.search,
                        color: themeColors.primary,
                      ),
                      onPressed: () {
                        final query = _searchController.text.trim();
                        if (query.isNotEmpty) {
                          BlocProvider.of<QuickSearchController>(context).performSearch(query);
                        }
                      },
                    ),
                    // Clear button - only when text exists
                    if (_hasText)
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: themeColors.onSurfaceDisable,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _hasText = false;
                          });
                          BlocProvider.of<QuickSearchController>(context).clearSearch();
                        },
                      ),
                  ],
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeColors.onSurfaceDisable),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeColors.primary, width: 2),
              ),
              filled: true,
              fillColor: themeColors.surface,
            ),
          ),
        );
      },
    );
  }

  String _getSearchHint(SearchType searchType) {
    switch (searchType) {
      case SearchType.wordDefine:
        return 'Type a single word to search...';
      case SearchType.quickVerse:
        return 'Type partial verse to search...';
      case SearchType.books:
        return 'Enter phrase to search or Ask a question ...';
      case SearchType.unified:
        return 'Enter phrase to search or Ask a question ...';
    }
  }

  Widget _buildSearchResults() {
    return BlocBuilder<QuickSearchController, QuickSearchState>(
      buildWhen: (prev, curr) =>
          prev.currentSearchType != curr.currentSearchType ||
          prev.isLoading != curr.isLoading ||
          prev.error != curr.error ||
          prev.wordDefineResult != curr.wordDefineResult ||
          prev.verseResults != curr.verseResults ||
          prev.bookResults != curr.bookResults ||
          prev.searchCounter != curr.searchCounter,
      builder: (context, state) {
        // Loading state
        if (state.isLoading) {
          return _buildLoadingState(state.currentSearchType);
        }

        // Error state
        if (state.error != null) {
          return _buildErrorState(state.error!);
        }

        // Empty state
        if (state.searchQuery.isEmpty) {
          return _buildEmptyState(state.currentSearchType);
        }

        // Results
        switch (state.currentSearchType) {
          case SearchType.wordDefine:
            return _buildWordDefineResults(state.wordDefineResult);
          case SearchType.quickVerse:
            return _buildVerseResults(state.verseResults);
          case SearchType.books:
            return _buildBookResults(state.bookResults);
          case SearchType.unified:
            return _buildUnifiedMessage();
        }
      },
    );
  }

  Widget _buildLoadingState(SearchType searchType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: themeColors.primary),
          const SizedBox(height: 16),
          Text(
            'Searching ${_getSearchTypeLabel(searchType)}...',
            style: TdResTextStyles.h5.copyWith(color: themeColors.onSurfaceDisable),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
            'Search Failed',
            style: TdResTextStyles.h4.copyWith(color: themeColors.errorColor),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TdResTextStyles.p1.copyWith(color: themeColors.onSurfaceDisable),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(SearchType searchType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getSearchTypeIcon(searchType),
            size: 64,
            color: themeColors.onSurfaceDisable,
          ),
          const SizedBox(height: 16),
          Text(
            'Search ${_getSearchTypeLabel(searchType)}',
            style: TdResTextStyles.h4.copyWith(color: themeColors.onSurfaceDisable),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a search term to find ${_getSearchTypeLabel(searchType).toLowerCase()}',
            style: TdResTextStyles.p1.copyWith(color: themeColors.onSurfaceDisable),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWordDefineResults(dynamic wordDefineResult) {
    if (wordDefineResult == null || wordDefineResult.details.definitions.isEmpty) {
      return _buildNoResultsState('word definitions');
    }

    final definitions = wordDefineResult.details.definitions as List<WordDefinitionRM>;
    
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${definitions.length} definition${definitions.length == 1 ? '' : 's'} found',
            style: TdResTextStyles.h5.copyWith(color: themeColors.onSurfaceHigh),
          ),
        ),
        
        // LLM Summary at the top level (outside of individual cards)
        if (wordDefineResult.details.llmDef != null && wordDefineResult.details.llmDef!.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(
              maxHeight: 300, // Prevent extremely tall LLM summaries
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
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
                        child: const Icon(Icons.chat_bubble_outline),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          "LLM Summary",
                          style: TdResTextStyles.h4Medium.copyWith(
                            color: themeColors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  TdResGaps.v_12,
                  _buildMarkdown(wordDefineResult.details.llmDef!, themeColors),
                ],
              ),
            ),
          ),
        
        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: definitions.length,
            itemBuilder: (context, index) {
              return WordDefinitionCard(
                definition: definitions[index],
                themeColors: themeColors,
                appThemeDisplay: appThemeDisplay,
                // All interactive features enabled (but NO LLM Summary per card)
                showSource: true,
                showLLMSummary: false, // Disable LLM Summary in individual cards
                isExpandable: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVerseResults(List<VerseRM> verses) {
    if (verses.isEmpty) {
      return _buildNoResultsState('verses');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${verses.length} verse${verses.length == 1 ? '' : 's'} found',
            style: TdResTextStyles.h5.copyWith(color: themeColors.onSurfaceHigh),
          ),
        ),
        
        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: verses.length,
            itemBuilder: (context, index) {
              return VerseCard(
                verse: verses[index],
                themeColors: themeColors,
                appThemeDisplay: appThemeDisplay,
                // All interactive features enabled
                showNavigation: true,
                showBookmark: true,
                showSource: true,
                showOtherFields: true,
                // Provide navigation callbacks that use our VerseService
                onPrevious: () => VerseService.instance.navigateVerse(verses[index].versePk, false),
                onNext: () => VerseService.instance.navigateVerse(verses[index].versePk, true),
                onBookmark: () => VerseService.instance.toggleBookmark(verses[index].versePk),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoResultsState(String contentType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: themeColors.onSurfaceDisable,
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: TdResTextStyles.h4.copyWith(color: themeColors.onSurfaceDisable),
          ),
          const SizedBox(height: 8),
          Text(
            'No $contentType found for your search',
            style: TdResTextStyles.p1.copyWith(color: themeColors.onSurfaceDisable),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookResults(List<BookChunkRM> bookChunks) {
    if (bookChunks.isEmpty) {
      return _buildNoResultsState('book chunks');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with share button (like in the image)
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Book Chunks',
                style: TdResTextStyles.h4.copyWith(color: themeColors.onSurface),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: themeColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.share,
                      size: 16,
                      color: themeColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Share',
                      style: TdResTextStyles.p2.copyWith(
                        color: themeColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Book chunks list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: bookChunks.length,
            itemBuilder: (context, index) {
              return BookChunkItemLightweightWidget(
                chunk: bookChunks[index],
                searchQuery: _searchController.text.trim(), // ✅ Pass search query for share functionality
                onSourceClick: (url) async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                onNavigateNext: () => _handleNextChunk(bookChunks[index]),
                onNavigatePrevious: () => _handlePreviousChunk(bookChunks[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  // Book chunk action handlers
  void _handleCopyChunk(BookChunkRM chunk) {
    // TODO: Implement copy to clipboard
  }

  void _handleShareChunk(BookChunkRM chunk) {
    // TODO: Implement share functionality
  }

  void _handleReferenceClick(String reference) {
    // TODO: Implement reference navigation
  }

  Widget _buildUnifiedMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 64,
              color: themeColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Unified Search Available',
              style: TdResTextStyles.h4.copyWith(
                color: themeColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the dedicated Unified tab for comprehensive search across Dictionary, Verses, and Books simultaneously.',
              style: TdResTextStyles.p1.copyWith(
                color: themeColors.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getSearchTypeLabel(SearchType searchType) {
    switch (searchType) {
      case SearchType.wordDefine:
        return 'Word Definitions';
      case SearchType.quickVerse:
        return 'Verses';
      case SearchType.books:
        return 'Book Chunks';
      case SearchType.unified:
        return 'Unified Search';
    }
  }

  IconData _getSearchTypeIcon(SearchType searchType) {
    switch (searchType) {
      case SearchType.wordDefine:
        return Icons.book_outlined;
      case SearchType.quickVerse:
        return Icons.format_quote_outlined;
      case SearchType.books:
        return Icons.menu_book_outlined;
      case SearchType.unified:
        return Icons.auto_awesome_outlined;
    }
  }

  Widget _buildMarkdown(String content, AppThemeColors themeColors) {
    final config = themeColors.isDark 
        ? MarkdownConfig.darkConfig 
        : MarkdownConfig.defaultConfig;
        
    Widget codeWrapper(child, text, language) =>
        MarkdownCodeWrapperWidget(child, text, language);

    return MarkdownWidget(
      data: content,
      shrinkWrap: true,
      selectable: true,
      config: config.copy(
        configs: [
          themeColors.isDark
              ? PreConfig.darkConfig.copy(wrapper: codeWrapper)
              : PreConfig().copy(wrapper: codeWrapper),
        ],
      ),
    );
  }

  /// 🔄 Handle previous chunk navigation
  void _handlePreviousChunk(bookChunk) {
    if (bookChunk.chunkRefId == null) return;
    
    
    // Use BooksService to handle navigation
    final booksService = BooksService.instance;
    booksService.navigateChunk(bookChunk.chunkRefId!, false);
  }

  /// ⏭️ Handle next chunk navigation  
  void _handleNextChunk(bookChunk) {
    if (bookChunk.chunkRefId == null) return;
    
    
    // Use BooksService to handle navigation
    final booksService = BooksService.instance;
    booksService.navigateChunk(bookChunk.chunkRefId!, true);
  }
}
