import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dharak_flutter/app/types/prashna/tool_call.dart';
import 'package:dharak_flutter/app/types/books/book_chunk.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/widgets/expandable_tool_card.dart';
import 'package:dharak_flutter/app/ui/pages/books/parts/item_lightweight.dart';
import 'package:dharak_flutter/app/ui/widgets/share_modal.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dharak_flutter/core/services/search_orchestrator.dart';
import 'package:dharak_flutter/core/services/books_service.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';

/// Books-specific tool card that shows book chunk results
class BooksToolCard extends StatefulWidget {
  final ToolCall toolCall;

  const BooksToolCard({
    super.key,
    required this.toolCall,
  });

  @override
  State<BooksToolCard> createState() => _BooksToolCardState();
}

class _BooksToolCardState extends State<BooksToolCard> {
  bool _hasSearched = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookChunkRM>>(
      stream: SearchOrchestrator.booksResults,
      builder: (context, snapshot) {
        final bookChunks = snapshot.data ?? [];
        
        // Books service handles loading internally, so we track our own loading state
        final isLoading = _hasSearched && bookChunks.isEmpty && snapshot.connectionState == ConnectionState.waiting;
        
        return ExpandableToolCard(
          toolCall: widget.toolCall,
          isLoading: isLoading,
          error: null, // Books service doesn't expose error stream
          resultCount: bookChunks.isNotEmpty ? bookChunks.length : null,
          onExpand: _onExpand,
          resultsWidget: _buildResults(bookChunks),
        );
      },
    );
  }

  void _onExpand() {
    if (!_hasSearched) {
      setState(() {
        _hasSearched = true;
      });
      SearchOrchestrator.searchBooks(widget.toolCall.query);
    }
  }

  Widget _buildResults(List<BookChunkRM> bookChunks) {
    if (bookChunks.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        _buildResultsHeader(bookChunks.length),
        
        const SizedBox(height: 12),
        
        // Book chunks list
        ...bookChunks.map((chunk) {
          final repaintKey = GlobalKey();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RepaintBoundary(
              key: repaintKey,
              child: BookChunkItemLightweightWidget(
                chunk: chunk,
                onSourceClick: (url) async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                onClickShare: (widgetKey) => _handleShare(chunk, widgetKey),
                onNavigateNext: () => _handleNextChunk(chunk),
                onNavigatePrevious: () => _handlePreviousChunk(chunk),
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
          Icons.library_books,
          size: 16,
          color: Colors.orange,
        ),
        const SizedBox(width: 6),
        Text(
          '$count book chunk${count == 1 ? '' : 's'} found',
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
              'No book content found for "${widget.toolCall.query}"',
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
      const SnackBar(content: Text('Book content copied to clipboard')),
    );
  }

  void _handleShare(BookChunkRM chunk, [GlobalKey? widgetKey]) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ShareModal(
        themeColors: themeColors,
        textToShare: chunk.text ?? '',
        onCopyText: () {
          Navigator.of(context).pop();
          _handleCopy(chunk.text ?? '');
        },
        onShareImage: () {
          Navigator.of(context).pop();
          _handleShareImage(chunk, widgetKey);
        },
        contentType: 'chunk', // Blue theme for chunks
      ),
    );
  }

  void _handleShareImage(BookChunkRM chunk, GlobalKey? widgetKey) {
    // For now, just share as text since we don't have the ShareRepository here
    // This could be enhanced later to use the proper ShareRepository
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image sharing available in main Books section')),
    );
  }

  /// 🔄 Handle previous chunk navigation
  void _handlePreviousChunk(BookChunkRM chunk) {
    if (chunk.chunkRefId == null) return;
    
    
    // Use BooksService to handle navigation
    final booksService = BooksService.instance;
    booksService.navigateChunk(chunk.chunkRefId!, false);
  }

  /// ⏭️ Handle next chunk navigation  
  void _handleNextChunk(BookChunkRM chunk) {
    if (chunk.chunkRefId == null) return;
    
    
    // Use BooksService to handle navigation
    final booksService = BooksService.instance;
    booksService.navigateChunk(chunk.chunkRefId!, true);
  }
}
















