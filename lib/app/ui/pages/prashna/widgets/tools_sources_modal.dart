import 'package:dharak_flutter/app/types/prashna/chat_message.dart';
import 'package:dharak_flutter/app/types/prashna/api_response_parser.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/tool_card_factory.dart';
import 'package:dharak_flutter/app/types/prashna/tool_call.dart' as tc;
import 'package:dharak_flutter/app/types/prashna/execution_log.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/execution_timeline.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

/// Modal widget for Tools and Sources (Perplexity-style)
class ToolsAndSourcesModal extends StatefulWidget {
  final ChatMessage message;
  final int initialTab;
  final int? scrollToSource;
  final AppThemeColors? themeColors;
  final Map<int, GlobalKey> sourceKeys;
  final ScrollController sourcesScrollController;

  const ToolsAndSourcesModal({
    super.key,
    required this.message,
    this.initialTab = 0,
    this.scrollToSource,
    this.themeColors,
    required this.sourceKeys,
    required this.sourcesScrollController,
  });

  @override
  State<ToolsAndSourcesModal> createState() => _ToolsAndSourcesModalState();
}

class _ToolsAndSourcesModalState extends State<ToolsAndSourcesModal> with TickerProviderStateMixin {
  late TabController _modalTabController;

  @override
  void initState() {
    super.initState();
    
    // Determine tab count based on available content
    int tabCount = 0;
    if (_hasToolCalls()) tabCount++;
    if (_hasSources()) tabCount++;
    if (_hasLogs()) tabCount++;
    
    // Ensure at least one tab
    if (tabCount == 0) tabCount = 1;
    
    final initialTab = widget.initialTab.clamp(0, tabCount - 1);
    
    _modalTabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: initialTab.clamp(0, tabCount - 1),
    );

    // Auto-scroll to source if specified
    if (widget.scrollToSource != null && widget.initialTab == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSource(widget.scrollToSource!);
      });
    }
  }

  @override
  void dispose() {
    _modalTabController.dispose();
    super.dispose();
  }

  bool _hasToolCalls() {
    // First check if toolCalls are already parsed and stored in the message
    if (widget.message.toolCalls.isNotEmpty) {
      return true;
    }
    
    // Fall back to parsing from rawContent or content
    final content = widget.message.rawContent ?? widget.message.content ?? '';
    final toolCalls = PrashnaApiResponseParser.parseToolCalls(content);
    return toolCalls.isNotEmpty;
  }

  bool _hasSources() {
    return widget.message.citations.isNotEmpty;
  }

  bool _hasLogs() {
    // Check if execution log data is available
    if (widget.message.executionLog != null) {
      return widget.message.executionLog!.events.isNotEmpty;
    }
    
    // Fall back to parsing from rawContent or content
    final content = widget.message.rawContent ?? widget.message.content ?? '';
    if (content.isNotEmpty) {
      final executionLog = PrashnaApiResponseParser.parseExecutionLog(content);
      if (executionLog != null) {
        return executionLog.events.isNotEmpty;
      }
    }
    
    // NO FALLBACK: Only show logs tab if real execution data exists
    return false;
  }

  int _getToolCallsCount() {
    // First check if toolCalls are already parsed and stored in the message
    if (widget.message.toolCalls.isNotEmpty) {
      return widget.message.toolCalls.length;
    }
    
    // Fall back to parsing from rawContent or content
    final content = widget.message.rawContent ?? widget.message.content ?? '';
    final toolCalls = PrashnaApiResponseParser.parseToolCalls(content);
    return toolCalls.length;
  }

  void _scrollToSource(int sourceNumber) {
    // Implementation similar to the original _scrollToSource method
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.7, // Reduced from 0.85 to 0.75
      decoration: BoxDecoration(
        // Use a distinctly different background color
        color: widget.themeColors?.isDark == true 
            ? const Color(0xFF1E1E2E)  // Dark purple-gray for dark mode
            : const Color(0xFFF8F9FF), // Very light blue-gray for light mode
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        // Add a distinctive border at the top
        border: Border(
          top: BorderSide(
            color: widget.themeColors?.primary ?? Colors.indigo.shade500,
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
          // Add a subtle inner shadow for depth
          BoxShadow(
            color: (widget.themeColors?.primary ?? Colors.indigo.shade500).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Modal drag handle for visual cue
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.themeColors?.onSurfaceMedium ?? Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Modal Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
            decoration: BoxDecoration(
              // Gradient header for more distinction
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  (widget.themeColors?.primary ?? Colors.indigo.shade500).withOpacity(0.1),
                  (widget.themeColors?.primary ?? Colors.indigo.shade500).withOpacity(0.05),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: widget.themeColors?.primary?.withOpacity(0.2) ?? Colors.indigo.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Modal icon for clear identification
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.themeColors?.primary ?? Colors.indigo.shade500,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
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
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: widget.themeColors?.onSurface ?? Colors.black87,
                        ),
                      ),
                      Text(
                        'Tools used and sources referenced',
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.themeColors?.onSurfaceMedium ?? Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // More prominent close button with dark indigo color
                Container(
                  decoration: BoxDecoration(
                    // Use dark indigo gradient for high visibility
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.indigo.shade500,
                        Colors.indigo.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.shade300,
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
          ),

          // Tab Bar (Tools + Sources + Logs)
          if (_hasToolCalls() || _hasSources() || _hasLogs())
            Container(
              decoration: BoxDecoration(
                // Subtle gradient for tab bar
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (widget.themeColors?.primary ?? Colors.indigo.shade500).withOpacity(0.02),
                    Colors.transparent,
                  ],
                ),
              ),
              child: TabBar(
                controller: _modalTabController,
                labelColor: widget.themeColors?.primaryHigh ?? Colors.indigo.shade700,
                unselectedLabelColor: widget.themeColors?.onSurfaceMedium ?? Colors.grey.shade600,
                indicatorColor: widget.themeColors?.primary ?? Colors.indigo.shade500,
                indicatorWeight: 3,
                isScrollable: true, // Allow scrolling for three tabs
                tabs: [
                  if (_hasToolCalls())
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
                              color: widget.themeColors?.primaryLight ?? Colors.indigo.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_getToolCallsCount()}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: widget.themeColors?.primaryHigh ?? Colors.indigo.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_hasSources())
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
                              color: widget.themeColors?.primaryLight ?? Colors.indigo.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.message.citations.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: widget.themeColors?.primaryHigh ?? Colors.indigo.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_hasLogs())
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timeline_outlined, size: 16),
                          const SizedBox(width: 6),
                          const Text('Logs'),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.speed,
                              size: 12,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // Tab Content
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    // Get all available tabs
    final availableTabs = <Widget>[];
    
    if (_hasToolCalls()) availableTabs.add(_buildToolsContent());
    if (_hasSources()) availableTabs.add(_buildSourcesContent());
    if (_hasLogs()) availableTabs.add(_buildLogsContent());
    
    if (availableTabs.isEmpty) {
      return _buildEmptyContent();
    }
    
    if (availableTabs.length == 1) {
      return availableTabs.first;
    }
    
    return TabBarView(
      controller: _modalTabController,
      children: availableTabs,
    );
  }

  Widget _buildEmptyContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No additional information available',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tools, sources, and logs will appear here when available',
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

  Widget _buildToolsContent() {
    // NEW IMPLEMENTATION: Use our tool card factory with API response parser
    List<tc.ToolCall> toolCalls = [];
    
    // First check if toolCalls are already parsed and stored in the message
    if (widget.message.toolCalls.isNotEmpty) {
      // Convert ChatMessage ToolCall to our ToolCall format
      toolCalls = widget.message.toolCalls.map((msgToolCall) => 
        tc.ToolCall(
          toolName: msgToolCall.name,
          toolArgs: msgToolCall.parameters,
        )
      ).toList();
    } else {
      // Fall back to parsing from rawContent or content
      final content = widget.message.rawContent ?? widget.message.content ?? '';
      toolCalls = PrashnaApiResponseParser.parseToolCalls(content);
    }
    
    if (toolCalls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle_outlined, size: 48, color: Colors.grey.shade400),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.themeColors?.onSurface ?? Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${toolCalls.length} tool${toolCalls.length == 1 ? '' : 's'} used to generate this response',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.themeColors?.onSurfaceMedium ?? Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // NEW: Our expandable tool cards
          ...toolCards,
        ],
      ),
    );
  }

  Widget _buildSourcesContent() {
    if (widget.message.citations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.source_outlined, size: 48, color: widget.themeColors?.isDark == true ? Colors.grey.shade600 : Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No sources available',
              style: TextStyle(
                color: widget.themeColors?.isDark == true ? Colors.grey.shade400 : Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sources will appear here when available',
              style: TextStyle(
                color: widget.themeColors?.isDark == true ? Colors.grey.shade500 : Colors.grey.shade400,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort sources by citation number (id) in ascending order
    final sortedSources = List<SourceCitation>.from(widget.message.citations)
      ..sort((a, b) => a.id.compareTo(b.id));

    return ListView.builder(
      controller: widget.sourcesScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: sortedSources.length,
      itemBuilder: (context, index) {
        final source = sortedSources[index];
        return _buildSimpleSourceCard(source, source.id);
      },
    );
  }

  Widget _buildSimpleSourceCard(SourceCitation source, int sourceNumber) {
    return ExpandableSimpleSourceCard(
      key: widget.sourceKeys[sourceNumber],
      source: source,
      sourceNumber: sourceNumber,
      themeColors: widget.themeColors,
    );
  }

  Widget _buildLogsContent() {
    return FutureBuilder<ExecutionLog?>(
      future: _getExecutionLog(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final executionLog = snapshot.data;
        
        if (executionLog == null || executionLog.events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timeline_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No execution logs available',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Execution timing and performance data will appear here',
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
        
        return ExecutionTimeline(
          executionLog: executionLog,
          themeColors: widget.themeColors,
        );
      },
    );
  }

  /// Get execution log data asynchronously
  Future<ExecutionLog?> _getExecutionLog() async {
    // Get execution log data
    ExecutionLog? executionLog = widget.message.executionLog;
    
    // Fall back to parsing from content if not already available
    if (executionLog == null) {
      final content = widget.message.rawContent ?? widget.message.content ?? '';
      executionLog = PrashnaApiResponseParser.parseExecutionLog(content);
    }
    
    // NO FALLBACK: Return null if no real execution log exists
    if (executionLog == null || executionLog.events.isEmpty) {
      return null;
    }
    
    return executionLog;
  }

  // REMOVED: All mock execution log methods - no fallback data will be generated
}

/// Expandable source card widget (original implementation)
class ExpandableSimpleSourceCard extends StatefulWidget {
  final SourceCitation source;
  final int sourceNumber;
  final AppThemeColors? themeColors;

  const ExpandableSimpleSourceCard({
    super.key,
    required this.source,
    required this.sourceNumber,
    this.themeColors,
  });

  @override
  State<ExpandableSimpleSourceCard> createState() => _ExpandableSimpleSourceCardState();
}

class _ExpandableSimpleSourceCardState extends State<ExpandableSimpleSourceCard> with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expandController;
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _highlightAnimation = CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const int previewMaxLength = 150;
    final bool hasLongContent = (widget.source.text?.length ?? 0) > previewMaxLength;
    final String previewText = hasLongContent && !_isExpanded
        ? '${widget.source.text!.substring(0, previewMaxLength)}...'
        : widget.source.text ?? '';

    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: widget.themeColors?.isDark == true 
                ? _getSourceTypeColor(widget.source.type).withOpacity(0.1)
                : _getSourceTypeColor(widget.source.type).shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.themeColors?.isDark == true 
                  ? _getSourceTypeColor(widget.source.type).withOpacity(0.3)
                  : _getSourceTypeColor(widget.source.type).shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with source number and type
                Row(
                  children: [
                    // Source number badge
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getSourceTypeColor(widget.source.type),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.sourceNumber}',
                          style: TextStyle(
                            color: widget.themeColors?.isDark == true 
                                ? Colors.grey.shade900 
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Source type
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.themeColors?.isDark == true 
                              ? _getSourceTypeColor(widget.source.type).withOpacity(0.2)
                              : _getSourceTypeColor(widget.source.type).shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getEnhancedSourceTitle(widget.source),
                          style: TextStyle(
                            color: widget.themeColors?.isDark == true 
                                ? _getSourceTypeColor(widget.source.type).shade300
                                : _getSourceTypeColor(widget.source.type).shade800,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          maxLines: null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Expand/collapse button
                    if (hasLongContent)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                            if (_isExpanded) {
                              _expandController.forward();
                            } else {
                              _expandController.reverse();
                            }
                          });
                        },
                        child: AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.expand_more,
                            color: _getSourceTypeColor(widget.source.type).shade600,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Source text
                AnimatedCrossFade(
                  firstChild: Text(
                    previewText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  secondChild: Text(
                    widget.source.text ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  crossFadeState: _isExpanded 
                      ? CrossFadeState.showSecond 
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
                
                // Show URL and action buttons when expanded
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  
                  // URL display (if available)
                  if (widget.source.url?.isNotEmpty == true) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.themeColors?.isDark == true 
                            ? _getSourceTypeColor(widget.source.type).shade900.withOpacity(0.3)
                            : _getSourceTypeColor(widget.source.type).shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 14,
                            color: _getSourceTypeColor(widget.source.type).shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _launchURL(widget.source.url!),
                              child: Text(
                                widget.source.url!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getSourceTypeColor(widget.source.type).shade600,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Action buttons
                  Row(
                    children: [
                      // Copy button
                      _buildActionButton(
                        icon: Icons.copy,
                        onTap: () => _copySourceContent(),
                      ),
                      const SizedBox(width: 8),
                      
                      // Share button
                      _buildActionButton(
                        icon: Icons.share,
                        onTap: () => _shareSourceContent(),
                      ),
                      
                      // URL button (if URL available)
                      if (widget.source.url?.isNotEmpty == true) ...[
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.open_in_new,
                          onTap: () => _launchURL(widget.source.url!),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  MaterialColor _getSourceTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'verse':
      case 'verses':
        return MaterialColor(0xFF059669, const <int, Color>{
          50: Color(0xFFe8f5f0),
          100: Color(0xFFd1ebe1),
          200: Color(0xFFa3d7c3),
          300: Color(0xFF75c3a5),
          400: Color(0xFF47af87),
          500: Color(0xFF059669), // Standardized QuickVerse green
          600: Color(0xFF04875f),
          700: Color(0xFF037854),
          800: Color(0xFF026a4a),
          900: Color(0xFF015b40),
        });
      case 'defn':
      case 'definition':
      case 'dict':
      case 'dictionary':
        return MaterialColor(0xFFc60000, const <int, Color>{
          50: Color(0xFFffeaea),
          100: Color(0xFFffd5d5),
          200: Color(0xFFffabab),
          300: Color(0xFFff8080),
          400: Color(0xFFff5656),
          500: Color(0xFFc60000), // Standardized WordDefine red
          600: Color(0xFFb50000),
          700: Color(0xFF9f0000),
          800: Color(0xFF8a0000),
          900: Color(0xFF750000),
        });
      case 'chunk':
      case 'book':
      case 'books':
        return Colors.blue;
      case 'heritage':
        return Colors.orange;
      default:
        return Colors.indigo;
    }
  }

  String _getSourceTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'verse':
      case 'verses':
        return 'Verse';
      case 'defn':
      case 'definition':
      case 'dict':
      case 'dictionary':
        return 'Dict';
      case 'chunk':
      case 'book':
      case 'books':
        return 'Books';
      case 'heritage':
        return 'HERITAGE';
      default:
        return type.toUpperCase();
    }
  }

  /// Get enhanced source title with word context if available
  String _getEnhancedSourceTitle(SourceCitation source) {
    final baseTitle = _getSourceTypeDisplayName(source.type);
    
    switch (source.type.toLowerCase()) {
      case 'defn':
      case 'definition':
        // For definitions, if we have the word in reference, show it
        if (source.reference != null && 
            source.reference!.isNotEmpty && 
            source.reference != 'Definition') {
          // Only show the word if it's a meaningful word (not just "Definition")
          return 'Dict: ${source.reference}';
        }
        break;
        
      case 'verse':
      case 'verses':
        // For verses, if we have verse reference, show it
        if (source.reference != null && 
            source.reference!.isNotEmpty) {
          // Could be verse number, chapter, or verse identifier
          return 'Verse: ${source.reference}';
        }
        break;
        
      case 'chunk':
      case 'book':
      case 'books':
        // For books, if we have book/chapter reference, show it
        if (source.reference != null && 
            source.reference!.isNotEmpty) {
          // Could be book name, chapter, or section
          return 'Books: ${source.reference}';
        }
        break;
    }
    
    return baseTitle;
  }

  /// Build action button for copy/share/URL actions
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: widget.themeColors?.isDark == true 
              ? Colors.grey.shade700.withOpacity(0.3)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: widget.themeColors?.isDark == true 
                ? Colors.grey.shade600
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: widget.themeColors?.isDark == true 
              ? Colors.grey.shade300
              : Colors.grey.shade600,
        ),
      ),
    );
  }

  /// Launch URL in external browser
  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not launch URL: $url');
      }
    } catch (e) {
      _showSnackBar('Error launching URL: $e');
    }
  }

  /// Copy source content to clipboard
  void _copySourceContent() {
    final content = widget.source.text ?? 'No content available';
    Clipboard.setData(ClipboardData(text: content));
    _showSnackBar('Content copied to clipboard');
  }

  /// Share source content
  void _shareSourceContent() {
    final content = widget.source.text ?? 'No content available';
    final title = _getEnhancedSourceTitle(widget.source);
    final shareText = '$title\n\n$content';
    
    if (widget.source.url?.isNotEmpty == true) {
      Share.share('$shareText\n\nSource: ${widget.source.url}');
    } else {
      Share.share(shareText);
    }
  }

  /// Show snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
