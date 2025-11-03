import 'package:flutter/material.dart';
import 'package:dharak_flutter/app/types/prashna/chat_message.dart';
import 'package:dharak_flutter/app/types/prashna/api_response_parser.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/tool_card_factory.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';

/// New Tools and Sources Modal with our improved tool card architecture
class NewToolsAndSourcesModal extends StatefulWidget {
  final ChatMessage message;
  final int initialTab;
  final int? scrollToSource;
  final AppThemeColors? themeColors;
  final Map<int, GlobalKey> sourceKeys;
  final ScrollController sourcesScrollController;

  const NewToolsAndSourcesModal({
    super.key,
    required this.message,
    this.initialTab = 0,
    this.scrollToSource,
    this.themeColors,
    required this.sourceKeys,
    required this.sourcesScrollController,
  });

  @override
  State<NewToolsAndSourcesModal> createState() => _NewToolsAndSourcesModalState();
}

class _NewToolsAndSourcesModalState extends State<NewToolsAndSourcesModal> 
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    
    final hasTools = _hasToolCalls();
    final hasSources = _hasSources();
    final tabCount = (hasTools ? 1 : 0) + (hasSources ? 1 : 0);
    
    _tabController = TabController(
      length: tabCount.clamp(1, 2),
      vsync: this,
      initialIndex: hasTools ? widget.initialTab.clamp(0, tabCount - 1) : 0,
    );

    // Auto-scroll to source if specified
    if (widget.scrollToSource != null && hasSources) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSource(widget.scrollToSource!);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _hasToolCalls() {
    final toolCalls = PrashnaApiResponseParser.parseToolCalls(widget.message.content ?? '');
    return toolCalls.isNotEmpty;
  }

  bool _hasSources() {
    return widget.message.citations.isNotEmpty;
  }

  int _getToolCallsCount() {
    final toolCalls = PrashnaApiResponseParser.parseToolCalls(widget.message.content ?? '');
    return toolCalls.length;
  }

  void _scrollToSource(int sourceNumber) {
    if (!mounted || !widget.sourcesScrollController.hasClients) return;
    
    final targetSourceIndex = widget.message.citations.indexWhere((citation) => citation.id == sourceNumber);
    if (targetSourceIndex != -1) {
      final sourceKey = widget.sourceKeys[widget.message.citations[targetSourceIndex].id];
      if (sourceKey?.currentContext != null) {
        Scrollable.ensureVisible(
          sourceKey!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = widget.themeColors ?? Theme.of(context).extension<AppThemeColors>()!;
    final hasTools = _hasToolCalls();
    final hasSources = _hasSources();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: themeColors.isDark 
            ? const Color(0xFF1E1E2E)
            : const Color(0xFFF8F9FF),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(
            color: themeColors.primary,
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: themeColors.onSurfaceMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          _buildHeader(themeColors),
          
          // Tab Bar (if both tools and sources exist)
          if (hasTools && hasSources) _buildTabBar(themeColors),
          
          // Content
          Expanded(
            child: hasTools && hasSources
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildToolsContent(),
                      _buildSourcesContent(),
                    ],
                  )
                : hasTools
                    ? _buildToolsContent()
                    : _buildSourcesContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            themeColors.primary.withOpacity(0.1),
            themeColors.primary.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: themeColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 18,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Additional Information',
                  style: TdResTextStyles.h4.copyWith(
                    color: themeColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Tools used and sources referenced',
                  style: TdResTextStyles.caption.copyWith(
                    color: themeColors.onSurfaceMedium,
                  ),
                ),
              ],
            ),
          ),
          
          // Close button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeColors.primary,
                  themeColors.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: themeColors.primary.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
              tooltip: 'Close',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppThemeColors themeColors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            themeColors.primary.withOpacity(0.02),
            Colors.transparent,
          ],
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: themeColors.primaryHigh,
        unselectedLabelColor: themeColors.onSurfaceMedium,
        indicatorColor: themeColors.primary,
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.build_outlined, size: 16),
                const SizedBox(width: 6),
                const Text('Tools'),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: themeColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_getToolCallsCount()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: themeColors.primaryHigh,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.source_outlined, size: 16),
                const SizedBox(width: 6),
                const Text('Sources'),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: themeColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.message.citations.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: themeColors.primaryHigh,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsContent() {
    final toolCalls = PrashnaApiResponseParser.parseToolCalls(widget.message.content ?? '');
    
    if (toolCalls.isEmpty) {
      return _buildEmptyToolsState();
    }

    final toolCards = ToolCardFactory.createToolCards(toolCalls);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tools Used',
                  style: TdResTextStyles.h5.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).extension<AppThemeColors>()?.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${toolCalls.length} tool${toolCalls.length == 1 ? '' : 's'} used to generate this response',
                  style: TdResTextStyles.p2.copyWith(
                    color: Theme.of(context).extension<AppThemeColors>()?.onSurfaceMedium,
                  ),
                ),
              ],
            ),
          ),
          
          // Tool cards
          ...toolCards,
        ],
      ),
    );
  }

  Widget _buildSourcesContent() {
    // Placeholder for sources content - keep existing implementation
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.source_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Sources content',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Implementation coming soon',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyToolsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build_circle_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No tools used',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This response was generated without using any external tools',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}












