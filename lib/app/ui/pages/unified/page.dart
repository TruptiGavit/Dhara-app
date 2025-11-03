import 'package:flutter/foundation.dart';
import 'package:dharak_flutter/app/data/services/supported_languages_service.dart';
import 'package:dharak_flutter/app/domain/citation/repo.dart';
import 'package:dharak_flutter/app/domain/share/repo.dart';
import 'package:dharak_flutter/app/domain/verse/repo.dart';
import 'package:dharak_flutter/app/domain/books/repo.dart';
import 'package:dharak_flutter/app/domain/verse/constants.dart';
import 'package:dharak_flutter/app/types/verse/language_pref.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/controller.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/cubit_states.dart';
import 'package:dharak_flutter/app/ui/pages/unified/controller.dart';
import 'package:dharak_flutter/app/ui/pages/unified/cubit_states.dart';
import 'package:dharak_flutter/app/ui/widgets/citation_modal.dart';
import 'package:dharak_flutter/app/ui/widgets/share_modal.dart';
import 'package:dharak_flutter/app/types/unified/unified_search_response.dart';
import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/types/verse/verses.dart';
import 'package:dharak_flutter/app/types/verse/verse_head.dart';
import 'package:dharak_flutter/app/types/verse/verse_foot.dart';
import 'package:dharak_flutter/app/types/books/chunk.dart';

// Import for WordDefine functionality - PURE UI COMPONENTS ONLY
import 'package:dharak_flutter/app/ui/pages/words/parts/word_definitions_content.dart';

// 🚀 PERFORMANCE: Import lightweight content widgets for unified page
import 'package:dharak_flutter/app/ui/pages/verses/parts/verses_content.dart';
import 'package:dharak_flutter/app/ui/pages/books/parts/book_chunks_content.dart';
import 'package:dharak_flutter/app/domain/verse/repo.dart';
import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/controller.dart';

// Import for QuickVerse functionality - COMPLETE PAGE (kept for individual pages)
import 'package:dharak_flutter/app/ui/pages/verses/controller.dart';
import 'package:dharak_flutter/app/ui/pages/verses/page.dart';
import 'package:dharak_flutter/app/ui/pages/verses/args.dart';

// Import for Books functionality - COMPLETE PAGE (kept for individual pages)
import 'package:dharak_flutter/app/ui/pages/books/controller.dart';
import 'package:dharak_flutter/app/ui/pages/books/page.dart';
import 'package:dharak_flutter/app/ui/pages/books/args.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';


class UnifiedSearchPage extends StatefulWidget {
  final String? query;
  final bool hideSearchBar;
  final bool hideWelcomeMessage;

  const UnifiedSearchPage({
    Key? key,
    this.query,
    this.hideSearchBar = false,
    this.hideWelcomeMessage = false,
  }) : super(key: key);

  @override
  State<UnifiedSearchPage> createState() => _UnifiedSearchPageState();
}

class _UnifiedSearchPageState extends State<UnifiedSearchPage> {
  late AppThemeColors themeColors;
  late UnifiedSearchController controller;
  
  // Track expanded state of collapsible cards
  final Map<String, bool> _expandedCards = {};
  String? _currentlyExpandedCard; // Track which card is currently expanded
  UnifiedSearchResult? currentResults; // Store current search results for share/citation
  
  // Track embedded controllers for global language change coordination
  final List<VersesController> _embeddedVersesControllers = [];
  final List<BooksController> _embeddedBooksControllers = [];
  
  // Listen to global language changes
  StreamSubscription<VersesLanguagePrefRM?>? _languageChangeSubscription;

  @override
  void initState() {
    super.initState();
    controller = Modular.get<UnifiedSearchController>();
    
    // Expand verses card by default to show language selector
    _expandedCards['all_verses'] = true;
    _currentlyExpandedCard = 'all_verses';
    
    // Setup global language change listener for all embedded controllers
    _setupGlobalLanguageChangeListener();
    
    // Perform initial streaming search if query is provided
    if (widget.query != null && widget.query!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.searchStreaming(widget.query!);
      });
    }
  }
  
  @override
  void dispose() {
    _languageChangeSubscription?.cancel();
    // Clear controller references to prevent memory leaks
    _embeddedVersesControllers.clear();
    _embeddedBooksControllers.clear();
    super.dispose();
  }
  
  /// Setup listener for global language changes to refresh all visible cards
  void _setupGlobalLanguageChangeListener() {
    final versesRepo = Modular.get<VerseRepository>();
    _languageChangeSubscription = versesRepo.mLanguagePrefObservable.listen((languagePref) {
      if (languagePref != null && mounted) {
        
        // Silent refresh of unified verse results
        _performSilentRefreshForLanguageChange();
        
        // Manual refresh triggered by language selection
        _manualRefreshAllCards();
      }
    });
  }
  
  /// Perform silent refresh for language change using UnifiedService
  void _performSilentRefreshForLanguageChange() {
    try {
      final unifiedService = UnifiedService.instance;
      unifiedService.refreshVersesForLanguageChange();
    } catch (e) {
    }
  }

  /// 🚀 PERFORMANCE FIX: Optimized refresh - target only verses controllers instead of full rebuild
  void _manualRefreshAllCards() {
    
    // 🚀 OPTIMIZATION: Only refresh verses controllers, no setState() needed
    if (_embeddedVersesControllers.isNotEmpty) {
      for (int i = 0; i < _embeddedVersesControllers.length; i++) {
        final versesController = _embeddedVersesControllers[i];
        _refreshControllerForLanguageChange(versesController);
      }
    }
    
    // Only use setState as last resort if controllers approach fails
    // This prevents expensive full page rebuilds in most cases
  }
  
  /// 🚀 PERFORMANCE FIX: Optimized controller refresh with safety checks
  void _refreshControllerForLanguageChange(VersesController versesController) {
    try {
      // Safety check - don't refresh closed controllers
      if (versesController.isClosed) {
        return;
      }
      
      final state = versesController.state;
      
      if (state.verseList.isNotEmpty) {
        String queryToUse = state.searchQuery?.isNotEmpty == true 
            ? state.searchQuery! 
            : widget.query ?? "agnimeele";
            
        // 🚀 Optimized: Only refresh if controller has actual content and query
        if (queryToUse.length > 3) {
          versesController.onSearchDirectQuery(queryToUse);
          if (kDebugMode) print("✅ UNIFIED: Refresh triggered for controller");
        }
      }
    } catch (e) {
      if (kDebugMode) print("❌ UNIFIED: Error refreshing controller: $e");
    }
  }

  /// Handle previous verse navigation in unified page
  Future<void> _handlePreviousVerse(String versePk) async {
    try {
      if (kDebugMode) print("⬅️ UNIFIED: Previous verse requested for PK: $versePk");
      
      // Find the verse index in current results
      final currentVerses = currentResults?.verses?.verses.verses ?? [];
      final verseIndex = currentVerses.indexWhere((v) => v.versePk.toString() == versePk);
      if (verseIndex == -1) {
        if (kDebugMode) print("❌ UNIFIED: Verse not found in current list");
        return;
      }
      
      // Create a temporary controller to handle the API call
      final versesRepo = Modular.get<VerseRepository>();
      final result = await versesRepo.getPreviousVerse(versePk: versePk);
      
      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        final responseData = result.data!;
        if (responseData.getVerseData() != null) {
          final newVerse = responseData.getVerseData()!;
          
          // Update the current results and trigger UI refresh
          _updateVerseInCurrentResults(verseIndex, newVerse);
          
          if (kDebugMode) print("✅ UNIFIED: Previous verse loaded successfully");
        } else {
          if (kDebugMode) print("⚠️ UNIFIED: No previous verse available");
          _showSnackBar("No previous verse available");
        }
      } else {
        if (kDebugMode) print("❌ UNIFIED: Failed to load previous verse");
        _showSnackBar("Failed to load previous verse");
      }
    } catch (e) {
      if (kDebugMode) print("❌ UNIFIED: Error in previous verse: $e");
      _showSnackBar("Error loading previous verse");
    }
  }

  /// Handle next verse navigation in unified page
  Future<void> _handleNextVerse(String versePk) async {
    try {
      if (kDebugMode) print("➡️ UNIFIED: Next verse requested for PK: $versePk");
      
      // Find the verse index in current results
      final currentVerses = currentResults?.verses?.verses.verses ?? [];
      final verseIndex = currentVerses.indexWhere((v) => v.versePk.toString() == versePk);
      if (verseIndex == -1) {
        if (kDebugMode) print("❌ UNIFIED: Verse not found in current list");
        return;
      }
      
      // Create a temporary controller to handle the API call
      final versesRepo = Modular.get<VerseRepository>();
      final result = await versesRepo.getNextVerse(versePk: versePk);
      
      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        final responseData = result.data!;
        if (responseData.getVerseData() != null) {
          final newVerse = responseData.getVerseData()!;
          
          // Update the current results and trigger UI refresh
          _updateVerseInCurrentResults(verseIndex, newVerse);
          
          if (kDebugMode) print("✅ UNIFIED: Next verse loaded successfully");
        } else {
          if (kDebugMode) print("⚠️ UNIFIED: No next verse available");
          _showSnackBar("No next verse available");
        }
      } else {
        if (kDebugMode) print("❌ UNIFIED: Failed to load next verse");
        _showSnackBar("Failed to load next verse");
      }
    } catch (e) {
      if (kDebugMode) print("❌ UNIFIED: Error in next verse: $e");
      _showSnackBar("Error loading next verse");
    }
  }

  /// Handle previous chunk navigation in unified page - SIMPLIFIED VERSION
  Future<void> _handlePreviousChunk(BookChunkRM chunk) async {
    try {
      if (kDebugMode) print("⬅️ UNIFIED: Previous chunk requested for ID: ${chunk.chunkRefId}");
      
      // Find the chunk index in current results
      final currentChunks = currentResults?.chunks?.chunks?.data ?? [];
      final chunkIndex = currentChunks.indexWhere((c) => c.chunkRefId == chunk.chunkRefId);
      if (chunkIndex == -1) {
        if (kDebugMode) print("❌ UNIFIED: Chunk not found in current list");
        return;
      }
      
      // Get books repository and make API call
      final booksRepo = Modular.get<BooksRepository>();
      final result = await booksRepo.getPreviousChunk(chunkRefId: chunk.chunkRefId.toString());
      
      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        final newChunk = result.data!.getPrevChunk();
        if (newChunk != null) {
          // SIMPLIFIED: Direct local state update with type conversion
          setState(() {
            if (currentResults?.chunks?.chunks?.data != null && chunkIndex < currentResults!.chunks!.chunks!.data.length) {
              // Convert new chunk from book_chunk.BookChunkRM to chunk.BookChunkRM
              final convertedChunk = BookChunkRM(
                text: newChunk.text ?? chunk.text,
                chunkRefId: newChunk.chunkRefId ?? chunk.chunkRefId,
                score: newChunk.score ?? chunk.score,
                reference: newChunk.reference ?? chunk.reference,
              );
              currentResults!.chunks!.chunks!.data[chunkIndex] = convertedChunk;
            }
          });
          
          if (kDebugMode) print("✅ UNIFIED: Previous chunk loaded successfully - ID: ${newChunk.chunkRefId}");
        } else {
          if (kDebugMode) print("⚠️ UNIFIED: No previous chunk available");
          _showSnackBar("No previous chunk available");
        }
      } else {
        if (kDebugMode) print("❌ UNIFIED: Failed to load previous chunk: ${result.message}");
        _showSnackBar("Failed to load previous chunk");
      }
    } catch (e) {
      if (kDebugMode) print("❌ UNIFIED: Error in previous chunk: $e");
      _showSnackBar("Error loading previous chunk");
    }
  }

  /// Handle next chunk navigation in unified page - SIMPLIFIED VERSION
  Future<void> _handleNextChunk(BookChunkRM chunk) async {
    try {
      if (kDebugMode) print("➡️ UNIFIED: Next chunk requested for ID: ${chunk.chunkRefId}");
      
      // Find the chunk index in current results
      final currentChunks = currentResults?.chunks?.chunks?.data ?? [];
      final chunkIndex = currentChunks.indexWhere((c) => c.chunkRefId == chunk.chunkRefId);
      if (chunkIndex == -1) {
        if (kDebugMode) print("❌ UNIFIED: Chunk not found in current list");
        return;
      }
      
      // Get books repository and make API call
      final booksRepo = Modular.get<BooksRepository>();
      final result = await booksRepo.getNextChunk(chunkRefId: chunk.chunkRefId.toString());
      
      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        final newChunk = result.data!.getNextChunk();
        if (newChunk != null) {
          // SIMPLIFIED: Direct local state update with type conversion
          setState(() {
            if (currentResults?.chunks?.chunks?.data != null && chunkIndex < currentResults!.chunks!.chunks!.data.length) {
              // Convert new chunk from book_chunk.BookChunkRM to chunk.BookChunkRM
              final convertedChunk = BookChunkRM(
                text: newChunk.text ?? chunk.text,
                chunkRefId: newChunk.chunkRefId ?? chunk.chunkRefId,
                score: newChunk.score ?? chunk.score,
                reference: newChunk.reference ?? chunk.reference,
              );
              currentResults!.chunks!.chunks!.data[chunkIndex] = convertedChunk;
            }
          });
          
          if (kDebugMode) print("✅ UNIFIED: Next chunk loaded successfully - ID: ${newChunk.chunkRefId}");
        } else {
          if (kDebugMode) print("⚠️ UNIFIED: No next chunk available");
          _showSnackBar("No next chunk available");
        }
      } else {
        if (kDebugMode) print("❌ UNIFIED: Failed to load next chunk: ${result.message}");
        _showSnackBar("Failed to load next chunk");
      }
    } catch (e) {
      if (kDebugMode) print("❌ UNIFIED: Error in next chunk: $e");
      _showSnackBar("Error loading next chunk");
    }
  }

  /// Update a chunk in the current results and refresh the UI (similar to verse update)
  void _updateChunkInCurrentResults(int chunkIndex, BookChunkRM newChunk) {
    if (kDebugMode) print("🔄 UNIFIED: _updateChunkInCurrentResults called for index $chunkIndex, new chunk ID: ${newChunk.chunkRefId}");
    
    if (currentResults?.chunks?.chunks == null) {
      return;
    }
    
    // Update the chunk in currentResults
    if (currentResults!.chunks!.chunks!.data.length > chunkIndex) {
      // Create updated chunks list
      final originalChunks = currentResults!.chunks!.chunks!.data;
      final updatedChunks = List<BookChunkRM>.from(originalChunks);
      
      if (kDebugMode) {
        print("🔄 UNIFIED: BEFORE update - chunk at index $chunkIndex: ID=${originalChunks[chunkIndex].chunkRefId}");
        print("🔄 UNIFIED: NEW chunk to insert: ID=${newChunk.chunkRefId}");
      }
      
      updatedChunks[chunkIndex] = newChunk;
      
      if (kDebugMode) {
        print("🔄 UNIFIED: AFTER update - chunk at index $chunkIndex: ID=${updatedChunks[chunkIndex].chunkRefId}");
      }
      
      // Create updated chunks response
      final updatedChunksResult = BookChunksResponseRM(
        success: currentResults!.chunks!.chunks!.success,
        data: updatedChunks,
      );
      
      final updatedChunksResponse = UnifiedChunkResponse(chunks: updatedChunksResult);
      
      // Update current results
      final oldResults = currentResults!;
      currentResults = currentResults!.copyWith(chunks: updatedChunksResponse);
      
      if (kDebugMode) {
        print("🔄 UNIFIED: OLD currentResults first chunk: ${oldResults.chunks?.chunks?.data.first.chunkRefId}");
        print("🔄 UNIFIED: NEW currentResults first chunk: ${currentResults!.chunks!.chunks!.data.first.chunkRefId}");
        print("🔄 UNIFIED: Object reference changed: ${oldResults.hashCode} → ${currentResults.hashCode}");
      }
      
      // Trigger UI rebuild
      setState(() {
        if (kDebugMode) print("🔄 UNIFIED: setState called - UI should rebuild now");
      });
      
      if (kDebugMode) {
        print("✅ UNIFIED: Chunk updated in results and UI refreshed");
        print("✅ UNIFIED: Updated chunk list length: ${currentResults!.chunks!.chunks!.data.length}");
        print("✅ UNIFIED: Updated chunk at index $chunkIndex has ID: ${currentResults!.chunks!.chunks!.data[chunkIndex].chunkRefId}");
      }
    }
  }

  /// Update a verse in the current results and refresh the UI
  void _updateVerseInCurrentResults(int verseIndex, VerseRM newVerse) {
    if (kDebugMode) print("🔄 UNIFIED: _updateVerseInCurrentResults called for index $verseIndex, new verse PK: ${newVerse.versePk}");
    
    if (currentResults == null) {
      if (kDebugMode) print("❌ UNIFIED: currentResults is null");
      return;
    }
    
    // Update the verse in currentResults
    if (currentResults!.verses != null && currentResults!.verses!.verses.verses.length > verseIndex) {
      // Create updated verses list
      final originalVerses = currentResults!.verses!.verses.verses;
      final updatedVerses = List<VerseRM>.from(originalVerses);
      
      if (kDebugMode) {
        print("🔄 UNIFIED: BEFORE update - verse at index $verseIndex: PK=${originalVerses[verseIndex].versePk}");
        print("🔄 UNIFIED: NEW verse to insert: PK=${newVerse.versePk}");
      }
      
      updatedVerses[verseIndex] = newVerse;
      
      if (kDebugMode) {
        print("🔄 UNIFIED: AFTER update - verse at index $verseIndex: PK=${updatedVerses[verseIndex].versePk}");
        print("🔄 UNIFIED: Updated list first verse: PK=${updatedVerses.first.versePk}");
      }
      
      // Create updated verses response
      final updatedVersesResult = VersesResultRM(
        head: currentResults!.verses!.verses.head,
        verses: updatedVerses,
        foot: currentResults!.verses!.verses.foot,
      );
      
      final updatedVersesResponse = UnifiedVerseResponse(verses: updatedVersesResult);
      
      // Update current results
      final oldResults = currentResults!;
      currentResults = currentResults!.copyWith(verses: updatedVersesResponse);
      
      if (kDebugMode) {
        print("🔄 UNIFIED: OLD currentResults first verse: ${oldResults.verses?.verses.verses.first.versePk}");
        print("🔄 UNIFIED: NEW currentResults first verse: ${currentResults!.verses!.verses.verses.first.versePk}");
        print("🔄 UNIFIED: Object reference changed: ${oldResults.hashCode} → ${currentResults.hashCode}");
      }
      
      // Trigger UI rebuild
      setState(() {
        if (kDebugMode) print("🔄 UNIFIED: setState called - UI should rebuild now");
      });
      
      if (kDebugMode) {
        print("✅ UNIFIED: Verse updated in results and UI refreshed");
        print("✅ UNIFIED: Updated verse list length: ${currentResults!.verses!.verses.verses.length}");
        print("✅ UNIFIED: Updated verse at index $verseIndex has PK: ${currentResults!.verses!.verses.verses[verseIndex].versePk}");
      }
    }
  }

  /// Handle book chunk bookmark toggle in unified page
  Future<void> _handleBookChunkBookmarkToggle(BookChunkRM chunk, bool isBookmarked) async {
    try {
      if (kDebugMode) print("📖 UNIFIED: Book chunk bookmark toggle for chunk ${chunk.chunkRefId}: ${isBookmarked ? 'ADD' : 'REMOVE'}");
      
      // Find the chunk in current results and update its bookmark status
      final chunkIndex = currentResults?.chunks?.chunks?.data.indexWhere((c) => c.chunkRefId == chunk.chunkRefId) ?? -1;
      if (chunkIndex != -1) {
        setState(() {
          if (currentResults?.chunks?.chunks?.data != null && chunkIndex < currentResults!.chunks!.chunks!.data.length) {
            // For now, just update the existing chunk (old format doesn't have isStarred field)
            // The BooksService will handle the actual bookmark state
            // Future: We may need to extend the old BookChunkRM or convert to new format
            // currentResults!.chunks!.chunks!.data[chunkIndex] = chunk; // Keep same chunk
          }
        });
        
        if (kDebugMode) print("✅ UNIFIED: Book chunk bookmark updated successfully");
        _showSnackBar(isBookmarked ? "Added to bookmarks" : "Removed from bookmarks");
      }
    } catch (e) {
      if (kDebugMode) print("❌ UNIFIED: Error in book chunk bookmark toggle: $e");
      _showSnackBar("Error updating bookmark");
    }
  }

  /// Handle bookmark toggle in unified page
  Future<void> _handleBookmarkToggle(VerseRM verse, bool isBookmarked) async {
    try {
      if (kDebugMode) print("📖 UNIFIED: Bookmark toggle for verse ${verse.versePk}: ${isBookmarked ? 'ADD' : 'REMOVE'}");
      
      // Get verses repository
      final versesRepo = Modular.get<VerseRepository>();
      
      // Toggle bookmark via API
      final result = await versesRepo.toggleBookmark(
        verse.versePk, 
        isToRemove: verse.isStarred && !isBookmarked,
      );
      
      if (result.status == DomainResultStatus.SUCCESS && result.data?.success == true) {
        // Update the verse in current results
        final verseIndex = currentResults?.verses?.verses.verses.indexWhere((v) => v.versePk == verse.versePk) ?? -1;
        if (verseIndex != -1) {
          final updatedVerse = verse.copyWith(isStarred: isBookmarked);
          _updateVerseInCurrentResults(verseIndex, updatedVerse);
          
          if (kDebugMode) print("✅ UNIFIED: Bookmark updated successfully");
          _showSnackBar(isBookmarked ? "Added to bookmarks" : "Removed from bookmarks");
        }
      } else {
        if (kDebugMode) print("❌ UNIFIED: Bookmark toggle failed");
        _showSnackBar("Bookmark action failed");
      }
    } catch (e) {
      if (kDebugMode) print("❌ UNIFIED: Error in bookmark toggle: $e");
      _showSnackBar("Error updating bookmark");
    }
  }

  /// Show snackbar message
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Get current language from dashboard controller
  String _getCurrentLanguage() {
    try {
      final dashboardController = Modular.get<DashboardController>();
      final languagePref = dashboardController.state.verseLanguagePref;
      return languagePref?.output ?? 'Devanagari';
    } catch (e) {
      if (kDebugMode) print("⚠️ UNIFIED: Could not get language preference: $e");
      return 'Devanagari'; // fallback
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    themeColors = Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: const Color(0xFF6CE18D), isDark: false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnifiedSearchController, UnifiedSearchCubitState>(
      bloc: controller,
      builder: (context, state) {
        return Expanded(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: _buildContent(state),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(TdResDimens.dp_16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ),
          TdResGaps.h_12,
          Text(
            'Searching across all modules...',
            style: TdResTextStyles.h6.copyWith(
              color: themeColors.onSurface?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(UnifiedSearchCubitState state) {
    if (state is UnifiedSearchInitial) {
      return _buildWelcomeState();
    } else if (state is UnifiedSearchSuccess) {
      return _buildResultsView(state.result);
    } else if (state is UnifiedSearchStreaming) {
      // Real-time streaming results - show as they arrive!
      return _buildStreamingResultsView(state.partialResult, state.query);
    } else if (state is UnifiedSearchEmpty) {
      return _buildEmptyState(state.query);
    } else if (state is UnifiedSearchError) {
      return _buildErrorState(state.query, state.error);
    } else if (state is UnifiedSearchLoading) {
      // Skip loading state, show welcome instead for faster UI
      return _buildWelcomeState();
    }
    
    return _buildWelcomeState();
  }

  Widget _buildWelcomeState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TdResDimens.dp_48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(TdResDimens.dp_24),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.electric_bolt,
                size: 64,
                color: Colors.purple.withOpacity(0.8),
              ),
            ),
            TdResGaps.v_24,
            Text(
              'Welcome to Shodh',
              style: TdResTextStyles.h2.copyWith(
                color: themeColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            TdResGaps.v_12,
            Text(
              'Ask a question or enter a phrase to search the world of Indic Knowledge',
              textAlign: TextAlign.center,
              style: TdResTextStyles.h6.copyWith(
                color: themeColors.onSurface?.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TdResDimens.dp_48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
            TdResGaps.v_16,
            Text(
              'Searching for "$query"...',
              style: TdResTextStyles.h5.copyWith(
                color: themeColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            TdResGaps.v_8,
            Text(
              'Processing across all modules',
              style: TdResTextStyles.h6.copyWith(
                color: themeColors.onSurface?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TdResDimens.dp_48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: themeColors.onSurface?.withOpacity(0.5),
            ),
            TdResGaps.v_16,
            Text(
              'No results found',
              style: TdResTextStyles.h4.copyWith(
                color: themeColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            TdResGaps.v_8,
            Text(
              'No results found for "$query" across any module.',
              textAlign: TextAlign.center,
              style: TdResTextStyles.h6.copyWith(
                color: themeColors.onSurface?.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String query, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TdResDimens.dp_48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.7),
            ),
            TdResGaps.v_16,
            Text(
              'Search Error',
              style: TdResTextStyles.h4.copyWith(
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            TdResGaps.v_8,
            Text(
              'Failed to search for "$query"',
              textAlign: TextAlign.center,
              style: TdResTextStyles.h6.copyWith(
                color: themeColors.onSurface?.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            TdResGaps.v_8,
            Text(
              error,
              textAlign: TextAlign.center,
              style: TdResTextStyles.buttonSmall.copyWith(
                color: Colors.red.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingResultsView(UnifiedSearchResult partialResult, String query) {
    currentResults = partialResult; // Store for share/citation
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TdResDimens.dp_16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results appear instantly - no loading indicator needed
          
          // Show results as they arrive - same format as final results
          if (partialResult.hasDefinitions) ...[
            ...partialResult.definitions.where((def) => def.foundMatch).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final definition = entry.value;
              final wordName = definition.definitions?.details.word ?? 'Unknown Word';
              final defCount = definition.definitions?.details.definitions?.length ?? 0;
              
              print("📡 Streaming card $index for word: '$wordName' with $defCount definitions");
              
              return Column(
                children: [
                  _buildCollapsibleCard(
                    wordName,
                    '[dict]',
                    Icons.local_library_outlined,
                    Colors.red,
                    defCount,
                    'definition_$wordName',
                    () => _buildSingleDefinitionSection(definition),
                    aiSummary: definition.definitions?.details.llmDef,
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ],
          
          if (partialResult.verses != null) ...[
            if (kDebugMode) print("🟢 STREAMING: Building collapsible verse card with ${partialResult.verses!.verses.verses.length} verses"),
            _buildCollapsibleCard(
              partialResult.verses!.verses.head?.inputString ?? widget.query ?? 'Search',
              '[verse]',
              Icons.auto_stories,
              Colors.green,
              partialResult.verses!.verses.verses.length,
              'verses',
              () => _buildAllVersesSection(),
            ),
            const SizedBox(height: 8),
          ],
          
          if (partialResult.chunks != null) ...[
            _buildCollapsibleCard(
              widget.query ?? 'Search', 
              '[chunk]',
              Icons.menu_book,
              Colors.orange,
              partialResult.chunks!.chunks?.data.length ?? 0,
              'chunks',
              () => _buildChunksSection(partialResult.chunks!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsView(UnifiedSearchResult result) {
    // Store current results for share/citation functionality
    currentResults = result;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TdResDimens.dp_16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with refresh button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Results',
                style: TdResTextStyles.h4.copyWith(
                  color: themeColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Manual refresh button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: themeColors.primary),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: themeColors.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    print("🔄 MANUAL: Refresh button pressed - IMMEDIATE REFRESH");
                    _manualRefreshAllCards();
                  },
                  tooltip: 'Refresh all cards with current language',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
            // Individual definition cards - one for each word found
            if (result.hasDefinitions) ...[
              ...result.definitions.where((def) => def.foundMatch).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final definition = entry.value;
                final wordName = definition.definitions?.details.word ?? 'Unknown Word';
                final defCount = definition.definitions?.details.definitions?.length ?? 0;
                
                if (kDebugMode) {
                  print("🔍 Creating card $index for word: '$wordName' with $defCount definitions");
                  print("🔍 Definition object hashCode: ${definition.hashCode}");
                  print("🔍 Sample definition: ${definition.definitions?.details.definitions?.first.text}");
                  print("🔍 All definitions for $wordName: ${definition.definitions?.details.definitions?.map((d) => '${d.text.length > 50 ? d.text.substring(0, 50) : d.text}...').join(' | ')}");
                }
                
                return Column(
                  children: [
                    _buildCollapsibleCard(
                      wordName,
                      '[dict]',
                      Icons.local_library_outlined,
                      const Color(0xFFF9140C),
                      defCount,
                      'definition_${wordName}_$index',
                      () => _buildSingleDefinitionSection(definition),
                      aiSummary: definition.definitions?.details.llmDef,
                    ),
                    TdResGaps.v_16,
                  ],
                );
              }).toList(),
            ],
            
            // Individual verse cards - one for each verse found  
            // Single verses card containing all verses - like Prashna tools tab
            if (result.hasVerses) ...[
              if (kDebugMode) print("🔵 FINAL: Building collapsible verse card with ${result.verses!.verses.verses.length} verses"),
              _buildCollapsibleCard(
                result.verses!.verses.head?.inputString ?? widget.query ?? 'Search',
                '[verse]',
                Icons.keyboard_command_key,
                const Color(0xFF189565),
                result.verses!.verses.verses.length,
                'all_verses',
                () => _buildAllVersesSection(),
              ),
              TdResGaps.v_16,
            ],
            
            // Single books card for the heritage query
            if (result.hasChunks) ...[
              _buildCollapsibleCard(
                widget.query ?? 'Search',
                '[chunk]',
                Icons.menu_book,
                Colors.blue,
                result.chunks!.chunks.data.length,
                'chunks',
                () => _buildChunksSection(result.chunks!),
              ),
              TdResGaps.v_16,
            ],
          ],
        ),
    );
  }

  Widget _buildCollapsibleCard(
    String title,
    String tag,
    IconData icon,
    Color color,
    int count,
    String cardId,
    Widget Function() contentBuilder, {
    String? aiSummary,
  }) {
    final isExpanded = _expandedCards[cardId] ?? false;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          // If this card is being expanded, close any other expanded card first
          if (!isExpanded && _currentlyExpandedCard != null) {
            _expandedCards[_currentlyExpandedCard!] = false;
          }
          
          // Toggle current card
          _expandedCards[cardId] = !isExpanded;
          
          // Update currently expanded card tracker
          if (!isExpanded) {
            _currentlyExpandedCard = cardId;
          } else {
            _currentlyExpandedCard = null;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isExpanded 
                ? color.withOpacity(0.08) 
                : Colors.black.withOpacity(0.04),
              blurRadius: isExpanded ? 8 : 4,
              offset: Offset(0, isExpanded ? 3 : 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Clean Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Title and Tag
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Count Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Expand Icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            // AI Summary (collapsed state only)
            if (aiSummary != null && aiSummary.isNotEmpty && !isExpanded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppThemeColors.seedColor(
                      seedColor: const Color(0xFFF9140C), // WordDefine red
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ).primaryLight.withAlpha(0x40),
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
                          color: AppThemeColors.seedColor(
                            seedColor: const Color(0xFFF9140C), // WordDefine red
                            isDark: Theme.of(context).brightness == Brightness.dark,
                          ).primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        aiSummary,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppThemeColors.seedColor(
                            seedColor: const Color(0xFFF9140C), // WordDefine red
                            isDark: Theme.of(context).brightness == Brightness.dark,
                          ).onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Expanded Content
            if (isExpanded) ...[
              Container(
                width: double.infinity,
                constraints: BoxConstraints(maxHeight: 500),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: contentBuilder(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSingleDefinitionSection(UnifiedDefinitionResponse definition) {
    if (!definition.foundMatch || definition.definitions == null) {
      return const SizedBox.shrink();
    }
    
    final word = definition.definitions!.details.word ?? 'unknown';
    if (kDebugMode) {
      print("🔍 Building EXACT WordDefine content for word: '$word'");
      print("🔍 Just showing the original WordDefine page as-is");
      print("🔍 Data hashCode: ${definition.definitions.hashCode}");
    }
    
    // **SIMPLE: Just show the EXACT original WordDefine content**
    // No custom containers, no custom layouts, no modifications
    // Just the pure original WordDefinitionsContent as it appears in Image 1
    return Container(
      constraints: BoxConstraints(maxHeight: 500),
      child: WordDefinitionsContent(
        key: ValueKey('unified_def_${word}_${definition.definitions.hashCode}'),
        wordDefinitions: definition.definitions!,
        themeColors: AppThemeColors.seedColor(
          seedColor: const Color(0xFFF9140C), // WordDefine red color (same as original)
          secondaryColor: const Color(0xFFF9140C), // Use red for secondary as well
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
        appThemeDisplay: Theme.of(context).extension<AppThemeDisplay>(),
        showSearch: false,
        showTitle: true, // Show everything as original
        showShareButton: true,
        showAISummary: true, // Show AI summary as original
        showSimilarWords: true, // ✅ Show similar words in unified search
        onSimilarWordClick: (word) {
          // Search for the clicked similar word
          controller.searchStreaming(word);
        },
      ),
    );
  }

  Widget _buildAllVersesSection() {
    
    // 🚀 CRITICAL FIX: Always read fresh data from currentResults
    // This eliminates the stale closure parameter issue
    final List<VerseRM> verseList;
    if (currentResults?.verses?.verses.verses != null && currentResults!.verses!.verses.verses.isNotEmpty) {
      verseList = currentResults!.verses!.verses.verses;
      if (kDebugMode) {
        print("🚀 UNIFIED: Building VersesContentWidget with FRESH data (${verseList.length} verses)");
        print("🔄 UNIFIED: CURRENT first verse PK: ${verseList.isNotEmpty ? verseList.first.versePk : 'N/A'}");
        print("🔄 UNIFIED: currentResults reference: ${currentResults.hashCode}");
      }
    } else {
      // Fallback - this should rarely happen
      verseList = [];
      if (kDebugMode) {
        print("❌ UNIFIED: No current results available, using empty list");
      }
    }
    
    if (verseList.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // 🚀 CRITICAL FIX: Force widget recreation by including content hash in key
    // This ensures Flutter rebuilds the widget when verse content changes
    final contentHash = verseList.map((v) => '${v.versePk}_${v.verseText?.hashCode ?? 0}').join('_');
    final widgetKey = 'unified_verses_$contentHash';
    if (kDebugMode) print("🔑 UNIFIED: Building VersesContentWidget with key: ${widgetKey.substring(0, 50)}...");
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language selector bar for verses
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppThemeColors.seedColor(
              seedColor: Theme.of(context).colorScheme.primary,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ).surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppThemeColors.seedColor(
                seedColor: Theme.of(context).colorScheme.primary,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ).primary.withAlpha(0x33),
              width: 1,
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
                      color: AppThemeColors.seedColor(
                        seedColor: Theme.of(context).colorScheme.primary,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      ).primary,
                    ),
                    SizedBox(width: TdResDimens.dp_4),
                    Flexible(
                      child: Text(
                        "Transcription by Aksharamukha",
                        style: TdResTextStyles.caption.copyWith(
                          color: AppThemeColors.seedColor(
                            seedColor: Theme.of(context).colorScheme.primary,
                            isDark: Theme.of(context).brightness == Brightness.dark,
                          ).primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${verseList.length} verses',
                      style: TdResTextStyles.caption.copyWith(
                        color: AppThemeColors.seedColor(
                          seedColor: Theme.of(context).colorScheme.primary,
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ).onSurfaceMedium,
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
        // Verses content
        Container(
          constraints: BoxConstraints(maxHeight: 500),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: VersesContentWidget(
              key: ValueKey(widgetKey),
              verses: verseList,
              themeColors: AppThemeColors.seedColor(
                seedColor: Theme.of(context).colorScheme.primary,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
              appThemeDisplay: Theme.of(context).extension<AppThemeDisplay>(),
              language: _getCurrentLanguage(),
              onBookmarkToggle: (verse, isBookmarked) => _handleBookmarkToggle(verse, isBookmarked),
              onPreviousVerse: (versePk) => _handlePreviousVerse(versePk),
              onNextVerse: (versePk) => _handleNextVerse(versePk),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChunksSection(UnifiedChunkResponse chunks) {
    if (chunks.chunks?.data.isEmpty != false) return const SizedBox.shrink();
    
    if (kDebugMode) {
      print("🚀 PERFORMANCE: Building lightweight BookChunksContentWidget with ${chunks.chunks!.data.length} chunks");
      print("🚀 PERFORMANCE: Using optimized content widget instead of full BooksPage");
    }
    
    // 🚀 PERFORMANCE: Use lightweight content widget instead of full page
    return Container(
      constraints: BoxConstraints(maxHeight: 500),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BookChunksContentWidget(
          key: ValueKey('unified_books_optimized'),
          chunks: chunks.chunks!.data,
          themeColors: AppThemeColors.seedColor(
            seedColor: Colors.blue, // Books module color
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          appThemeDisplay: Theme.of(context).extension<AppThemeDisplay>()!,
          // Book chunk navigation handlers
          onNavigatePrevious: _handlePreviousChunk,
          onNavigateNext: _handleNextChunk,
          // Book chunk bookmark handler
          onBookmarkToggle: _handleBookChunkBookmarkToggle,
        ),
      ),
    );
  }

  /// Replicate the exact BookChunkItemWidget design
  Widget _buildBookChunkItem(dynamic chunk) {
    const Color _booksBlue = Colors.blue;
    final shouldShowExpandButton = chunk.text.length > 150 || chunk.text.split('\n').length > 3;
    final GlobalKey repaintBoundaryKey = GlobalKey();
    
    return RepaintBoundary(
      key: repaintBoundaryKey,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: themeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _booksBlue.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _booksBlue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content with consistent structure: Text -> Reference
          if (shouldShowExpandButton)
            Column(
              children: [
                _buildExpandableContent(chunk),
                _buildChunkReference(chunk), // Reference always at bottom
              ],
            )
          else
            Column(
              children: [
                Container(
                  padding: EdgeInsets.all(TdResDimens.dp_16),
                  child: Text(
                    chunk.text,
                    style: TdResTextStyles.p1.copyWith(
                      color: themeColors.onSurface,
                      height: 1.6,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildChunkReference(chunk), // Reference always at bottom
              ],
            ),
          
          // Action buttons with relevance score
          _buildChunkActions(chunk, repaintBoundaryKey),
        ],
      ),
      ),
    );
  }

  Widget _buildExpandableContent(dynamic chunk) {
    const Color _booksBlue = Colors.blue;
    
    return ExpandableNotifier(
      child: ExpandablePanel(
        theme: ExpandableThemeData(
          inkWellBorderRadius: BorderRadius.circular(TdResDimens.dp_16),
          iconPadding: EdgeInsets.only(
            right: TdResDimens.dp_12,
            top: TdResDimens.dp_16,
          ),
          iconColor: _booksBlue,
          headerAlignment: ExpandablePanelHeaderAlignment.center,
          tapBodyToExpand: true,
          tapBodyToCollapse: true,
          hasIcon: true,
        ),
        collapsed: Container(
          padding: EdgeInsets.all(TdResDimens.dp_16),
          child: Text(
            chunk.text,
            style: TdResTextStyles.p1.copyWith(
              color: themeColors.onSurface,
              height: 1.6,
              fontSize: 16,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        expanded: Container(
          padding: EdgeInsets.all(TdResDimens.dp_16),
          child: Text(
            chunk.text,
            style: TdResTextStyles.p1.copyWith(
              color: themeColors.onSurface,
              height: 1.6,
              fontSize: 16,
            ),
          ),
        ),
        header: Container(), // Empty header to remove top content
      ),
    );
  }

  Widget _buildChunkReference(dynamic chunk) {
    const Color _booksBlue = Colors.blue;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.library_books_rounded,
            size: 18,
            color: _booksBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _booksBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _booksBlue.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
              child: Text(
                chunk.reference,
                style: TdResTextStyles.caption.copyWith(
                  color: _booksBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChunkActions(dynamic chunk, GlobalKey repaintBoundaryKey) {
    const Color _booksBlue = Colors.blue;
    final percentage = (chunk.score * 100).toStringAsFixed(1);
    
    return Container(
      decoration: BoxDecoration(
        color: _booksBlue.withOpacity(0.03),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(TdResDimens.dp_16),
          bottomRight: Radius.circular(TdResDimens.dp_16),
        ),
        border: Border(
          top: BorderSide(
            color: _booksBlue.withOpacity(0.1),
            width: 1.0,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: TdResDimens.dp_8, 
        vertical: TdResDimens.dp_8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildChunkActionButton(
            icon: Icons.star_rounded,
            label: "$percentage%",
            onPressed: () {}, // No action needed - just display
            score: chunk.score,
          ),
          _buildChunkActionButton(
            icon: Icons.share_rounded,
            label: "Share",
            onPressed: () => showShareModal(
              chunk.text,
              chunk.chunkRefId.toString(),
              repaintBoundaryKey,
            ),
          ),
          _buildChunkActionButton(
            icon: Icons.info_outline_rounded,
            label: "Citation",
            onPressed: () => showCitationModal(chunk.chunkRefId),
          ),
        ],
      ),
    );
  }

  Widget _buildChunkActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    double? score,
  }) {
    const Color _booksBlue = Colors.blue;
    // Special handling for star (relevance) button
    final isRelevanceButton = icon == Icons.star_rounded;
    final iconColor = isRelevanceButton ? _getStarColor(score ?? 0.0) : _booksBlue;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(TdResDimens.dp_8),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: TdResDimens.dp_4,
              horizontal: TdResDimens.dp_6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRelevanceButton && score != null)
                  _buildFilledStar(score)
                else
                  Icon(
                    icon,
                    color: iconColor,
                    size: 18,
                  ),
                SizedBox(height: TdResDimens.dp_2),
                Text(
                  label,
                  style: TdResTextStyles.caption.copyWith(
                    color: _booksBlue,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilledStar(double score) {
    const Color _booksBlue = Colors.blue;
    final starFill = score.clamp(0.0, 1.0);
    
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        children: [
          // Background star (outlined)
          Icon(
            Icons.star_border_rounded,
            size: 18,
            color: _booksBlue.withOpacity(0.3),
          ),
          // Filled portion of star
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: starFill,
              child: Icon(
                Icons.star_rounded,
                size: 18,
                color: _getStarColor(score),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStarColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.5) return Colors.orange;
    return Colors.red;
  }

  void showShareModal(String text, String chunkId, [GlobalKey? widgetKey]) {
    const Color _booksBlue = Colors.blue;
    ShareModal.show(
      context: context,
      themeColors: themeColors,
      textToShare: text,
      onCopyText: () {
        final chunkRefId = int.tryParse(chunkId);
        if (chunkRefId != null) {
          copyChunkToClipboard(chunkRefId);
        } else {
          // Fallback to legacy copy if ID is not a valid int
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Copied to clipboard!",
                style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
              ),
              backgroundColor: _booksBlue,
            ),
          );
        }
      },
      onShareImage: () => _handleShareImage(chunkId, text, widgetKey),
      contentType: 'chunk', // Blue theme for chunks
    );
  }

  Future<void> _handleShareImage(String chunkId, String chunkText, GlobalKey? widgetKey) async {
    try {
      final shareRepo = Modular.get<ShareRepository>();
      bool success;

      if (widgetKey != null) {
        success = await shareRepo.shareChunkAsImage(
          widgetKey: widgetKey,
          chunkId: chunkId,
          chunkText: chunkText,
        );
      } else {
        success = await shareRepo.shareChunkAsText(
          chunkId: chunkId,
          chunkText: chunkText,
        );
      }

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to share image"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error sharing: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void copyChunkToClipboard(int chunkRefId) {
    // Find the chunk text by ID
    if (currentResults?.chunks?.chunks.data != null) {
      final chunk = currentResults!.chunks!.chunks.data.firstWhere(
        (c) => c.chunkRefId == chunkRefId,
        orElse: () => currentResults!.chunks!.chunks.data.first,
      );
      
      Clipboard.setData(ClipboardData(text: chunk.text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Copied to clipboard!",
            style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
          ),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> showCitationModal(int chunkRefId) async {
    const Color _booksBlue = Colors.blue;
    OverlayEntry? loadingOverlay;
    try {
      final citationRepo = Modular.get<CitationRepository>();
      loadingOverlay = OverlayEntry(
        builder: (context) => Material(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: CircularProgressIndicator(
              color: _booksBlue,
            ),
          ),
        ),
      );
      Overlay.of(context).insert(loadingOverlay);
      final citation = await citationRepo.getChunkCitation(chunkRefId);
      loadingOverlay.remove();
      loadingOverlay = null;
      await Future.delayed(const Duration(milliseconds: 50));
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
            themeColors: themeColors,
            contentType: 'chunk',
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Citation not found",
              style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      loadingOverlay?.remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error loading citation: $e",
              style: TdResTextStyles.h5.copyWith(color: themeColors.surface),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Compact language selector for the Aksharamukha bar - exactly like random folder
  Widget _buildCompactLanguageSelector() {
    final dashboardController = Modular.get<DashboardController>();
    final themeColors = AppThemeColors.seedColor(
      seedColor: Theme.of(context).colorScheme.primary,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );

    return BlocBuilder<DashboardController, DashboardCubitState>(
      bloc: dashboardController,
      buildWhen: (previous, current) =>
          current.verseLanguagePref != previous.verseLanguagePref,
      builder: (context, state) {
        final currentLanguage = state.verseLanguagePref?.output ?? VersesConstants.LANGUAGE_DEFAULT;
        
        return PopupMenuButton<String>(
          key: ValueKey('unified_language_dropdown_$currentLanguage'), // Force rebuild on language change
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
            print("🎯 UNIFIED: User selected language '$value' from dropdown");
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
