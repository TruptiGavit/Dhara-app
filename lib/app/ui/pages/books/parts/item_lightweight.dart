import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../types/books/book_chunk.dart';
import '../../../../types/books/book_chunk_augmentation.dart';
import '../../../../../res/theme/app_theme_colors.dart';
import '../../../../../res/theme/app_theme_display.dart';
import '../../../../../res/values/dimens.dart';
import '../../../../../core/services/books_service.dart';
import '../../../../domain/books/repo.dart';
import '../../../../domain/base/domain_result.dart';
import '../../../../domain/citation/repo.dart';
import '../../../../domain/share/repo.dart';
import '../../../widgets/book_augmentation_modal.dart';
import '../../../widgets/citation_modal.dart';
import '../../../widgets/share_modal.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Modern, visually appealing BookChunkItemWidget with proper UX design
class BookChunkItemLightweightWidget extends StatefulWidget {
  final BookChunkRM chunk; // Changed from 'entity' to 'chunk' to match API usage
  final AppThemeColors? themeColors; // Made optional
  final AppThemeDisplay? appThemeDisplay;

  // Navigation callbacks (required for new API)
  final VoidCallback? onNavigatePrevious;
  final VoidCallback? onNavigateNext;
  final Function(String)? onSourceClick;
  
  // Bookmark callback (for parent context updates)
  final Function(BookChunkRM chunk, bool isBookmarked)? onBookmarkToggle;
  
  // Search query for share functionality
  final String? searchQuery;
  
  // Legacy callbacks (optional for backward compatibility)
  final Function(int)? onClickCopy;
  final Function(GlobalKey)? onClickShare;
  final Function(String)? onClickExternalUrl;
  final Function(int)? onClickCitation;

  const BookChunkItemLightweightWidget({
    super.key,
    required this.chunk, // Changed from entity to chunk
    this.themeColors, // Made optional
    this.appThemeDisplay,
    this.onNavigatePrevious,
    this.onNavigateNext,
    this.onSourceClick,
    this.onBookmarkToggle,
    this.searchQuery,
    this.onClickCopy,
    this.onClickShare,
    this.onClickExternalUrl,
    this.onClickCitation,
  });

  @override
  State<BookChunkItemLightweightWidget> createState() => _BookChunkItemLightweightWidgetState();
}

class _BookChunkItemLightweightWidgetState extends State<BookChunkItemLightweightWidget> with TickerProviderStateMixin {
  bool _isExpanded = false;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  
  // Local state for bookmark status to ensure UI updates
  late bool _isBookmarked;

  // Dynamic colors based on source type for left border accent
  Color get _borderColor {
    switch (widget.chunk.sourceType) {
      case BookChunkSourceType.original:
        return const Color(0xFF1565C0); // Blue - Traditional navigation
      case BookChunkSourceType.mergedAugmentation:
        return const Color(0xFF7C3AED); // Purple - Special insights
      case BookChunkSourceType.augmentation:
        return const Color(0xFF0891B2); // Teal - Derivative content
      case BookChunkSourceType.none:
        return const Color(0xFF059669); // Green - Dhara knowledge
      default:
        return const Color(0xFFEF4444); // Red - Unknown (instead of grey)
    }
  }
  
  // Theme-aware background for all cards
  Color get _cardBackgroundColor {
    // Use theme surface with slight tint based on border color
    return Color.alphaBlend(
      _borderColor.withOpacity(0.03),
      effectiveThemeColors.surface,
    );
  }
  
  // Theme-aware colors for links and actions
  Color get _linkColor {
    return effectiveThemeColors.isDark 
        ? const Color(0xFF60A5FA) // Lighter blue for dark theme
        : const Color(0xFF1565C0); // Original blue for light theme
  }
  
  // Legacy colors for compatibility (kept for gradual migration)
  static const Color _booksGreen = Color(0xFF2E7D32);
  static const Color _booksAmber = Color(0xFFEF6C00);
  
  // Computed property for effective theme colors
  AppThemeColors get effectiveThemeColors {
    return widget.themeColors ?? 
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: const Color(0xFF6CE18D), isDark: false);
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize bookmark state from widget data
    _isBookmarked = widget.chunk.isStarred ?? false;
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(BookChunkItemLightweightWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update local bookmark state if widget data changes
    if (oldWidget.chunk.isStarred != widget.chunk.isStarred) {
      _isBookmarked = widget.chunk.isStarred ?? false;
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _cardBackgroundColor, // Consistent blue background
          border: Border.all(
            color: effectiveThemeColors.onSurface.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: effectiveThemeColors.onSurface.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored top accent bar
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _borderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
            ),
            
            // Main content
            // Source title and score on same line (two columns)
            _buildSourceAndScoreHeader(),
            
            // Main content with colored background for emphasis
            _buildEmphasizedContent(),
            
            // Compact reference with colored background
            _buildEmphasizedReference(),
            
            // Actions: source link left, other icons right
            _buildReorganizedActions(),
          ],
        ),
      ),
    );
  }

  // New improved methods for better design
  Widget _buildSourceAndScoreHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: Source title (can wrap) with hyperlink
          Expanded(
            flex: 3,
            child: widget.chunk.sourceTitle != null
                ? GestureDetector(
                    onTap: widget.chunk.sourceUrl != null
                        ? () => _launchExternalUrl(widget.chunk.sourceUrl!)
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.chunk.sourceUrl != null) ...[
                          Icon(
                            Icons.open_in_new,
                            size: 12,
                            color: _borderColor.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            widget.chunk.sourceTitle!,
                            style: TextStyle(
                              fontSize: 11,
                              color: _borderColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                              decoration: widget.chunk.sourceUrl != null 
                                  ? TextDecoration.underline 
                                  : null,
                            ),
                            // Allow wrapping for long source titles
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          
          // Right column: Score badge
          if (widget.chunk.score != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _borderColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _borderColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                '${(widget.chunk.score! * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _borderColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmphasizedContent() {
    if (widget.chunk.text == null || widget.chunk.text!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Light blue background instead of colored
        color: effectiveThemeColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _borderColor.withOpacity(0.2),
          width: 0.8,
        ),
      ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              final maxLines = _isExpanded ? null : 3;
              return Text(
                widget.chunk.text!,
                      style: TextStyle(
                  fontSize: 14,
                        height: 1.5,
                  color: effectiveThemeColors.onSurface,
                  fontWeight: FontWeight.w600, // Bolder for main content
                ),
                maxLines: maxLines,
                overflow: _isExpanded ? null : TextOverflow.ellipsis,
              );
            },
          ),
          
          // Show more/less button - appears for longer text
          if (widget.chunk.text!.length > 100) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
                        child: Row(
                mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                    _isExpanded ? 'Show less' : 'Show more',
                              style: TextStyle(
                      fontSize: 12,
                      color: _borderColor,
                                fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: _borderColor,
                            ),
                          ],
                        ),
                      ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmphasizedReference() {
    if (widget.chunk.reference == null || widget.chunk.reference!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
        // Subtle background for reference - much lighter than main content
        color: effectiveThemeColors.onSurface.withOpacity(0.03),
                borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: effectiveThemeColors.onSurface.withOpacity(0.08),
          width: 0.5,
        ),
              ),
              child: Text(
        widget.chunk.reference!,
                style: TextStyle(
          fontSize: 11,
          color: effectiveThemeColors.onSurface.withOpacity(0.7),
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400, // Lighter weight to differentiate from main content
          height: 1.3,
        ),
        // Allow reference to wrap to next lines - no maxLines restriction
      ),
    );
  }

  Widget _buildReorganizedActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source button removed since it's now in the title
          
          // BOTTOM LINE - Action buttons (right aligned, like verse cards)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildSmartActionButtons(),
            ],
          ),
        ],
      ),
    );
  }

  /// 🎨 Beautiful Smart Action Buttons based on source type
  Widget _buildSmartActionButtons() {
    final sourceType = widget.chunk.sourceType;
    
    switch (sourceType) {
      case BookChunkSourceType.original:
        return _buildOriginalActions();
      case BookChunkSourceType.mergedAugmentation:
        return _buildMergedAugmentationActions();
      case BookChunkSourceType.augmentation:
        return _buildAugmentationActions();
      case BookChunkSourceType.none:
        return _buildNoneActions();
      default:
        return _buildDefaultActions();
    }
  }

  /// 🔹 Original Content: Traditional navigation + bookmark/share
  Widget _buildOriginalActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Navigation buttons for original content
        _buildActionButton(
          icon: Icons.chevron_left,
          onTap: () => _handleNavigation(false),
          isEnabled: widget.chunk.chunkRefId != null,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.chevron_right,
          onTap: () => _handleNavigation(true),
          isEnabled: widget.chunk.chunkRefId != null,
        ),
        
        const SizedBox(width: 12),
        
        // Standard actions
        _buildActionButton(
          icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border_outlined,
          onTap: () => _handleBookmark(),
          isEnabled: true,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.format_quote,
          onTap: () => _handleCitation(),
          isEnabled: true,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.share,
          onTap: () => _handleShare(),
          isEnabled: true,
        ),
      ],
    );
  }

  /// 🔶 Merged Augmentation: "See All Sources" + standard actions
  Widget _buildMergedAugmentationActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
              children: [
        // Special "See All Sources" button
        _buildSpecialButton(
          icon: Icons.library_books,
          label: "See Facts",
          onTap: () => _handleSeeAugmentations(),
          color: _borderColor,
        ),
        
        const SizedBox(width: 12),
        
        // Standard actions
                _buildActionButton(
          icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border_outlined,
          onTap: () => _handleBookmark(),
          isEnabled: true,
        ),
        const SizedBox(width: 8),
                _buildActionButton(
          icon: Icons.format_quote,
          onTap: () => _handleCitation(),
          isEnabled: true,
        ),
        const SizedBox(width: 8),
                _buildActionButton(
          icon: Icons.share,
          onTap: () => _handleShare(),
          isEnabled: true,
        ),
      ],
    );
  }

  /// 🔸 Augmentation: "See Original" + standard actions  
  Widget _buildAugmentationActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Special "See Original" button
        _buildSpecialButton(
          icon: Icons.source,
          label: "See Original",
          onTap: () => _handleSeeOriginal(),
          color: _borderColor,
        ),
        
        const SizedBox(width: 12),
        
        // Standard actions
        _buildActionButton(
          icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border_outlined,
          onTap: () => _handleBookmark(),
          isEnabled: true,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.format_quote,
          onTap: () => _handleCitation(),
          isEnabled: true,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.share,
          onTap: () => _handleShare(),
          isEnabled: true,
        ),
      ],
    );
  }

  /// 🔺 None Source Type: Pure Dhara knowledge + standard actions
  Widget _buildNoneActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border_outlined,
          onTap: () => _handleBookmark(),
          isEnabled: true,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.format_quote,
          onTap: () => _handleCitation(),
          isEnabled: true,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.share,
          onTap: () => _handleShare(),
          isEnabled: true,
        ),
      ],
    );
  }

  /// Default actions for unknown source types
  Widget _buildDefaultActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border_outlined,
          onTap: () => _handleBookmark(),
          isEnabled: true,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.format_quote,
          onTap: () => _handleCitation(),
          isEnabled: true,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.share,
          onTap: () => _handleShare(),
          isEnabled: true,
        ),
      ],
    );
  }

  /// Beautiful special action button with label
  Widget _buildSpecialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
              const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Small action button like verse cards
  Widget _buildActionButton({
    required IconData icon, 
    required VoidCallback onTap, 
    required bool isEnabled
  }) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: isEnabled 
                ? effectiveThemeColors.onSurface
                : effectiveThemeColors.onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  // Keep existing methods but rename the old _buildHeader
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(TdResDimens.dp_12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _linkColor.withOpacity(0.03),
            _linkColor.withOpacity(0.01),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source information with clickable link
          Expanded(
            child: _buildSourceInfo(),
          ),
          
          SizedBox(width: TdResDimens.dp_8),
          
          // Score badge
          _buildScoreBadge(),
        ],
      ),
    );
  }

  Widget _buildSourceInfo() {
    if (widget.chunk.sourceTitle == null) {
      return Row(
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 16,
            color: _linkColor,
          ),
          SizedBox(width: TdResDimens.dp_6),
          Text(
            'Unknown Source',
            style: TextStyle(
              color: effectiveThemeColors.onSurface.withOpacity(0.6),
              fontSize: 12,
                fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: widget.chunk.sourceUrl != null 
        ? () => _launchExternalUrl(widget.chunk.sourceUrl!)
        : null,
                        child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(TdResDimens.dp_4),
            decoration: BoxDecoration(
              color: _linkColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.library_books_outlined,
              size: 14,
              color: _linkColor,
            ),
          ),
          
          SizedBox(width: TdResDimens.dp_8),
          
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                  widget.chunk.sourceTitle!,
                  style: TextStyle(
                    color: widget.chunk.sourceUrl != null ? _linkColor : effectiveThemeColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: widget.chunk.sourceUrl != null ? TextDecoration.underline : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.chunk.sourceUrl != null) ...[
                  SizedBox(height: TdResDimens.dp_2),
                  Text(
                    'Tap to open source',
                      style: TextStyle(
                      color: _linkColor.withOpacity(0.7),
                      fontSize: 10,
                        fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          if (widget.chunk.sourceUrl != null) ...[
            SizedBox(width: TdResDimens.dp_6),
            Icon(
              Icons.open_in_new,
              size: 14,
              color: _linkColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreBadge() {
    final score = widget.chunk.score ?? 0.0;
    final color = _getScoreColor(score);
    final percentage = (score * 100).toStringAsFixed(1);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_10, vertical: TdResDimens.dp_6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
                        child: Row(
        mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
            Icons.auto_awesome,
            size: 14,
            color: color,
          ),
          SizedBox(width: TdResDimens.dp_4),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildMainContent() {
    final text = widget.chunk.text ?? 'No content available';
    
    return Padding(
      padding: EdgeInsets.all(TdResDimens.dp_16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _toggleExpansion(),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: Text(
                text,
                style: TextStyle(
                  color: effectiveThemeColors.onSurface,
                  fontSize: 15,
                  height: 1.6,
                  letterSpacing: 0.2,
                ),
                maxLines: _isExpanded ? null : 4,
                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
          ),
          
          if (_shouldShowExpandButton()) ...[
            SizedBox(height: TdResDimens.dp_12),
            Center(
              child: GestureDetector(
                onTap: () => _toggleExpansion(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_16, vertical: TdResDimens.dp_8),
                  decoration: BoxDecoration(
                    color: _linkColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _linkColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                              size: 18,
                              color: _linkColor,
                            ),
                      ),
                      SizedBox(width: TdResDimens.dp_6),
                            Text(
                              _isExpanded ? "Show less" : "Show more",
                              style: TextStyle(
                                color: _linkColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
            ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReferenceSection() {
    if (widget.chunk.reference == null || widget.chunk.reference!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: TdResDimens.dp_16),
      padding: EdgeInsets.all(TdResDimens.dp_12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _booksAmber.withOpacity(0.08),
            _booksAmber.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _booksAmber.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
            Container(
                padding: EdgeInsets.all(TdResDimens.dp_4),
              decoration: BoxDecoration(
                  color: _booksAmber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.bookmark_outline,
                  size: 14,
                  color: _booksAmber,
                ),
              ),
              SizedBox(width: TdResDimens.dp_8),
              Text(
                'Reference',
                style: TextStyle(
                  color: _booksAmber,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          
          SizedBox(height: TdResDimens.dp_10),
          
          // Reference text with proper wrapping - NO TRUNCATION
          _buildWrappedReference(),
        ],
      ),
    );
  }

  Widget _buildWrappedReference() {
    final reference = widget.chunk.reference!;
    final parts = reference.contains('->') 
      ? reference.split('->').map((e) => e.trim()).toList()
      : [reference];
    
    // For single part, show as simple text block
    if (parts.length == 1) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(TdResDimens.dp_10),
        decoration: BoxDecoration(
          color: _booksAmber.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _booksAmber.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Text(
          reference,
          style: TextStyle(
            color: _booksAmber.withAlpha(210),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          // NO text truncation - let it wrap to next lines naturally
        ),
      );
    }
    
    // For multiple parts, show as breadcrumb-style navigation
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.asMap().entries.map((entry) {
        final index = entry.key;
        final part = entry.value;
        final isLast = index == parts.length - 1;
        
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : TdResDimens.dp_6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Level indicator
              Container(
                margin: EdgeInsets.only(top: TdResDimens.dp_2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: _booksAmber.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
              
              SizedBox(width: TdResDimens.dp_8),
              
              // Reference part with full text wrapping  
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_10, vertical: TdResDimens.dp_8),
                  decoration: BoxDecoration(
                    color: _booksAmber.withOpacity(index == 0 ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _booksAmber.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    part,
                    style: TextStyle(
                      color: _booksAmber.withAlpha(200),
                      fontSize: 12,
                      fontWeight: index == 0 ? FontWeight.w600 : FontWeight.w500,
                      height: 1.4,
                    ),
                    // NO maxLines or overflow - let it wrap naturally to multiple lines
                  ),
                ),
            ),
          ],
        ),
        );
      }).toList(),
    );
  }




  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching URL: $e');
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  void _showBookmarkFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bookmark feature coming soon!'),
        backgroundColor: _linkColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  bool _shouldShowExpandButton() {
    final text = widget.chunk.text ?? '';
    return text.length > 200; // Show expand button for longer texts
  }

  Color _getScoreColor(double score) {
    if (score >= 0.7) return _booksGreen;
    if (score >= 0.4) return _booksAmber;
    return Colors.red.shade600;
  }

  // Action handlers for compact buttons
  void _handleShare() async {
    if (widget.chunk.chunkRefId == null) return;
    
    try {
      print('📤 Opening share modal for chunk: ${widget.chunk.chunkRefId}');
      
      // Show share modal with options for copy text and share image
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (modalContext) => ShareModal(
          themeColors: effectiveThemeColors,
          textToShare: widget.chunk.text ?? '',
          contentType: 'chunk',
          onCopyText: () => _handleCopyText(),
          onShareImage: () => _handleShareImage(),
        ),
      );
    } catch (e) {
      print('📤 Share modal error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to open share options'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _handleCopyText() async {
    if (widget.chunk.chunkRefId == null) return;
    
    try {
      print('📋 Copying chunk text: ${widget.chunk.chunkRefId}');
      
      // Get share repository and copy content to clipboard
      final shareRepo = Modular.get<ShareRepository>();
      final success = await shareRepo.copyChunkToClipboard(widget.chunk.chunkRefId!.toString());
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Copied to clipboard'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
        print('📋 Copy successful for chunk: ${widget.chunk.chunkRefId}');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to copy content'),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      print('📋 Copy error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to copy content'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _handleShareImage() async {
    if (widget.chunk.chunkRefId == null) return;
    
    try {
      print('🖼️ Sharing chunk as image: ${widget.chunk.chunkRefId}');
      
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Preparing image to share...'),
            backgroundColor: _borderColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Get share repository and get formatted share content first
      final shareRepo = Modular.get<ShareRepository>();
      
      // Get the properly formatted share content from the API (same as copy functionality)
      final formattedShareContent = await shareRepo.getChunkShareContent(
        widget.chunk.chunkRefId!.toString(),
        type: 'text',
      );
      
      if (formattedShareContent != null && formattedShareContent.isNotEmpty) {
        // Now share as image with the properly formatted content
        final success = await shareRepo.shareChunkAsImage(
          widgetKey: _repaintBoundaryKey,
          chunkId: widget.chunk.chunkRefId!.toString(),
          chunkText: formattedShareContent, // Use formatted content instead of raw text
          searchedQuery: widget.searchQuery, // Pass the search query for promotional message
        );
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Image shared successfully'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 2),
            ),
          );
          print('🖼️ Image share successful for chunk: ${widget.chunk.chunkRefId}');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to share image'),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No shareable content available'),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        print('🖼️ No formatted share content available for chunk: ${widget.chunk.chunkRefId}');
      }
    } catch (e) {
      print('🖼️ Image share error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to share image'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _handleCitation() async {
    if (widget.chunk.chunkRefId == null) return;
    
    try {
      print('🔖 Getting citation for chunk: ${widget.chunk.chunkRefId}');
      
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Loading citation...'),
            backgroundColor: _borderColor,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      
      // Get citation repository and fetch citation
      final citationRepo = Modular.get<CitationRepository>();
      final citation = await citationRepo.getChunkCitation(widget.chunk.chunkRefId!);
      
      if (citation != null && mounted) {
        // Show citation modal
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          enableDrag: true,
          isDismissible: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.67,
          ),
          builder: (modalContext) => CitationModal(
            citation: citation,
            themeColors: effectiveThemeColors,
            contentType: 'chunk',
          ),
        );
        print('🔖 Citation modal displayed for chunk: ${widget.chunk.chunkRefId}');
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Citation not available for this chunk'),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        print('🔖 No citation available for chunk: ${widget.chunk.chunkRefId}');
      }
    } catch (e) {
      print('🔖 Citation error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load citation'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _handleBookmark() async {
    if (widget.chunk.chunkRefId == null) return;
    
    try {
      final isCurrentlyBookmarked = _isBookmarked; // Use local state
      print('🔖 ${isCurrentlyBookmarked ? 'Removing' : 'Adding'} bookmark for chunk: ${widget.chunk.chunkRefId}');
      
      // Optimistically update UI immediately for better user experience
      setState(() {
        _isBookmarked = !isCurrentlyBookmarked;
      });
      
      // Call BooksService to toggle bookmark
      await BooksService.instance.toggleBookmark(widget.chunk.chunkRefId!);
      
      // Notify parent context if callback provided
      if (widget.onBookmarkToggle != null) {
        widget.onBookmarkToggle!(widget.chunk, !isCurrentlyBookmarked);
      }
      
      // Show user feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyBookmarked 
              ? 'Removed from bookmarks' 
              : 'Added to bookmarks'
            ),
            backgroundColor: _borderColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      print('🔖 Bookmark toggle successful');
    } catch (e) {
      print('🔖 Bookmark toggle error: $e');
      
      // Revert the optimistic update on error
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
      
      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update bookmark'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _handleNavigation(bool isNext) async {
    if (widget.chunk.chunkRefId == null) return;
    
    try {
      print('Navigate to ${isNext ? 'next' : 'previous'} chunk from ${widget.chunk.chunkRefId}');
      
      // Call BooksService navigation - now returns the new chunk
      final newChunk = await BooksService.instance.navigateChunk(widget.chunk.chunkRefId!, isNext);
      
      if (newChunk != null) {
        // If parent provides navigation callbacks, call them 
        if (isNext && widget.onNavigateNext != null) {
          widget.onNavigateNext!();
        } else if (!isNext && widget.onNavigatePrevious != null) {
          widget.onNavigatePrevious!();
        }
        print('Navigation successful: ${widget.chunk.chunkRefId} -> ${newChunk.chunkRefId}');
      } else {
        print('Navigation failed: No new chunk returned');
      }
    } catch (e) {
      print('Navigation failed: $e');
    }
  }

  /// 🔶 Handle "See All Sources" for merged augmentation
  void _handleSeeAugmentations() async {
    if (widget.chunk.chunkRefId == null) return;
    
    try {
      print('🔶 Loading augmentations for chunk: ${widget.chunk.chunkRefId}');
      print('🔶 Source type: ${widget.chunk.sourceType}');
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveThemeColors.surface),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Loading all sources...'),
            ],
          ),
          backgroundColor: _borderColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Test the API URL first
      final testUrl = 'https://project.iith.ac.in/bheri/chunk/auglist/${widget.chunk.chunkRefId}/';
      print('🔶 Testing API URL: $testUrl');
      
      // Get repository and make API call
      final booksRepo = Modular.get<BooksRepository>();
      final result = await booksRepo.getAugmentationList(
        chunkRefId: widget.chunk.chunkRefId.toString(),
      );
      
      print('🔶 API Result status: ${result.status}');
      print('🔶 API Result message: ${result.message}');
      
      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        final augmentations = result.data!.augmentations;
        
        print('🔶 Successfully loaded ${augmentations.length} augmentations');
        
        // Show beautiful modal with augmentations
        if (!mounted) return;
        BookAugmentationModal.show(
          context: context,
          augmentations: augmentations,
          originalChunk: widget.chunk,
          themeColors: effectiveThemeColors,
          onSourceClick: widget.onSourceClick,
        );
        
      } else {
        print('🔶 API call failed with: ${result.message}');
        if (!mounted) return;
        _showErrorSnackBar('Debug: ${result.message}');
      }
    } catch (e) {
      print('🔶 Exception in _handleSeeAugmentations: $e');
      if (!mounted) return;
      _showErrorSnackBar('Debug Error: $e');
    }
  }

  /// 🔸 Handle "See Original" for augmentation
  void _handleSeeOriginal() async {
    if (widget.chunk.chunkRefId == null) return;
    
    try {
      print('🔸 Loading original for augmented chunk: ${widget.chunk.chunkRefId}');
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
          children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveThemeColors.surface),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Loading original source...'),
            ],
          ),
          backgroundColor: _borderColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Get repository and make API call
      final booksRepo = Modular.get<BooksRepository>();
      final result = await booksRepo.getOriginalChunk(
        chunkRefId: widget.chunk.chunkRefId.toString(),
      );
      
      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        final originalChunk = result.data!.chunk;
        
        print('🔸 Successfully loaded original chunk: ${originalChunk.chunkRefId}');
        
        // Show original chunk using our existing card widget in a simple modal
        if (!mounted) return;
        _showOriginalChunkModal(originalChunk);
        
      } else {
        _showErrorSnackBar('Failed to load original: ${result.message}');
      }
    } catch (e) {
      print('🔸 Error loading original: $e');
      _showErrorSnackBar('Error loading original source');
    }
  }

  /// Helper method to show error snackbars
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: effectiveThemeColors.surface, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// 🔄 Handle navigation within modal context
  Future<void> _handleModalNavigation(BookChunkRM currentChunk, bool isNext) async {
    if (currentChunk.chunkRefId == null) return;
    
    try {
      print('🔀 Modal Navigation: ${isNext ? 'next' : 'previous'} from ${currentChunk.chunkRefId}');
      
      // Use BooksService to get the new chunk
      final newChunk = await BooksService.instance.navigateChunk(currentChunk.chunkRefId!, isNext);
      
      if (newChunk != null) {
        // Close current modal and show new one with the navigated chunk
        Navigator.of(context).pop();
        await Future.delayed(const Duration(milliseconds: 100)); // Small delay for smooth transition
        _showOriginalChunkModal(newChunk);
        print('🔀 Modal Navigation successful: ${currentChunk.chunkRefId} -> ${newChunk.chunkRefId}');
      } else {
        print('🔀 Modal Navigation failed: No new chunk returned');
        // Show error message but don't close modal
        _showErrorSnackBar('No ${isNext ? 'next' : 'previous'} chunk available');
      }
    } catch (e) {
      print('🔀 Modal Navigation error: $e');
      _showErrorSnackBar('Navigation failed');
    }
  }

  /// 🔹 Show original chunk using our existing book card widget
  void _showOriginalChunkModal(BookChunkRM originalChunk) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.75, // Start at 75% height - opens more fully
          minChildSize: 0.4, // Minimum 40% height  
          maxChildSize: 0.95, // Maximum 95% height - allow nearly full screen
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.source,
                      color: _linkColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Original Source',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              // Original chunk using our existing widget
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: BookChunkItemLightweightWidget(
                    chunk: originalChunk,
                    themeColors: effectiveThemeColors,
                    onSourceClick: widget.onSourceClick,
                    // Enable navigation within modal - update the modal content
                    onNavigatePrevious: () => _handleModalNavigation(originalChunk, false),
                    onNavigateNext: () => _handleModalNavigation(originalChunk, true),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}