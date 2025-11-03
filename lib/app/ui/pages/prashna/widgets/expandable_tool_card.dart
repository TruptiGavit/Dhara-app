import 'package:flutter/material.dart';
import 'package:dharak_flutter/app/types/prashna/tool_call.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:expandable/expandable.dart';

/// Generic expandable tool card that can contain any search results
class ExpandableToolCard extends StatefulWidget {
  final ToolCall toolCall;
  final Widget? resultsWidget;
  final bool isLoading;
  final String? error;
  final int? resultCount;
  final VoidCallback? onExpand;
  final bool isExpanded;
  
  const ExpandableToolCard({
    super.key,
    required this.toolCall,
    this.resultsWidget,
    this.isLoading = false,
    this.error,
    this.resultCount,
    this.onExpand,
    this.isExpanded = false,
  });

  @override
  State<ExpandableToolCard> createState() => _ExpandableToolCardState();
}

class _ExpandableToolCardState extends State<ExpandableToolCard>
    with SingleTickerProviderStateMixin {
  late ExpandableController _expandableController;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _expandableController = ExpandableController(initialExpanded: widget.isExpanded);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _expandableController.addListener(() {
      if (_expandableController.expanded) {
        _animationController.forward();
        widget.onExpand?.call();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _expandableController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,  // Remove shadow effect for clean Prashna design
      color: _getToolBackgroundColor(widget.toolCall.toolType), // Tool-specific background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getToolColor(widget.toolCall.toolType).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ExpandablePanel(
        controller: _expandableController,
        theme: const ExpandableThemeData(
          hasIcon: false,
          tapHeaderToExpand: true,
          tapBodyToExpand: false,
          tapBodyToCollapse: false,
        ),
        header: _buildHeader(themeColors),
        collapsed: const SizedBox.shrink(),
        expanded: _buildExpandedContent(themeColors),
      ),
    );
  }

  Widget _buildHeader(AppThemeColors themeColors) {
    final toolColor = _getToolColor(widget.toolCall.toolType);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Tool icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: toolColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getToolIcon(widget.toolCall.toolType),
              color: toolColor,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Tool info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.toolCall.displayName,
                      style: TdResTextStyles.h5.copyWith(
                        color: themeColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.resultCount != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: toolColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${widget.resultCount}',
                          style: TdResTextStyles.caption.copyWith(
                            color: toolColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.toolCall.query,
                  style: TdResTextStyles.p2.copyWith(
                    color: themeColors.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.toolCall.duration != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Completed in ${widget.toolCall.duration!.toStringAsFixed(2)}s',
                    style: TdResTextStyles.caption.copyWith(
                      color: themeColors.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Loading indicator or expand icon
          if (widget.isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: toolColor,
              ),
            )
          else
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value * 3.14159,
                  child: Icon(
                    Icons.expand_more,
                    color: themeColors.onSurface.withOpacity(0.6),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(AppThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Divider(
            color: themeColors.onSurface.withOpacity(0.1),
            height: 1,
          ),
          
          const SizedBox(height: 16),
          
          // Results content
          if (widget.error != null)
            _buildErrorContent(themeColors)
          else if (widget.isLoading)
            _buildLoadingContent(themeColors)
          else if (widget.resultsWidget != null)
            widget.resultsWidget!
          else
            _buildEmptyContent(themeColors),
        ],
      ),
    );
  }

  Widget _buildLoadingContent(AppThemeColors themeColors) {
    return Container(
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: _getToolColor(widget.toolCall.toolType),
            ),
            const SizedBox(height: 12),
            Text(
              'Searching ${widget.toolCall.displayName.toLowerCase()}...',
              style: TdResTextStyles.p2.copyWith(
                color: themeColors.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(AppThemeColors themeColors) {
    return Container(
      height: 80,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              widget.error!,
              style: TdResTextStyles.p2.copyWith(
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyContent(AppThemeColors themeColors) {
    return Container(
      height: 80,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: themeColors.onSurface.withOpacity(0.3),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'No results found',
              style: TdResTextStyles.p2.copyWith(
                color: themeColors.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getToolColor(ToolType toolType) {
    switch (toolType) {
      case ToolType.dictionary:
        return const Color(0xFFc60000); // Standardized WordDefine red
      case ToolType.verse:
        return const Color(0xFF059669); // Standardized QuickVerse green
      case ToolType.books:
        return Colors.blue; // Standardized Books blue
      case ToolType.unknown:
        return Colors.grey;
    }
  }

  /// Get tool-specific background color (lightest shade)
  Color _getToolBackgroundColor(ToolType toolType) {
    final themeColors = Theme.of(context).extension<AppThemeColors>();
    final isDark = themeColors?.isDark == true;
    
    switch (toolType) {
      case ToolType.dictionary:
        return isDark 
            ? const Color(0xFFc60000).withOpacity(0.1) // Dark red with opacity
            : const Color(0xFFffeaea); // WordDefine red shade 50 (lightest)
      case ToolType.verse:
        return isDark 
            ? const Color(0xFF059669).withOpacity(0.1) // Dark green with opacity
            : const Color(0xFFe8f5f0); // QuickVerse green shade 50 (lightest)
      case ToolType.books:
        return isDark 
            ? Colors.blue.withOpacity(0.1) // Dark blue with opacity
            : Colors.blue.shade50; // Books blue shade 50 (lightest)
      case ToolType.unknown:
        return isDark 
            ? Colors.indigo.withOpacity(0.1) // Dark indigo with opacity
            : Colors.indigo.shade50; // Default lightest indigo
    }
  }

  IconData _getToolIcon(ToolType toolType) {
    switch (toolType) {
      case ToolType.dictionary:
        return Icons.local_library_outlined; // Standardized WordDefine icon
      case ToolType.verse:
        return Icons.keyboard_command_key; // Standardized QuickVerse icon  
      case ToolType.books:
        return Icons.menu_book; // Standardized Books icon
      case ToolType.unknown:
        return Icons.help;
    }
  }
}








