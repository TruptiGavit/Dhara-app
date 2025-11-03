import 'package:dharak_flutter/app/types/unified/unified_response.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/core/components/tool_card.dart';
import 'package:dharak_flutter/core/controllers/unified_controller.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class UnifiedPage extends StatefulWidget {
  const UnifiedPage({Key? key}) : super(key: key);

  @override
  State<UnifiedPage> createState() => _UnifiedPageState();
}

class _UnifiedPageState extends State<UnifiedPage> {
  late TextEditingController _searchController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _searchController.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;

    return BlocProvider<UnifiedController>(
      create: (_) {
        final controller = Modular.get<UnifiedController>();
        return controller;
      },
      child: Scaffold(
        backgroundColor: themeColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchSection(themeColors),
              Expanded(
                child: _buildResultsSection(themeColors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(AppThemeColors themeColors) {
    return Container(
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
      child: Column(
        children: [
          // Minimalist Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unified Search',
                        style: TdResTextStyles.h3.copyWith(
                          color: themeColors.onSurface,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Smart search across all content',
                        style: TdResTextStyles.p3.copyWith(
                          color: themeColors.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Compact Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: themeColors.onSurface.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search across all content...',
                  hintStyle: TdResTextStyles.p1.copyWith(
                    color: themeColors.onSurfaceDisable,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.search_rounded,
                      color: const Color(0xFFFF6B35).withOpacity(0.6),
                      size: 18,
                    ),
                  ),
                suffixIcon: _hasText
                    ? Container(
                        padding: const EdgeInsets.only(right: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Orange Search button
                            Builder(
                              builder: (searchContext) => Container(
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  onPressed: () => _performSearch(searchContext),
                                  tooltip: 'Search',
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ),
                            ),
                            // Clear button
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: themeColors.onSurfaceDisable,
                                size: 16,
                              ),
                              onPressed: _clearSearch,
                              tooltip: 'Clear',
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _performSearch(),
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
          
          // Action buttons
          BlocBuilder<UnifiedController, UnifiedState>(
            buildWhen: (prev, curr) => 
                prev.searchResults.length != curr.searchResults.length ||
                prev.isLoading != curr.isLoading,
            builder: (context, state) {
              if (state.searchResults.isEmpty && !state.isLoading) {
                return const SizedBox.shrink();
              }
              
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    if (state.searchResults.isNotEmpty) ...[
                      Text(
                        '${state.searchResults.length} search${state.searchResults.length != 1 ? 'es' : ''}',
                        style: TdResTextStyles.p3.copyWith(
                          color: themeColors.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => BlocProvider.of<UnifiedController>(context).clearAllResults(),
                        icon: Icon(
                          Icons.clear_all,
                          size: 16,
                          color: themeColors.onSurface.withOpacity(0.7),
                        ),
                        label: Text(
                          'Clear All',
                          style: TdResTextStyles.p2.copyWith(
                            color: themeColors.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(AppThemeColors themeColors) {
    return BlocBuilder<UnifiedController, UnifiedState>(
      buildWhen: (prev, curr) => 
          prev.searchResults != curr.searchResults ||
          prev.isLoading != curr.isLoading ||
          prev.error != curr.error ||
          prev.searchCounter != curr.searchCounter,
      builder: (context, state) {
        if (state.isLoading && state.searchResults.isEmpty) {
          return _buildLoadingState(themeColors);
        }

        if (state.error != null && state.searchResults.isEmpty) {
          return _buildErrorState(themeColors, state.error!);
        }

        if (state.searchResults.isEmpty) {
          return _buildEmptyState(themeColors);
        }

        return _buildSearchResults(themeColors, state);
      },
    );
  }

  Widget _buildSearchResults(AppThemeColors themeColors, UnifiedState state) {
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

    return Container(
      color: themeColors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
        children: [
          // Current Search Results Section
          if (currentResults.isNotEmpty) ...[
            _buildCoreUnifiedSectionHeader(themeColors, 'Current Search', Icons.search, currentResults.length),
            const SizedBox(height: 8),
            ...currentResults.asMap().entries.map((entry) {
              final index = entry.key;
              final result = entry.value;
              final showStreamingIndicator = state.isStreaming && index == 0;
              return _buildCoreUnifiedResultItem(result, themeColors, false, showStreamingIndicator);
            }),
          ],
          
          // Previous Searches Section (Expandable)
          if (previousResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCoreUnifiedPreviousSearchesSection(themeColors, previousResults),
          ],
        ],
      ),
    );
  }

  Widget _buildCoreUnifiedSectionHeader(AppThemeColors themeColors, String title, IconData icon, int count) {
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

  Widget _buildCoreUnifiedPreviousSearchesSection(AppThemeColors themeColors, List<UnifiedSearchResult> previousResults) {
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
          ...previousResults.map((result) => _buildCoreUnifiedResultItem(result, themeColors, true, false)),
        ],
      ),
    );
  }

  Widget _buildCoreUnifiedResultItem(UnifiedSearchResult result, AppThemeColors themeColors, bool isGreyedOut, bool showLoading) {
    final controller = BlocProvider.of<UnifiedController>(context);
    final tools = controller.getExpandableTools(result);

    return Column(
      children: [
        // Search result header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                size: 14,
                color: isGreyedOut 
                    ? themeColors.onSurface.withOpacity(0.4)
                    : themeColors.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Text(
                _formatTimestamp(result.timestamp),
                style: TdResTextStyles.p3.copyWith(
                  color: isGreyedOut 
                      ? themeColors.onSurface.withOpacity(0.4)
                      : themeColors.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 8),
              if (isGreyedOut)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: themeColors.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Previous',
                    style: TdResTextStyles.caption.copyWith(
                      color: themeColors.onSurface.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ),
              const Spacer(),
              InkWell(
                onTap: () => controller.removeResult(result.query),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: isGreyedOut 
                      ? themeColors.onSurface.withOpacity(0.3)
                      : themeColors.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        
        // Tool cards for each available tool type
        ...tools.map((toolType) => ToolCard(
          result: result,
          toolType: toolType,
          themeColors: themeColors,
          isGreyedOut: isGreyedOut,
          onCopy: _handleCopy,
          onShare: _handleShare,
          onReferenceClick: _handleReferenceClick,
        )).toList(),
        
        // Loading indicator for streaming (only for current results)
        if (showLoading)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(themeColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading more results...',
                  style: TdResTextStyles.p2.copyWith(
                    color: themeColors.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLoadingState(AppThemeColors themeColors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(themeColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Searching across all sources...',
            style: TdResTextStyles.p1.copyWith(
              color: themeColors.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppThemeColors themeColors, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: themeColors.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Search Failed',
              style: TdResTextStyles.h4.copyWith(
                color: themeColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TdResTextStyles.p1.copyWith(
                color: themeColors.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => BlocProvider.of<UnifiedController>(context).refreshCurrentSearch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppThemeColors themeColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 80,
              color: themeColors.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Unified Search',
              style: TdResTextStyles.h3.copyWith(
                color: themeColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Search across Dictionary, Verses, and Books simultaneously.\nGet comprehensive results in expandable tool cards.',
              style: TdResTextStyles.p1.copyWith(
                color: themeColors.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Try searching for:',
                    style: TdResTextStyles.p2.copyWith(
                      color: themeColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• "Who is Rama?"\n• "Tell me about dharma"\n• "Bhagavad Gita verses"',
                    style: TdResTextStyles.p2.copyWith(
                      color: themeColors.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  void _performSearch([BuildContext? searchContext]) {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      try {
        final ctx = searchContext ?? context;
        final controller = BlocProvider.of<UnifiedController>(ctx);
        controller.searchUnified(query);
      } catch (e) {
        // Handle error silently
      }
    }
  }

  void _clearSearch() {
    // Don't dismiss keyboard when clearing - just clear the text
    _searchController.clear();
    // Don't navigate back to welcome state - keep current results visible
  }

  void _handleCopy(String text) {
    // TODO: Implement copy to clipboard
  }

  void _handleShare(String text) {
    // TODO: Implement share functionality
  }

  void _handleReferenceClick(String reference) {
    // TODO: Implement reference navigation
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Determine if a result should be greyed out based on search session
  bool _shouldGreyOutResult(UnifiedSearchResult result, List<UnifiedSearchResult> allResults) {
    if (allResults.isEmpty) return false;
    
    // Find the most recent search session ID
    final sessionIds = allResults.map((r) => r.searchSessionId);
    if (sessionIds.isEmpty) return false;
    
    final mostRecentSessionId = sessionIds.reduce((a, b) => a > b ? a : b);
    
    // Grey out if this result is not from the most recent search session
    return result.searchSessionId < mostRecentSessionId;
  }

}
