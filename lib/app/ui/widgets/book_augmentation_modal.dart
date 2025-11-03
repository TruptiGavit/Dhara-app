import 'package:flutter/material.dart';
import 'package:dharak_flutter/app/types/books/book_chunk.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:dharak_flutter/app/domain/books/repo.dart';
import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/ui/pages/books/parts/item_lightweight.dart';
import 'package:dharak_flutter/core/services/books_service.dart';

/// 🎨 Beautiful Modal for displaying augmentation list
class BookAugmentationModal extends StatefulWidget {
  final List<String> augmentations;
  final BookChunkRM originalChunk;
  final AppThemeColors themeColors;
  final Function(String)? onSourceClick;
  final Function(BookChunkRM)? onSeeOriginal;

  const BookAugmentationModal({
    super.key,
    required this.augmentations,
    required this.originalChunk,
    required this.themeColors,
    this.onSourceClick,
    this.onSeeOriginal,
  });

  /// 🎪 Beautiful modal presentation method
  static Future<void> show({
    required BuildContext context,
    required List<String> augmentations,
    required BookChunkRM originalChunk,
    required AppThemeColors themeColors,
    Function(String)? onSourceClick,
    Function(BookChunkRM)? onSeeOriginal,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black54, // Darker overlay to show it's a modal
      enableDrag: true,
      isDismissible: true,
      builder: (context) => BookAugmentationModal(
        augmentations: augmentations,
        originalChunk: originalChunk,
        themeColors: themeColors,
        onSourceClick: onSourceClick,
        onSeeOriginal: onSeeOriginal,
      ),
    );
  }

  @override
  State<BookAugmentationModal> createState() => _BookAugmentationModalState();
}

class _BookAugmentationModalState extends State<BookAugmentationModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animation
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.75; // Reduced from 0.85 to 0.75
    
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: widget.themeColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), // Increased radius
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25), // Stronger shadow
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildOriginalChunk(),
            _buildAugmentationsList(),
          ],
        ),
      ),
    );
  }

  /// 🎨 Enhanced modal header with clear modal indicators
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16), // Increased padding
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(0.08), // Slightly stronger background
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF7C3AED).withOpacity(0.15), // Stronger border
            width: 2, // Thicker border
          ),
        ),
      ),
      child: Column(
        children: [
          // Modal drag indicator
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10), // Slightly larger
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.15), // Stronger background
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.library_books,
                  color: Color(0xFF7C3AED),
                  size: 22, // Slightly larger icon
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Sources',
                      style: TextStyle(
                        fontSize: 19, // Larger title
                        fontWeight: FontWeight.w800, // Bolder
                        color: widget.themeColors.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.augmentations.length} augmentations found',
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.themeColors.onSurface?.withOpacity(0.65),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Enhanced close button
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.red,
                    size: 22,
                  ),
                  tooltip: 'Close modal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔶 Original merged chunk display
  Widget _buildOriginalChunk() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7C3AED).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.merge_type,
                size: 16,
                color: const Color(0xFF7C3AED),
              ),
              const SizedBox(width: 6),
              Text(
                'Dhara Summary',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const Spacer(),
              if (widget.originalChunk.score != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(widget.originalChunk.score! * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.originalChunk.text ?? '',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: widget.themeColors.onSurface,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 📚 Beautiful augmentations list
  Widget _buildAugmentationsList() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'Source Breakdown',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: widget.themeColors.onSurface,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: widget.augmentations.length,
              itemBuilder: (context, index) {
                return _buildAugmentationCard(
                  widget.augmentations[index],
                  index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔸 Individual augmentation card - now expandable!
  Widget _buildAugmentationCard(String augmentationText, int index) {
    return _AugmentationExpandableCard(
      augmentationText: augmentationText,
      index: index,
      themeColors: widget.themeColors,
      onSourceClick: widget.onSourceClick,
    );
  }

}

/// 🎨 Beautiful Expandable Card for each augmentation
class _AugmentationExpandableCard extends StatefulWidget {
  final String augmentationText;
  final int index;
  final AppThemeColors themeColors;
  final Function(String url)? onSourceClick;

  const _AugmentationExpandableCard({
    Key? key,
    required this.augmentationText,
    required this.index,
    required this.themeColors,
    this.onSourceClick,
  }) : super(key: key);

  @override
  State<_AugmentationExpandableCard> createState() => _AugmentationExpandableCardState();
}

class _AugmentationExpandableCardState extends State<_AugmentationExpandableCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  
  BookChunkRM? _originalChunk;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.themeColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0891B2).withOpacity(_isExpanded ? 0.4 : 0.2),
          width: _isExpanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0891B2).withOpacity(_isExpanded ? 0.15 : 0.05),
            blurRadius: _isExpanded ? 12 : 8,
            spreadRadius: 0,
            offset: Offset(0, _isExpanded ? 4 : 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clickable header
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: _handleToggleExpansion,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Index badge
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0891B2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${widget.index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0891B2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Title
                    Expanded(
                      child: Text(
                        'Dhara Facts',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0891B2),
                        ),
                      ),
                    ),
                    
                    // Show More/Less button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(_isExpanded ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF1565C0).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: const Color(0xFF1565C0),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isExpanded ? 'Show Less' : 'Show More',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Augmentation content - truncated to 2 lines
          Container(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Text(
              widget.augmentationText,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: widget.themeColors.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Expandable original content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildOriginalContent(),
          ),
        ],
      ),
    );
  }

  /// Handle expanding/collapsing to show original content
  void _handleToggleExpansion() async {
    if (!_isExpanded) {
      // Expanding - load original content
      await _loadOriginalContent();
      if (_originalChunk != null || _error != null) {
        setState(() {
          _isExpanded = true;
        });
        _animationController.forward();
      }
    } else {
      // Collapsing
      _animationController.reverse();
      setState(() {
        _isExpanded = false;
      });
    }
  }

  /// Load the augmented chunk content for this augmentation text
  Future<void> _loadOriginalContent() async {
    if (_isLoading || _originalChunk != null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the augmented chunk for this specific augmentation text
      final booksRepo = Modular.get<BooksRepository>();
      final augmentedResult = await booksRepo.getAugmentedChunk(text: widget.augmentationText);

      if (augmentedResult.status == DomainResultStatus.SUCCESS && augmentedResult.data != null) {
        // Use the augmented chunk directly (not the original)
        final augmentedChunk = augmentedResult.data!.data;
        
        setState(() {
          _originalChunk = augmentedChunk; // Show the augmented chunk, not original
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = augmentedResult.message ?? 'Failed to load augmented chunk';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading augmented chunk';
        _isLoading = false;
      });
    }
  }

  /// 🔄 Handle navigation within expandable card context
  Future<void> _handleExpandableNavigation(BookChunkRM currentChunk, bool isNext) async {
    if (currentChunk.chunkRefId == null) return;
    
    try {
      print('🔀 Expandable Navigation: ${isNext ? 'next' : 'previous'} from ${currentChunk.chunkRefId}');
      
      // Use BooksService to get the new chunk
      final newChunk = await BooksService.instance.navigateChunk(currentChunk.chunkRefId!, isNext);
      
      if (newChunk != null) {
        // Update the original chunk state with the new chunk
        setState(() {
          _originalChunk = newChunk;
        });
        print('🔀 Expandable Navigation successful: ${currentChunk.chunkRefId} -> ${newChunk.chunkRefId}');
      } else {
        print('🔀 Expandable Navigation failed: No new chunk returned');
        // Show error via snackbar (if context allows)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No ${isNext ? 'next' : 'previous'} chunk available'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('🔀 Expandable Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation failed: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Build the original content section
  Widget _buildOriginalContent() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF1565C0)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading augmented source...',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.themeColors.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_originalChunk == null) {
      return const SizedBox.shrink();
    }

    // Show the augmented chunk using BookChunkItemLightweightWidget!
    // This will be an augmented chunk with proper styling and "See Original" functionality
    final augmentedChunk = _originalChunk!; // This is actually the augmented chunk now

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: BookChunkItemLightweightWidget(
        chunk: augmentedChunk, // Use the augmented chunk directly
        themeColors: widget.themeColors,
        onSourceClick: widget.onSourceClick,
        // Enable navigation within expandable card modal context
        onNavigatePrevious: () => _handleExpandableNavigation(augmentedChunk, false),
        onNavigateNext: () => _handleExpandableNavigation(augmentedChunk, true),
      ),
    );
  }
}
