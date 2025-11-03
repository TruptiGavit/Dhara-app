import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:dharak_flutter/app/data/services/supported_languages_service.dart';
import 'package:dharak_flutter/app/domain/verse/constants.dart';
import 'package:dharak_flutter/app/types/prashna/tool_call.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/controller.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/cubit_states.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/expandable_tool_card.dart';
import 'package:dharak_flutter/core/components/verse_card.dart';
import 'package:dharak_flutter/core/services/search_orchestrator.dart';
import 'package:dharak_flutter/core/services/verse_service.dart';
import 'package:dharak_flutter/core/services/citation_share_service.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/values/dimens.dart';

/// Verse-specific tool card that shows verse results
class VerseToolCard extends StatefulWidget {
  final ToolCall toolCall;

  const VerseToolCard({
    super.key,
    required this.toolCall,
  });

  @override
  State<VerseToolCard> createState() => _VerseToolCardState();
}

class _VerseToolCardState extends State<VerseToolCard> {
  bool _hasSearched = false;
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VerseRM>>(
      stream: SearchOrchestrator.versesResults,
      builder: (context, snapshot) {
        return StreamBuilder<bool>(
          stream: SearchOrchestrator.versesLoading,
          builder: (context, loadingSnapshot) {
            final isLoading = _hasSearched && (loadingSnapshot.data ?? false);

            return StreamBuilder<String?>(
              stream: SearchOrchestrator.versesError,
              builder: (context, errorSnapshot) {
                final error = _hasSearched ? errorSnapshot.data : null;
                final verses = snapshot.data ?? [];
                
                return ExpandableToolCard(
                  toolCall: widget.toolCall,
                  isLoading: isLoading,
                  error: error,
                  resultCount: verses.isNotEmpty ? verses.length : null,
                  onExpand: _onExpand,
                  resultsWidget: _buildResults(verses),
                );
              },
            );
          },
        );
      },
    );
  }

  void _onExpand() {
    if (!_hasSearched) {
      setState(() {
        _hasSearched = true;
      });
      SearchOrchestrator.searchVerses(widget.toolCall.query);
    }
  }

  Widget _buildResults(List<VerseRM> verses) {
    if (verses.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Aksharamukha bar (transcription credit + language selector)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.symmetric(
            horizontal: TdResDimens.dp_8,
            vertical: TdResDimens.dp_6,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).extension<AppThemeColors>()!.primary.withAlpha(0x20),
            borderRadius: BorderRadius.circular(TdResDimens.dp_6),
            border: Border.all(
              color: Theme.of(context).extension<AppThemeColors>()!.primary.withAlpha(0x1A),
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
                      color: Theme.of(context).extension<AppThemeColors>()!.primary,
                    ),
                    SizedBox(width: TdResDimens.dp_4),
                    Flexible(
                      child: Text(
                        "Transcription by Aksharamukha",
                        style: TdResTextStyles.caption.copyWith(
                          color: Theme.of(context).extension<AppThemeColors>()!.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${verses.length} verses',
                      style: TdResTextStyles.caption.copyWith(
                        color: Theme.of(context).extension<AppThemeColors>()!.onSurfaceMedium,
                        fontSize: 10,
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
        ),
        
        // Results header
        _buildResultsHeader(verses.length),
        
        const SizedBox(height: 12),
        
        // Verses list
        ...verses.map((verse) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RepaintBoundary(
            key: _repaintBoundaryKey,
            child: VerseCard(
              verse: verse,
              showNavigation: true,
              showBookmark: true,
              showSource: true,
              showOtherFields: true,
              isCompact: false,
              onPrevious: () => VerseService.instance.navigateVerse(verse.versePk, false),
              onNext: () => VerseService.instance.navigateVerse(verse.versePk, true),
              onBookmark: () => VerseService.instance.toggleBookmark(verse.versePk),
              onCopy: () => _handleCopy(verse.verseText ?? ''),
              onShare: () => _handleShare(verse),
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildResultsHeader(int count) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    
    return Row(
      children: [
        Icon(
          Icons.format_quote,
          size: 16,
          color: Colors.green,
        ),
        const SizedBox(width: 6),
        Text(
          '$count verse${count == 1 ? '' : 's'} found',
          style: TdResTextStyles.p2.copyWith(
            color: themeColors.onSurface.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    
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
              'No verses found for "${widget.toolCall.query}"',
              style: TdResTextStyles.p2.copyWith(
                color: themeColors.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleCopy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verse copied to clipboard')),
    );
  }

  void _handleShare(VerseRM verse) {
    // Use the same CitationShareService as normal verse cards
    CitationShareService.instance.showVerseShare(
      context,
      _repaintBoundaryKey,
      verse.verseText ?? 'No verse text available',
      verse.versePk.toString(),
      themeColors: Theme.of(context).extension<AppThemeColors>(),
    );
  }

  /// Compact language selector for the Aksharamukha bar - exactly like random folder
  Widget _buildCompactLanguageSelector() {
    final dashboardController = Modular.get<DashboardController>();
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;

    return BlocBuilder<DashboardController, DashboardCubitState>(
      bloc: dashboardController,
      buildWhen: (previous, current) {
        final shouldRebuild = current.verseLanguagePref?.output != previous.verseLanguagePref?.output;
        if (kDebugMode) {
          print("🔄 PRASHNA VerseToolCard: buildWhen - shouldRebuild: $shouldRebuild");
          print("🔄 PRASHNA VerseToolCard: buildWhen - previous: ${previous.verseLanguagePref?.output}, current: ${current.verseLanguagePref?.output}");
        }
        return shouldRebuild;
      },
      builder: (context, state) {
        final currentLanguage = state.verseLanguagePref?.output ?? VersesConstants.LANGUAGE_DEFAULT;
        if (kDebugMode) {
          print("🔄 PRASHNA VerseToolCard: BlocBuilder rebuilding - currentLanguage: $currentLanguage");
          print("🔄 PRASHNA VerseToolCard: Language label: ${_getLanguageLabel(currentLanguage)}");
        }
        
        return PopupMenuButton<String>(
          key: ValueKey('prashna_language_dropdown_$currentLanguage'), // Force rebuild on language change
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
          onSelected: (String value) {
            print("🎯 PRASHNA: User selected language '$value' from dropdown");
            dashboardController.onVerseLanguageChange(value);
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
        );
      },
    );
  }

  /// Get language label from constants
  String _getLanguageLabel(String language) {
    return VersesConstants.LANGUAGE_LABELS_MAP[language] ?? language;
  }

  /// Get supported languages from service
  Map<String, String> _getSupportedLanguages() {
    try {
      return SupportedLanguagesService().getSupportedLanguages();
    } catch (e) {
      return VersesConstants.LANGUAGE_LABELS_MAP.map((k, v) => MapEntry(k, v ?? k));
    }
  }
}
