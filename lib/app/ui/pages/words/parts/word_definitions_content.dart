import 'package:dharak_flutter/app/ui/pages/words/parts/item.dart';
import 'package:dharak_flutter/app/ui/pages/words/parts/similar_words.dart';
import 'package:dharak_flutter/app/domain/share/repo.dart';
import 'package:dharak_flutter/app/domain/citation/repo.dart';
import 'package:dharak_flutter/app/ui/widgets/share_modal.dart';
import 'package:dharak_flutter/app/ui/widgets/citation_modal.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/app/types/dictionary/word_definitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_modular/flutter_modular.dart';
import 'package:url_launcher/url_launcher.dart';

// 🚀 PERFORMANCE: Constants to avoid recreating EdgeInsets repeatedly
const EdgeInsets _kDefinitionMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 4);
const EdgeInsets _kWordOverviewMargin = EdgeInsets.all(16);
const EdgeInsets _kWordOverviewPadding = EdgeInsets.all(16);

/// Reusable WordDefine content widget that can be embedded anywhere
/// Contains all the functionality of the main WordDefine page but without navigation
class WordDefinitionsContent extends StatefulWidget {
  final DictWordDefinitionsRM wordDefinitions;
  final AppThemeColors themeColors;
  final AppThemeDisplay? appThemeDisplay;
  final bool showSearch;
  final bool showTitle;
  final bool showShareButton;
  final bool showAISummary;
  final bool showSimilarWords;
  final Function(String)? onSimilarWordClick;

  const WordDefinitionsContent({
    super.key,
    required this.wordDefinitions,
    required this.themeColors,
    this.appThemeDisplay,
    this.showSearch = false,
    this.showTitle = true,
    this.showShareButton = true,
    this.showAISummary = true,
    this.showSimilarWords = true,
    this.onSimilarWordClick,
  });

  @override
  State<WordDefinitionsContent> createState() => _WordDefinitionsContentState();
}

class _WordDefinitionsContentState extends State<WordDefinitionsContent> {
  final GlobalKey<SliverAnimatedListState> listKey = GlobalKey<SliverAnimatedListState>();
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: Container(
        color: Color.alphaBlend(
          widget.themeColors.secondaryColor.withAlpha(0x12),
          widget.themeColors.surface,
        ),
        child: _buildOptimizedContent(),
      ),
    );
  }

  /// 🚀 PERFORMANCE FIX: Use lightweight ListView instead of heavy CustomScrollView
  Widget _buildOptimizedContent() {
    final definitions = widget.wordDefinitions.details.definitions;
    final similarWords = widget.wordDefinitions.similarWords;
    
    // For small lists (<50 items), use simple Column in SingleChildScrollView
    if (definitions.length < 50) {
      return SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Word Overview Section
            if (widget.showTitle) _buildWordOverviewSimple(),
            
            // Definitions Header
            if (definitions.isNotEmpty) _buildDefinitionsHeaderSimple(),
            
            // Definitions List (simple column for small lists)
            ...definitions.map((definition) => Container(
              key: ValueKey('def_${definition.dictRefId ?? definition.hashCode}'), // 🚀 PERFORMANCE: Stable keys
              margin: _kDefinitionMargin, // 🚀 PERFORMANCE: Const EdgeInsets
              child: WordDefinitionItemWidget(
                key: ValueKey('widget_def_${definition.dictRefId ?? definition.hashCode}'), // 🚀 PERFORMANCE: Widget keys
                appThemeDisplay: widget.appThemeDisplay,
                themeColors: widget.themeColors,
                entity: definition,
                onClickCopy: (message) {
                  final dictRefId = definition.dictRefId;
                  if (dictRefId != null) {
                    _copyDefinitionToClipboard(dictRefId);
                  } else {
                    _copyToClipboard(message);
                  }
                },
                onClickShare: (widgetKey) {
                  _showShareModal(
                    definition.text,
                    definition.dictRefId?.toString() ?? definition.text.hashCode.toString(),
                    widgetKey,
                    definition,
                  );
                },
                onClickExternalUrl: (urlLink) => _launchExternalUrl(urlLink),
                onClickCitation: (dictRefId) => _showCitationModal(dictRefId),
              ),
            )).toList(),
            
            // Similar Words Section
            if (widget.showSimilarWords && similarWords.isNotEmpty)
              WordSimilarWordsWidget(
                appThemeDisplay: widget.appThemeDisplay,
                themeColors: widget.themeColors,
                similarWords: similarWords,
                onSearchClick: widget.onSimilarWordClick,
              ),
            
            const SizedBox(height: 40),
          ],
        ),
      );
    }
    
    // For larger lists, use optimized ListView.builder
    final similarWords = widget.wordDefinitions.similarWords;
    final hasSimilarWords = widget.showSimilarWords && similarWords.isNotEmpty;
    final itemCount = definitions.length + 2 + (hasSimilarWords ? 2 : 1); // +2 for header/overview, +1 or +2 for similar words/spacing
    
    return ListView.builder(
      controller: _scrollController,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0 && widget.showTitle) {
          return _buildWordOverviewSimple();
        } else if (index == 1 && definitions.isNotEmpty) {
          return _buildDefinitionsHeaderSimple();
        } else if (index == definitions.length + 2 && hasSimilarWords) {
          // Similar words section
          return WordSimilarWordsWidget(
            appThemeDisplay: widget.appThemeDisplay,
            themeColors: widget.themeColors,
            similarWords: similarWords,
            onSearchClick: widget.onSimilarWordClick,
          );
        } else if (index == itemCount - 1) {
          // Bottom spacing
          return const SizedBox(height: 40);
        } else {
          final defIndex = widget.showTitle ? index - 2 : index - 1;
          if (defIndex < 0 || defIndex >= definitions.length) {
            return const SizedBox.shrink();
          }
          
          final definition = definitions[defIndex];
          return Container(
            key: ValueKey('def_list_${definition.dictRefId ?? definition.hashCode}'), // 🚀 PERFORMANCE: ListView keys
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: WordDefinitionItemWidget(
              key: ValueKey('widget_list_def_${definition.dictRefId ?? definition.hashCode}'), // 🚀 PERFORMANCE: Widget keys
              appThemeDisplay: widget.appThemeDisplay,
              themeColors: widget.themeColors,
              entity: definition,
              onClickCopy: (message) {
                final dictRefId = definition.dictRefId;
                if (dictRefId != null) {
                  _copyDefinitionToClipboard(dictRefId);
                } else {
                  _copyToClipboard(message);
                }
              },
              onClickShare: (widgetKey) {
                _showShareModal(
                  definition.text,
                  definition.dictRefId?.toString() ?? definition.text.hashCode.toString(),
                  widgetKey,
                  definition,
                );
              },
              onClickExternalUrl: (urlLink) => _launchExternalUrl(urlLink),
              onClickCitation: (dictRefId) => _showCitationModal(dictRefId),
            ),
          );
        }
      },
    );
  }

  /// 🚀 Simplified word overview without Sliver wrapper
  Widget _buildWordOverviewSimple() {
    final word = widget.wordDefinitions.givenWord;
    final llmSummary = widget.wordDefinitions.details.llmDef;
    final otherScripts = widget.wordDefinitions.details.otherScripts;

    return Container(
      margin: _kWordOverviewMargin, // 🚀 PERFORMANCE: Const EdgeInsets
      padding: _kWordOverviewPadding, // 🚀 PERFORMANCE: Const EdgeInsets
      decoration: BoxDecoration(
        color: widget.themeColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.themeColors.primary.withAlpha(0x40),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word title
          Text(
            word,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: widget.themeColors.primary,
            ),
          ),
          
          // Other scripts
          if (otherScripts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: otherScripts.entries
                  .where((script) => script.value?.isNotEmpty == true)
                  .map((script) {
                return Text(
                  '${script.key}: ${script.value}',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.themeColors.onSurfaceMedium,
                  ),
                );
              }).toList(),
            ),
          ],
          
          // LLM Summary
          if (widget.showAISummary && llmSummary?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.themeColors.primaryLight.withAlpha(0x40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Summary',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.themeColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    llmSummary!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: widget.themeColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🚀 Simplified definitions header without Sliver wrapper  
  Widget _buildDefinitionsHeaderSimple() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        "Definitions",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: widget.themeColors.primary,
        ),
      ),
    );
  }

  Widget _buildWordOverview() {
    final word = widget.wordDefinitions.givenWord;
    final llmSummary = widget.wordDefinitions.details.llmDef;
    final otherScripts = widget.wordDefinitions.details.otherScripts;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.themeColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.themeColors.primary.withAlpha(0x40),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word title
            Text(
              word,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: widget.themeColors.primary,
              ),
            ),
            
            // Other scripts
            if (otherScripts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: otherScripts.entries
                    .where((script) => script.value?.isNotEmpty == true)
                    .map((script) {
                  return Text(
                    '${script.key}: ${script.value}',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.themeColors.onSurfaceMedium,
                    ),
                  );
                }).toList(),
              ),
            ],
            
            // LLM Summary
            if (widget.showAISummary && llmSummary?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.themeColors.primaryLight.withAlpha(0x40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Summary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.themeColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      llmSummary!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: widget.themeColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDefinitionsHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "Definitions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.themeColors.onSurface.withAlpha(0xb6),
                ),
              ),
            ),
            if (widget.showShareButton)
              TextButton.icon(
                onPressed: () {
                  _showScreenShareModal();
                },
                style: TextButton.styleFrom(
                  backgroundColor: widget.themeColors.secondaryLight.withAlpha(0x22),
                ),
                label: Text(
                  "Share",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.alphaBlend(
                      widget.themeColors.onSurface.withAlpha(0x96),
                      widget.themeColors.secondaryLight,
                    ),
                  ),
                ),
                icon: Icon(
                  Icons.share,
                  size: 16,
                  color: Color.alphaBlend(
                    widget.themeColors.onSurface.withAlpha(0x96),
                    widget.themeColors.secondaryLight,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefinitionsList() {
    final definitions = widget.wordDefinitions.details.definitions;
    
    if (definitions.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Text(
            "No definitions available",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: widget.themeColors.onSurfaceDisable,
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < definitions.length) {
            return Container(
              margin: _kDefinitionMargin, // 🚀 PERFORMANCE: Const EdgeInsets
              child: WordDefinitionItemWidget(
                appThemeDisplay: widget.appThemeDisplay,
                themeColors: widget.themeColors,
                entity: definitions[index],
                onClickCopy: (message) {
                  final dictRefId = definitions[index].dictRefId;
                  if (dictRefId != null) {
                    _copyDefinitionToClipboard(dictRefId);
                  } else {
                    _copyToClipboard(message);
                  }
                },
                onClickShare: (widgetKey) {
                  print('📤 WordDefine Share clicked: defId=${definitions[index].dictRefId}, text=${definitions[index].text.substring(0, 30)}...');
                  _showShareModal(
                    definitions[index].text,
                    definitions[index].dictRefId?.toString() ?? definitions[index].text.hashCode.toString(),
                    widgetKey,
                    definitions[index], // Pass the full definition object
                  );
                },
                onClickExternalUrl: (urlLink) => _launchExternalUrl(urlLink),
                onClickCitation: (dictRefId) => _showCitationModal(dictRefId),
              ),
            );
          }
          return const SizedBox.shrink();
        },
        childCount: definitions.length,
      ),
    );
  }

  // === Real functionality methods (same as main WordDefine page) ===

  Future<void> _copyDefinitionToClipboard(int defnId) async {
    try {
      final shareRepo = Modular.get<ShareRepository>();
      final success = await shareRepo.copyDefinitionToClipboard(defnId.toString());
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Definition copied to clipboard!",
              style: TdResTextStyles.h5.copyWith(color: widget.themeColors.surface),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to copy definition')),
        );
      }
    }
  }

  void _copyToClipboard(String message) {
    Clipboard.setData(ClipboardData(text: message));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Copied to clipboard!",
            style: TdResTextStyles.h5.copyWith(color: widget.themeColors.surface),
          ),
        ),
      );
    }
  }

  void _showShareModal(String text, String definitionId, [GlobalKey? widgetKey, dynamic definition]) {
    print('📤 WordDefine _showShareModal called: defId=$definitionId, hasWidgetKey=${widgetKey != null}');
    try {
      ShareModal.show(
        context: context,
        themeColors: widget.themeColors,
        textToShare: text,
        onCopyText: () {
          print('📤 WordDefine ShareModal onCopyText called');
          final dictRefId = int.tryParse(definitionId);
          if (dictRefId != null) {
            _copyDefinitionToClipboard(dictRefId);
          } else {
            _copyToClipboard(text);
          }
        },
        onShareImage: widgetKey != null && definition != null ? () {
          print('📤 WordDefine ShareModal onShareImage called');
          _shareImage(widgetKey, definition);
        } : null,
        contentType: 'definition',
      );
      print('📤 WordDefine ShareModal.show completed successfully');
    } catch (e) {
      print('📤 WordDefine Error showing ShareModal: $e');
    }
  }

  void _showScreenShareModal() {
    ShareModal.show(
      context: context,
      themeColors: widget.themeColors,
      textToShare: widget.wordDefinitions.givenWord,
      onCopyText: () {
        _copyToClipboard(widget.wordDefinitions.givenWord);
      },
      onShareImage: () {
        _shareScreenContent();
      },
      isScreenShare: true,
      contentType: 'definition',
    );
  }

  Future<void> _shareScreenContent() async {
    print('📤 _shareScreenContent called for word definitions');
    try {
      final shareRepo = Modular.get<ShareRepository>();
      
      // Scroll to top to ensure word overview (LLM summary) is visible
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0.0, // Scroll to top
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        // Wait for scroll animation to complete
        await Future.delayed(const Duration(milliseconds: 350));
      }
      
      // Use the repaint boundary key for full screen capture
      final renderObject = _repaintBoundaryKey.currentContext?.findRenderObject();
      if (renderObject == null) {
        print('📤 WordDefine Error: Could not find render object for screen content');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to capture screen for sharing')),
          );
        }
        return;
      }

      print('📤 WordDefine Calling shareDefinitionAsImage for screen capture (including top overview)');
      final success = await shareRepo.shareDefinitionAsImage(
        widgetKey: _repaintBoundaryKey,
        definitionId: 'all_definitions',
        definitionText: 'All definitions for: ${widget.wordDefinitions.givenWord}',
        searchedWord: widget.wordDefinitions.givenWord,
      );
      
      if (success) {
        print('📤 WordDefine Screen sharing successful (with word overview)');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Screen shared successfully!')),
          );
        }
      } else {
        print('📤 WordDefine Screen sharing failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to share screen image')),
          );
        }
      }
    } catch (e) {
      print('📤 WordDefine Error in _shareScreenContent: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share screen image')),
        );
      }
    }
  }

  Future<void> _shareImage(GlobalKey widgetKey, dynamic definition) async {
    print('📤 WordDefine _shareImage called with widgetKey and definition');
    try {
      final shareRepo = Modular.get<ShareRepository>();
      
      // Get definition details from the definition object
      final renderObject = widgetKey.currentContext?.findRenderObject();
      if (renderObject == null) {
        print('📤 WordDefine Error: Could not find render object for widget');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to capture definition for sharing')),
          );
        }
        return;
      }

      // Extract definition details
      final definitionId = definition.dictRefId?.toString() ?? definition.text.hashCode.toString();
      final definitionText = definition.text ?? '';

      print('📤 WordDefine Calling shareDefinitionAsImage with ID: $definitionId');
      final success = await shareRepo.shareDefinitionAsImage(
        widgetKey: widgetKey,
        definitionId: definitionId,
        definitionText: definitionText,
        searchedWord: widget.wordDefinitions.givenWord,
      );
      
      if (success) {
        print('📤 WordDefine Image sharing successful');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Definition shared successfully!')),
          );
        }
      } else {
        print('📤 WordDefine Image sharing failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to share definition image')),
          );
        }
      }
    } catch (e) {
      print('📤 WordDefine Error in _shareImage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share definition image')),
        );
      }
    }
  }

  Future<void> _showCitationModal(int dictRefId) async {
    OverlayEntry? loadingOverlay;
    
    try {
      final citationRepo = Modular.get<CitationRepository>();
      
      // Show loading overlay
      loadingOverlay = OverlayEntry(
        builder: (context) => Material(
          color: Colors.black.withValues(alpha: 0.3),
          child: Center(
            child: CircularProgressIndicator(
              color: widget.themeColors.primary,
            ),
          ),
        ),
      );
      
      Overlay.of(context).insert(loadingOverlay);
      
      // Fetch citation data
      final citation = await citationRepo.getDefinitionCitation(dictRefId);
      
      // Remove loading overlay
      loadingOverlay.remove();
      loadingOverlay = null;
      
      await Future.delayed(const Duration(milliseconds: 50));
      
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
            themeColors: widget.themeColors,
            contentType: 'definition',
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Citation not available')),
        );
      }
    } catch (e) {
      // Remove loading overlay if still present
      loadingOverlay?.remove();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load citation')),
        );
      }
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open URL')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open URL')),
        );
      }
    }
  }
}
