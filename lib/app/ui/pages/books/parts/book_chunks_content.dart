import 'package:dharak_flutter/app/types/books/chunk.dart';
import 'package:dharak_flutter/app/types/books/book_chunk.dart' as new_book_chunk;
import 'package:dharak_flutter/app/ui/pages/books/parts/item_lightweight.dart';
import 'package:dharak_flutter/app/domain/share/repo.dart';
import 'package:dharak_flutter/app/domain/citation/repo.dart';
import 'package:dharak_flutter/app/ui/widgets/share_modal.dart';
import 'package:dharak_flutter/app/ui/widgets/citation_modal.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// 🚀 PERFORMANCE OPTIMIZED: Lightweight book chunks content widget for unified page
/// Contains all book functionality with progressive loading and optimizations
class BookChunksContentWidget extends StatefulWidget {
  final List<BookChunkRM> chunks;
  final AppThemeColors themeColors;
  final AppThemeDisplay? appThemeDisplay;
  
  // Navigation callbacks for unified page integration
  final Future<void> Function(BookChunkRM chunk)? onNavigatePrevious;
  final Future<void> Function(BookChunkRM chunk)? onNavigateNext;
  
  // Bookmark callback for unified page integration
  final Future<void> Function(BookChunkRM chunk, bool isBookmarked)? onBookmarkToggle;

  const BookChunksContentWidget({
    super.key,
    required this.chunks,
    required this.themeColors,
    this.appThemeDisplay,
    this.onNavigatePrevious,
    this.onNavigateNext,
    this.onBookmarkToggle,
  });

  @override
  State<BookChunksContentWidget> createState() => _BookChunksContentWidgetState();
}

class _BookChunksContentWidgetState extends State<BookChunksContentWidget> {
  final ShareRepository _shareRepo = Modular.get<ShareRepository>();
  final CitationRepository _citationRepo = Modular.get<CitationRepository>();

  /// Convert old BookChunkRM to new BookChunkRM format for the widget
  new_book_chunk.BookChunkRM _convertChunk(BookChunkRM oldChunk) {
    return new_book_chunk.BookChunkRM(
      text: oldChunk.text,
      chunkRefId: oldChunk.chunkRefId,
      score: oldChunk.score,
      reference: oldChunk.reference,
      sourceTitle: null,   // Old format doesn't have these fields
      sourceUrl: null,     // Old format doesn't have these fields
      sourceType: null,    // Old format doesn't have these fields
      isStarred: null,     // Old format doesn't have bookmark status
    );
  }

  /// Convert new BookChunkRM back to old format for navigation handlers
  BookChunkRM _convertToOldChunk(new_book_chunk.BookChunkRM newChunk) {
    return BookChunkRM(
      text: newChunk.text ?? '',
      chunkRefId: newChunk.chunkRefId ?? 0,
      score: newChunk.score ?? 0.0,
      reference: newChunk.reference ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chunks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Text(
          "No book chunks found",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: widget.themeColors.onSurfaceDisable,
          ),
        ),
      );
    }

    // 🚀 PERFORMANCE: Use same pattern as WordDefine - simple Column for immediate display
    // Unified tab should be instant like WordDefine, not progressive
    final startTime = DateTime.now().millisecondsSinceEpoch;
    print("🚀 UNIFIED BOOKS: Building ${widget.chunks.length} chunks instantly (like WordDefine) at ${startTime}ms");
    
    final result = SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: widget.chunks.map((chunk) {
          final convertedChunk = _convertChunk(chunk);
          return Container(
            key: ValueKey('chunk_unified_${chunk.chunkRefId}'),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: BookChunkItemLightweightWidget(
              key: ValueKey('chunk_item_${chunk.chunkRefId}'),
              chunk: convertedChunk, // Use converted chunk format
              onSourceClick: (url) => _launchExternalUrl(url),
              // Navigation callbacks passed from unified page (use original chunk format)
              onNavigatePrevious: widget.onNavigatePrevious != null 
                  ? () => widget.onNavigatePrevious!(chunk) 
                  : null,
              onNavigateNext: widget.onNavigateNext != null 
                  ? () => widget.onNavigateNext!(chunk) 
                  : null,
              // Bookmark callback passed from unified page (use original chunk format)
              onBookmarkToggle: widget.onBookmarkToggle != null 
                  ? (convertedChunk, isBookmarked) => widget.onBookmarkToggle!(chunk, isBookmarked) 
                  : null,
            ),
          );
        }).toList(),
      ),
    );
    
    final endTime = DateTime.now().millisecondsSinceEpoch;
    print("🚀 UNIFIED BOOKS: Completed building in ${endTime - startTime}ms");
    
    return result;
  }

  void _copyChunkToClipboard(BookChunkRM chunk) {
    final text = chunk.text;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showShareModal(BookChunkRM chunk, GlobalKey? widgetKey) {
    ShareModal.show(
      context: context,
      themeColors: widget.themeColors,
      textToShare: chunk.text,
      onCopyText: () => _copyChunkToClipboard(chunk),
      onShareImage: () => _handleShareImage(chunk, widgetKey),
      contentType: 'chunk',
    );
  }

  void _showCitationModal(int chunkRefId) async {
    try {
      final citation = await _citationRepo.getChunkCitation(chunkRefId);
      if (citation != null && mounted) {
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
            contentType: 'chunk',
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Citation not available')),
      );
    }
  }

  Future<void> _handleShareImage(BookChunkRM chunk, GlobalKey? widgetKey) async {
    try {
      bool success;

      if (widgetKey != null) {
        success = await _shareRepo.shareChunkAsImage(
          widgetKey: widgetKey,
          chunkId: chunk.chunkRefId.toString(),
          chunkText: chunk.text,
          searchedQuery: '', // Unified tab doesn't have search controller
        );
      } else {
        success = await _shareRepo.shareChunkAsText(
          chunkId: chunk.chunkRefId.toString(),
          chunkText: chunk.text,
          searchTerm: '', // Correct parameter name for text sharing
        );
      }

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shared successfully!'),
            backgroundColor: Colors.blue,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error sharing chunk image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing chunk'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _launchExternalUrl(String urlLink) async {
    // Implementation depends on your URL launcher setup
    // This is a placeholder - adjust based on your existing implementation
    print('🔗 Launching external URL: $urlLink');
  }
}
