import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dharak_flutter/app/types/prashna/tool_call.dart';
import 'package:dharak_flutter/app/types/dictionary/word_definitions.dart';
import 'package:dharak_flutter/app/types/dictionary/definition.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/expandable_tool_card.dart';
import 'package:dharak_flutter/core/components/word_definition_card.dart';
import 'package:dharak_flutter/core/services/search_orchestrator.dart';
import 'package:dharak_flutter/core/services/citation_share_service.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';

/// Dictionary-specific tool card that shows word definitions
class DictionaryToolCard extends StatefulWidget {
  final ToolCall toolCall;

  const DictionaryToolCard({
    super.key,
    required this.toolCall,
  });

  @override
  State<DictionaryToolCard> createState() => _DictionaryToolCardState();
}

class _DictionaryToolCardState extends State<DictionaryToolCard> {
  bool _hasSearched = false;
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DictWordDefinitionsRM?>(
      stream: SearchOrchestrator.dictionaryResults,
      builder: (context, snapshot) {
        return StreamBuilder<bool>(
          stream: SearchOrchestrator.dictionaryLoading,
          builder: (context, loadingSnapshot) {
            final isLoading = _hasSearched && (loadingSnapshot.data ?? false);

            return StreamBuilder<String?>(
              stream: SearchOrchestrator.dictionaryError,
              builder: (context, errorSnapshot) {
                final error = _hasSearched ? errorSnapshot.data : null;
                final results = snapshot.data;
                final definitions = results?.details.definitions ?? [];
                
                return ExpandableToolCard(
                  toolCall: widget.toolCall,
                  isLoading: isLoading,
                  error: error,
                  resultCount: definitions.isNotEmpty ? definitions.length : null,
                  onExpand: _onExpand,
                  resultsWidget: _buildResults(results),
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
      SearchOrchestrator.searchDictionary(widget.toolCall.query);
    }
  }

  Widget _buildResults(DictWordDefinitionsRM? results) {
    if (results == null) {
      return const SizedBox.shrink();
    }

    final definitions = results.details.definitions;
    
    if (definitions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        _buildResultsHeader(definitions.length),
        
        const SizedBox(height: 12),
        
        // Definitions list
        ...definitions.asMap().entries.map((entry) {
          final index = entry.key;
          final definition = entry.value;
          final repaintKey = GlobalKey();
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RepaintBoundary(
              key: repaintKey,
              child: WordDefinitionCard(
                definition: definition,
                wordDetails: results.details,
                isCompact: false,
                showSource: true,
                showLLMSummary: false,
                onCopy: () => _handleCopy(definition.text),
                onShare: () => _handleShareWithKey(definition, repaintKey),
                onSourceClick: _handleSourceClick,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildResultsHeader(int count) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    
    return Row(
      children: [
        Icon(
          Icons.book,
          size: 16,
          color: Colors.blue,
        ),
        const SizedBox(width: 6),
        Text(
          '$count definition${count == 1 ? '' : 's'} found',
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
              'No definitions found for "${widget.toolCall.query}"',
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
      const SnackBar(content: Text('Definition copied to clipboard')),
    );
  }

  void _handleShareWithKey(WordDefinitionRM definition, GlobalKey repaintKey) {
    // Use the same CitationShareService as normal definition cards
    CitationShareService.instance.showDefinitionShare(
      context,
      repaintKey,
      definition.text,
      definition.dictRefId?.toString(),
      widget.toolCall.query, // Pass the searched word
    );
  }

  void _handleSourceClick(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening source link')),
        );
      }
    }
  }
}
