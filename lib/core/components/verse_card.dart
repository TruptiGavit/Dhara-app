import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/types/verse/verse_other_field.dart';
import 'package:dharak_flutter/app/ui/widgets/code_wrapper.dart';
import 'package:dharak_flutter/app/ui/widgets/verse_text.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/controller.dart';
import 'package:dharak_flutter/core/services/verse_service.dart';
import 'package:dharak_flutter/core/services/citation_share_service.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:dharak_flutter/res/layouts/containers.dart';
import 'package:dharak_flutter/res/styles/decorations.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/markdown_widget.dart';

/// Reusable Verse Card component that works in any context
/// Automatically updates when verse data changes through VerseService
class VerseCard extends StatefulWidget {
  final VerseRM verse;
  
  // Navigation callbacks - optional for different contexts
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onBookmark;
  final VoidCallback? onCopy;
  final Function(String url)? onSourceClick;
  final VoidCallback? onShare;
  final VoidCallback? onCitation;
  
  // UI configuration
  final bool showNavigation;
  final bool showBookmark;
  final bool showSource;
  final bool showOtherFields;
  final bool isCompact;
  final bool showShare;
  final bool showCitation;
  
  // Theme (auto-detected if not provided)
  final AppThemeColors? themeColors;
  final AppThemeDisplay? appThemeDisplay;

  const VerseCard({
    super.key,
    required this.verse,
    this.onPrevious,
    this.onNext,
    this.onBookmark,
    this.onCopy,
    this.onSourceClick,
    this.onShare,
    this.onCitation,
    this.showNavigation = true,
    this.showBookmark = true,
    this.showSource = true,
    this.showOtherFields = true,
    this.isCompact = false,
    this.showShare = true,
    this.showCitation = true,
    this.themeColors,
    this.appThemeDisplay,
  });

  @override
  State<VerseCard> createState() => _VerseCardState();
}

class _VerseCardState extends State<VerseCard> {
  late AppThemeColors themeColors;
  late AppThemeDisplay appThemeDisplay;
  
  // ExpansionTileController removed - using direct state management
  bool _mIsFitlerOpen = false;
  List<bool> _mOtherFieldsExpandedStates = [];
  
  ExpandableController? _expansionController = ExpandableController(
    initialExpanded: false,
  );

  // Key for RepaintBoundary to enable screenshot sharing
  late final GlobalKey _repaintBoundaryKey;

  @override
  void initState() {
    super.initState();
    _repaintBoundaryKey = GlobalKey();
    _initializeOtherFieldsStates();
    _expansionController?.addListener(_expansionListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prepareTheme();
  }

  @override
  void didUpdateWidget(covariant VerseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verse.versePk != widget.verse.versePk ||
        (oldWidget.verse.otherFields?.length ?? 0) != (widget.verse.otherFields?.length ?? 0)) {
      _initializeOtherFieldsStates();
    }
  }

  @override
  void dispose() {
    _expansionController?.removeListener(_expansionListener);
    super.dispose();
  }

  void _prepareTheme() {
    themeColors = widget.themeColors ?? 
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: const Color(0xFF6CE18D), isDark: false);
    appThemeDisplay = widget.appThemeDisplay ?? 
        TdThemeHelper.prepareThemeDisplay(context);
  }

  void _initializeOtherFieldsStates() {
    _mOtherFieldsExpandedStates = List<bool>.filled(
      widget.verse.otherFields?.length ?? 0, 
      false,
    );
  }

  void _expansionListener() {
    setState(() {
      // Trigger rebuild when expansion state changes so buttons show/hide properly
    });
  }

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
  Widget build(BuildContext context) {
    // Listen to verse updates from VerseService
    return StreamBuilder<VerseRM?>(
      stream: VerseService.instance.getVerseStream(widget.verse.versePk),
      builder: (context, snapshot) {
        // Use updated verse from stream, fallback to widget verse
        final currentVerse = snapshot.data ?? widget.verse;
        return _buildCard(currentVerse);
      },
    );
  }

  Widget _buildCard(VerseRM verse) {
    if (widget.isCompact) {
      return _buildCompactCard(verse);
    }
    return _buildFullCard(verse);
  }

  Widget _buildCompactCard(VerseRM verse) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: VerseText(
          verse.verseLetText ?? verse.verseText ?? 'No verse text available',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TdResTextStyles.p2,
          language: _getCurrentLanguage(),
        ),
        subtitle: Text(
          verse.verseRef ?? 'Unknown Reference',
          style: TdResTextStyles.caption,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showBookmark)
              IconButton(
                icon: Icon(
                  (verse.isStarred ?? false) ? Icons.bookmark : Icons.bookmark_border,
                  color: themeColors.onSurface,
                ),
                onPressed: widget.onBookmark ?? () => _handleBookmark(verse),
              ),
          ],
        ),
        onTap: () {
          _expansionController?.toggle();
        },
      ),
    );
  }

  Widget _buildFullCard(VerseRM verse) {
    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: CommonContainer(
        appThemeDisplay: appThemeDisplay,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          decoration: TdResDecorations.decorationCardOutlined(
            Color.alphaBlend(
              themeColors.primary.withAlpha(0x12),
              themeColors.onSurfaceLowest,
            ),
            themeColors.surface.withAlpha(0x96),
            isElevated: false,
          ).copyWith(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeColors.onSurfaceDisable),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Column(
            children: [
              ExpandableNotifier(
                child: ExpandablePanel(
                  controller: _expansionController,
                  collapsed: _buildCollapsedHeader(verse),
                  theme: ExpandableThemeData(
                    inkWellBorderRadius: BorderRadius.circular(18),
                    iconPadding: const EdgeInsets.only(right: 12),
                    headerAlignment: ExpandablePanelHeaderAlignment.center,
                    iconColor: themeColors.onSurfaceHigh,
                    tapBodyToCollapse: true,
                    tapBodyToExpand: true,
                    tapHeaderToExpand: true,
                  ),
                  header: _buildHeader(verse),
                  expanded: _buildExpanded(verse),
                ),
              ),
              _buildBottomSection(verse),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedHeader(VerseRM verse) {
    return InkWell(
      onTap: () => _expansionController?.toggle(),
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
        child: VerseText(
          "..${_getTruncatedText(verse)}..",
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TdResTextStyles.p2,
          language: _getCurrentLanguage(),
        ),
      ),
    );
  }

  String _getTruncatedText(VerseRM verse) {
    final text = verse.verseLetText ?? verse.verseText ?? 'No verse text available';
    return text.length > 30 ? text.substring(0, 30) : text;
  }

  Widget _buildHeader(VerseRM verse) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Row(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  themeColors.onSurface.withAlpha(0x56),
                  themeColors.primaryLight,
                ).withAlpha(0x12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                verse.verseRef ?? 'Unknown Reference',
                style: TdResTextStyles.p3.copyWith(
                  color: Color.alphaBlend(
                    themeColors.onSurface.withAlpha(0x76),
                    themeColors.primaryHigh,
                  ),
                ),
              ),
            ),
          ),
          if (verse.similarity != null) _buildSimilarityChip(verse),
        ],
      ),
    );
  }

  Widget _buildSimilarityChip(VerseRM verse) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: themeColors.primary,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: themeColors.secondaryColor.withAlpha(0x12),
            spreadRadius: 0,
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        verse.similarity!,
        style: TdResTextStyles.caption.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildExpanded(VerseRM verse) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4).copyWith(top: 12),
      child: InkWell(
        onTap: () => _expansionController?.toggle(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: VerseText(
            verse.verseText ?? 'No verse text available',
            style: TdResTextStyles.p1.copyWith(
              color: themeColors.onSurface,
              height: 1.5,
            ),
            language: _getCurrentLanguage(),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(VerseRM verse) {
    if (widget.showOtherFields && (verse.otherFields?.isNotEmpty ?? false)) {
      return _buildOtherFieldsExpansion(verse);
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: _buildActions(verse),
      );
    }
  }

  Widget _buildActions(VerseRM verse) {
    final linkColor = Color.alphaBlend(
      themeColors.onSurface.withAlpha(0x46),
      themeColors.primaryHigh,
    );
    
    final isExpanded = _expansionController?.expanded == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Source line (always left-aligned)
        if (widget.showSource && verse.sourceUrl != null)
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 30,
              child: TextButton(
                style: TextButton.styleFrom(
                  iconColor: linkColor,
                  foregroundColor: linkColor,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  backgroundColor: themeColors.secondaryColor.withAlpha(0x2),
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => widget.onSourceClick?.call(verse.sourceUrl!) ?? 
                             _handleSourceClick(verse.sourceUrl!),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text("Source:", style: TdResTextStyles.caption.copyWith(color: linkColor)),
                    Text(
                      verse.sourceName ?? 'Unknown Source',
                      style: TdResTextStyles.caption.copyWith(
                        decoration: TextDecoration.underline,
                        decorationThickness: 2,
                        decorationColor: linkColor,
                        color: Colors.transparent,
                        shadows: [Shadow(color: linkColor, blurRadius: 0, offset: const Offset(0, -1))],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Action icons line (only when expanded, right-aligned)
        if (isExpanded && _hasAnyActionIcons(verse))
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Wrap(
                  spacing: 4,
                  children: [
                    // Navigation buttons
                    if (widget.showNavigation) ...[
                      _buildActionButton(
                        icon: Icons.chevron_left,
                        onTap: widget.onPrevious ?? () => _handlePrevious(verse),
                      ),
                      _buildActionButton(
                        icon: Icons.chevron_right,
                        onTap: widget.onNext ?? () => _handleNext(verse),
                      ),
                    ],

                    // Bookmark button
                    if (widget.showBookmark)
                      _buildActionButton(
                        icon: (verse.isStarred ?? false) ? Icons.bookmark_rounded : Icons.bookmark_border_outlined,
                        onTap: widget.onBookmark ?? () => _handleBookmark(verse),
                      ),

                    // Citation button
                    if (widget.showCitation)
                      _buildActionButton(
                        icon: Icons.format_quote,
                        onTap: widget.onCitation ?? () => _handleCitation(verse),
                      ),

                    // Share button
                    if (widget.showShare)
                      _buildActionButton(
                        icon: Icons.share,
                        onTap: widget.onShare ?? () => _handleShare(verse),
                      ),
                    
                    // Info button (for other fields expansion)
                    if (widget.showOtherFields && (verse.otherFields?.isNotEmpty ?? false))
                      _buildActionButton(
                        icon: Icons.info_outline,
                        onTap: () => _toggleOtherFields(),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  // Helper method to check if any action icons should be shown
  bool _hasAnyActionIcons(VerseRM verse) {
    return widget.showNavigation || 
           widget.showBookmark || 
           widget.showCitation || 
           widget.showShare ||
           (widget.showOtherFields && (verse.otherFields?.isNotEmpty ?? false));
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: themeColors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildOtherFieldsExpansion(VerseRM verse) {
    return Column(
      children: [
        // Source and actions section (outside ExpansionTile)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: _buildActions(verse),
        ),
        
        // More Info expansion section (only show when expanded)
        if (_mIsFitlerOpen)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8).copyWith(bottom: 8),
            decoration: BoxDecoration(
              color: themeColors.primary.withAlpha(0x64),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            width: double.maxFinite,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "More Info",
                    style: TdResTextStyles.h6Medium,
                    textAlign: TextAlign.left,
                  ),
                ),
                const Divider(color: Colors.black26, height: 1),
                ...(verse.otherFields ?? [])
                    .asMap()
                    .map((i, e) => MapEntry(i, _buildOtherFieldItem(i, e)))
                    .values,
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOtherFieldItem(int index, VerseOtherFieldRM field) {
    final isExpanded = _mOtherFieldsExpandedStates.length > index
        ? _mOtherFieldsExpandedStates[index]
        : false;

    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: Colors.white,
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        key: Key('tile_${index}_$isExpanded'),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        initiallyExpanded: isExpanded,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        iconColor: Colors.black87,
        minTileHeight: 44,
        collapsedIconColor: Colors.black54,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: const Border(bottom: BorderSide(color: Colors.black12)),
        collapsedShape: const Border(bottom: BorderSide(color: Colors.black12)),
        onExpansionChanged: (expanded) => _toggleOtherFieldItem(index, expanded),
        title: Text(
          field.title ?? 'Other Field',
          style: TdResTextStyles.h5Medium.copyWith(
            color: themeColors.onSurface.withAlpha(0x90),
          ),
        ),
        children: [
          InkWell(
            onTap: () => _toggleOtherFieldItem(index, !isExpanded),
            child: Container(
              decoration: TdResDecorations.decorationCardOutlined(
                Color.alphaBlend(
                  themeColors.primary.withAlpha(0x12),
                  themeColors.onSurfaceLowest,
                ),
                themeColors.surface.withAlpha(0xb0),
                isElevated: false,
              ).copyWith(
                borderRadius: BorderRadius.circular(6),
                border: Border(
                  left: BorderSide(
                    width: 4,
                    color: Color.alphaBlend(
                      themeColors.onSurface.withAlpha(0x36),
                      themeColors.primary,
                    ),
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: VerseText(
                field.value ?? 'No content available',
                style: TdResTextStyles.p2.copyWith(
                  color: themeColors.onSurface,
                  height: 1.4,
                ),
                language: _getCurrentLanguage(),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // Event handlers
  void _toggleOtherFields() {
    setState(() {
      _mIsFitlerOpen = !_mIsFitlerOpen;
    });
  }

  void _toggleOtherFieldItem(int index, bool isExpanded) {
    if (_mOtherFieldsExpandedStates.length <= index) return;

    setState(() {
      _mOtherFieldsExpandedStates[index] = isExpanded;
    });
  }

  // Default action handlers (can be overridden by callbacks)
  void _handlePrevious(VerseRM verse) {
    VerseService.instance.navigateVerse(verse.versePk, false);
  }

  void _handleNext(VerseRM verse) {
    VerseService.instance.navigateVerse(verse.versePk, true);
  }

  void _handleBookmark(VerseRM verse) {
    VerseService.instance.toggleBookmark(verse.versePk);
  }


  void _handleCitation(VerseRM verse) {
    // Use the citation service to show verse citation
    CitationShareService.instance.showVerseCitation(
      context,
      verse.versePk,
      themeColors: themeColors,
    );
  }

  void _handleShare(VerseRM verse) {
    // Use the share service to show verse share options
    CitationShareService.instance.showVerseShare(
      context,
      _repaintBoundaryKey,
      verse.verseText ?? 'No verse text available',
      verse.versePk.toString(),
      themeColors: themeColors,
    );
  }

  void _handleSourceClick(String url) {
    // TODO: Implement URL launch
    // launchUrl(Uri.parse(url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening: $url')),
    );
  }
}
