import 'package:dharak_flutter/app/types/dictionary/definition.dart';
import 'package:dharak_flutter/app/types/dictionary/dict_word_detail.dart';
import 'package:dharak_flutter/app/ui/widgets/code_wrapper.dart';
import 'package:dharak_flutter/core/services/citation_share_service.dart';
import 'package:dharak_flutter/res/layouts/containers.dart';
import 'package:dharak_flutter/res/styles/decorations.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/markdown_widget.dart';

/// Reusable Word Definition Card component that works in any context
class WordDefinitionCard extends StatefulWidget {
  final WordDefinitionRM definition;
  final DictWordDetailRM? wordDetails; // For LLM Summary
  
  // Action callbacks - optional for different contexts
  final VoidCallback? onCopy;
  final Function(String url)? onSourceClick;
  final VoidCallback? onShare;
  final VoidCallback? onCitation;
  
  // UI configuration
  final bool showSource;
  final bool showLLMSummary;
  final bool isCompact;
  final bool isExpandable;
  final bool showShare;
  final bool showCitation;
  
  // Theme (auto-detected if not provided)
  final AppThemeColors? themeColors;
  final AppThemeDisplay? appThemeDisplay;

  const WordDefinitionCard({
    super.key,
    required this.definition,
    this.wordDetails,
    this.onCopy,
    this.onSourceClick,
    this.onShare,
    this.onCitation,
    this.showSource = true,
    this.showLLMSummary = false,
    this.isCompact = false,
    this.isExpandable = true,
    this.showShare = true,
    this.showCitation = true,
    this.themeColors,
    this.appThemeDisplay,
  });

  @override
  State<WordDefinitionCard> createState() => _WordDefinitionCardState();
}

class _WordDefinitionCardState extends State<WordDefinitionCard> {
  // Key for RepaintBoundary to enable screenshot sharing
  late final GlobalKey _repaintBoundaryKey;

  @override
  void initState() {
    super.initState();
    _repaintBoundaryKey = GlobalKey();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveThemeColors = widget.themeColors ?? 
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: const Color(0xFF6CE18D), isDark: false);
    
    final effectiveAppThemeDisplay = widget.appThemeDisplay ?? 
        TdThemeHelper.prepareThemeDisplay(context);

    if (widget.isCompact) {
      return _buildCompactCard(effectiveThemeColors, effectiveAppThemeDisplay);
    }
    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: _buildFullCard(effectiveThemeColors, effectiveAppThemeDisplay),
    );
  }

  Widget _buildCompactCard(AppThemeColors themeColors, AppThemeDisplay appThemeDisplay) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Icon(
          Icons.description,
          color: themeColors.secondaryColor,
          size: 20,
        ),
        title: Text(
          widget.definition.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TdResTextStyles.h5,
        ),
        subtitle: Text(
          widget.definition.srcShortTitle,
          style: TdResTextStyles.caption,
        ),
        trailing: null,
      ),
    );
  }

  Widget _buildFullCard(AppThemeColors themeColors, AppThemeDisplay appThemeDisplay) {
    return CommonContainer(
      appThemeDisplay: appThemeDisplay,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: TdResDecorations.decorationCardOutlined(
          Colors.transparent,
          themeColors.isDark 
              ? themeColors.onSurface.withAlpha(0x08)
              : themeColors.surface,
          isElevated: false,
          shadow: themeColors.isDark 
              ? null 
              : themeColors.secondaryColor.withAlpha(0x2),
        ).copyWith(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              width: 4,
              color: Color.alphaBlend(
                themeColors.onSurface.withAlpha(0x56),
                themeColors.secondaryLight,
              ),
            ),
          ),
        ),
        child: Column(
          children: [
            if (widget.isExpandable)
              _buildExpandableContent(themeColors)
            else
              _buildStaticContent(themeColors),
            _buildActions(themeColors),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableContent(AppThemeColors themeColors) {
    return ExpandableNotifier(
      child: ExpandablePanel(
        collapsed: _buildCollapsedContent(themeColors),
        theme: ExpandableThemeData(
          inkWellBorderRadius: BorderRadius.circular(18),
          iconPadding: const EdgeInsets.only(right: 8, top: 12),
          iconColor: themeColors.onSurfaceHigh,
          headerAlignment: ExpandablePanelHeaderAlignment.center,
          tapBodyToExpand: true,
          tapBodyToCollapse: true,
          hasIcon: true,
        ),
        header: _buildHeader(themeColors),
        expanded: _buildExpandedContent(themeColors),
      ),
    );
  }

  Widget _buildStaticContent(AppThemeColors themeColors) {
    return Column(
      children: [
        _buildHeader(themeColors),
        _buildExpandedContent(themeColors),
      ],
    );
  }

  Widget _buildCollapsedContent(AppThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4).copyWith(top: 14),
      child: Text(
        widget.definition.text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TdResTextStyles.h5,
      ),
    );
  }

  Widget _buildHeader(AppThemeColors themeColors) {
    final linkColor = Color.alphaBlend(
      themeColors.onSurface.withAlpha(0x46),
      themeColors.secondaryColor,
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
      child: Row(
        spacing: 6,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.description, 
            size: 20, 
            color: linkColor,
          ),
          Flexible(
            flex: 1,
            child: Text(
              widget.definition.srcShortTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TdResTextStyles.p3.copyWith(
                color: Color.alphaBlend(
                  themeColors.onSurface.withAlpha(0x66),
                  themeColors.secondaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(AppThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          _buildMarkdown(widget.definition.text, themeColors),
          
          // Note: LLM Summary is now shown at page level, not per card
        ],
      ),
    );
  }

  Widget _buildActions(AppThemeColors themeColors) {
    final linkColor = Color.alphaBlend(
      themeColors.onSurface.withAlpha(0x46),
      themeColors.secondaryColor,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TdResGaps.h_12,
        
        // Source link
        if (widget.showSource && widget.definition.sourceUrl != null)
          SizedBox(
            height: 30,
            child: TextButton.icon(
              iconAlignment: IconAlignment.end,
              style: TextButton.styleFrom(
                iconColor: linkColor,
                foregroundColor: linkColor,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                backgroundColor: themeColors.secondaryColor.withAlpha(0x2),
              ),
              onPressed: () => widget.onSourceClick?.call(widget.definition.sourceUrl!) ?? 
                           _handleSourceClick(widget.definition.sourceUrl!),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(
                "Source",
                style: TdResTextStyles.buttonSmall.copyWith(
                  decoration: TextDecoration.underline,
                  decorationThickness: 2,
                  decorationColor: linkColor,
                  color: Colors.transparent,
                  shadows: [
                    Shadow(
                      color: linkColor,
                      blurRadius: 0,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        const Spacer(flex: 1),
        
        // Action buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Citation button (if dictRefId is available)
            if (widget.showCitation && widget.definition.dictRefId != null)
              IconButton(
                onPressed: widget.onCitation ?? () => _handleCitation(),
                icon: Icon(
                  Icons.format_quote,
                  size: 18,
                  color: themeColors.onSurface,
                ),
              ),
            
            // Share button
            if (widget.showShare)
              IconButton(
                onPressed: widget.onShare ?? () => _handleShare(),
                icon: Icon(
                  Icons.share,
                  size: 18,
                  color: themeColors.onSurface,
                ),
              ),
            
          ],
        ),
      ],
    );
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
      selectable: false,
      config: config.copy(
        configs: [
          themeColors.isDark
              ? PreConfig.darkConfig.copy(wrapper: codeWrapper)
              : PreConfig().copy(wrapper: codeWrapper),
        ],
      ),
    );
  }

  Widget _buildLLMSummary(AppThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            spacing: 16,
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
              Text(
                "LLM Summary",
                textAlign: TextAlign.start,
                style: TdResTextStyles.h4Medium.copyWith(
                  color: themeColors.onSurface,
                ),
              ),
            ],
          ),
          TdResGaps.v_12,
          _buildMarkdown(widget.wordDetails!.llmDef!, themeColors),
        ],
      ),
    );
  }

  // Default action handlers

  void _handleCitation() {
    // Use the citation service to show definition citation
    if (widget.definition.dictRefId != null) {
      CitationShareService.instance.showDefinitionCitation(
        context,
        widget.definition.dictRefId!,
      );
    }
  }

  void _handleShare() {
    // Use the share service to show definition share options
    CitationShareService.instance.showDefinitionShare(
      context,
      _repaintBoundaryKey,
      widget.definition.text,
      widget.definition.dictRefId?.toString(),
      null, // searchedWord - could be passed as parameter if needed
    );
  }

  void _handleSourceClick(String url) {
    if (widget.onSourceClick != null) {
      widget.onSourceClick!(url);
    }
  }

}
