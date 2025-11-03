import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:dharak_flutter/app/ui/pages/words/controller.dart';
import 'package:dharak_flutter/app/ui/pages/words/page.dart';
import 'package:dharak_flutter/app/ui/pages/words/args.dart';
import 'package:dharak_flutter/app/ui/pages/verses/controller.dart';
import 'package:dharak_flutter/app/ui/pages/verses/page.dart';
import 'package:dharak_flutter/app/ui/pages/verses/args.dart';
import 'package:dharak_flutter/app/ui/pages/books/controller.dart';
import 'package:dharak_flutter/app/ui/pages/books/page.dart';
import 'package:dharak_flutter/app/ui/pages/books/args.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/controller.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/page.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/args.dart';

/// **SOLUTION TO YOUR CORE PROBLEM:**
/// This manager creates completely independent instances of your pages
/// so you can show EXACT SAME WordDefine/QuickVerse/Books pages anywhere
/// without BLoC conflicts or state interference
/// 
/// Each call creates a fresh controller instance, so you can have:
/// - One "Rama" card with its own WordDefine instance
/// - One "Sita" card with its own WordDefine instance  
/// - No conflicts between them!
class ReusablePageManager {
  
  /// Creates an independent WordDefine page with its own controller
  /// Perfect for tools card expansion or separate search instances
  static Widget createIndependentWordDefinePage({
    String? preloadedWord,
    Map<String, dynamic>? preloadedData,
    bool hideSearchBar = false,
    bool hideWelcomeMessage = false,
    String? uniqueKey,
  }) {
    // Create a COMPLETELY NEW controller instance
    // This solves your BLoC instance conflict issue!
    final independentController = WordDefineController(
      mDictionaryRepository: Modular.get(), // Get fresh repo instance
      mAuthAccountRepository: Modular.get(), // Get auth repo
    );
    
    // If we have preloaded word, set it and trigger search
    if (preloadedWord != null) {
      independentController.mSearchController.text = preloadedWord;
      // Trigger search after widget is mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (independentController.isClosed == false) {
          independentController.onSearchDirectQuery(preloadedWord);
        }
      });
    }
    
    return BlocProvider<WordDefineController>.value(
      value: independentController,
      child: WordDefinePage(
        key: uniqueKey != null ? ValueKey('worddefine_$uniqueKey') : null,
        mRequestArgs: WordDefineArgsRequest(
          default1: "independent_instance",
          hideSearchBar: hideSearchBar,
          hideWelcomeMessage: hideWelcomeMessage,
        ),
      ),
    );
  }
  
  /// Creates an independent QuickVerse page with its own controller
  /// Preserves streaming and language selection features
  static Widget createIndependentQuickVersePage({
    String? preloadedQuery,
    List<dynamic>? preloadedVerses,
    bool hideSearchBar = false,
    bool hideWelcomeMessage = false,
    String? uniqueKey,
  }) {
    // Create COMPLETELY NEW controller instance
    final independentController = VersesController(
      mVersesRepo: Modular.get(), // Fresh repo instance
      mAuthAccountRepository: Modular.get(), // Get auth repo
    );
    
    // If we have preloaded query, set it and trigger search
    if (preloadedQuery != null) {
      independentController.mSearchController.text = preloadedQuery;
      // Trigger search after widget is mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (independentController.isClosed == false) {
          independentController.onSearchDirectQuery(preloadedQuery);
        }
      });
    }
    
    return BlocProvider<VersesController>.value(
      value: independentController,
      child: VersesPage(
        key: uniqueKey != null ? ValueKey('quickverse_$uniqueKey') : null,
        mRequestArgs: VersesArgsRequest(
          default1: "independent_instance",
          hideSearchBar: hideSearchBar,
          hideWelcomeMessage: hideWelcomeMessage,
        ),
      ),
    );
  }
  
  /// Creates an independent Books page with its own controller
  static Widget createIndependentBooksPage({
    String? preloadedQuery,
    List<dynamic>? preloadedChunks,
    bool hideSearchBar = false,
    bool hideWelcomeMessage = false,
    String? uniqueKey,
  }) {
    // Create COMPLETELY NEW controller instance
    final independentController = BooksController(
      mBooksRepository: Modular.get(), // Fresh repo instance
      mAuthAccountRepository: Modular.get(), // Get auth repo
    );
    
    // If we have preloaded query, set it and trigger search
    if (preloadedQuery != null) {
      independentController.mSearchController.text = preloadedQuery;
      // Trigger search after widget is mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (independentController.isClosed == false) {
          independentController.onSearchDirectQuery(preloadedQuery);
        }
      });
    }
    
    return BlocProvider<BooksController>.value(
      value: independentController,
      child: BooksPage(
        key: uniqueKey != null ? ValueKey('books_$uniqueKey') : null,
        mRequestArgs: BooksArgsRequest(
          default1: "independent_instance",
          hideSearchBar: hideSearchBar,
          hideWelcomeMessage: hideWelcomeMessage,
        ),
      ),
    );
  }
  
  /// Creates an independent Prashna page with its own controller
  static Widget createIndependentPrashnaPage({
    String? initialMessage,
    bool hideSearchBar = false,
    bool hideWelcomeMessage = false,
    String? uniqueKey,
  }) {
    // Create COMPLETELY NEW controller instance
    final independentController = PrashnaController(
      prashnaRepository: Modular.get(), // Fresh repo instance
    );
    
    // If we have initial message, set it
    if (initialMessage != null) {
      independentController.messageController.text = initialMessage;
    }
    
    return BlocProvider<PrashnaController>.value(
      value: independentController,
      child: PrashnaPage(
        key: uniqueKey != null ? ValueKey('prashna_$uniqueKey') : null,
        mRequestArgs: PrashnaArgsRequest(
          default1: "independent_instance",
          initialMessage: initialMessage,
          sessionId: null,
        ),
      ),
    );
  }
}

/// **STREAMING-AWARE WRAPPER**
/// This wrapper shows results as they stream in real-time
/// Perfect for unified search where results come incrementally
class StreamingResultsWrapper extends StatefulWidget {
  final Widget child;
  final Stream<List<dynamic>>? resultsStream;
  final Function(List<dynamic>)? onNewResults;
  
  const StreamingResultsWrapper({
    super.key,
    required this.child,
    this.resultsStream,
    this.onNewResults,
  });
  
  @override
  State<StreamingResultsWrapper> createState() => _StreamingResultsWrapperState();
}

class _StreamingResultsWrapperState extends State<StreamingResultsWrapper> {
  List<dynamic> _accumulatedResults = [];
  
  @override
  void initState() {
    super.initState();
    _listenToStream();
  }
  
  void _listenToStream() {
    widget.resultsStream?.listen((newResults) {
      if (mounted) {
        setState(() {
          // Accumulate results as they arrive (streaming behavior)
          _accumulatedResults = [..._accumulatedResults, ...newResults];
        });
        
        // Notify parent about new results
        widget.onNewResults?.call(_accumulatedResults);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// **USAGE EXAMPLES:**
/// 
/// **1. For Tools Card Expansion (Prashna/Unified):**
/// ```dart
/// // In your tools card expansion:
/// GestureDetector(
///   onTap: () {
///     showDialog(
///       context: context,
///       builder: (context) => Dialog(
///         child: Container(
///           height: 600,
///           child: ReusablePageManager.createIndependentWordDefinePage(
///             preloadedWord: "rama",
///             hideSearchBar: false, // Allow searching within the dialog
///             uniqueKey: "dialog_rama", // Unique key to avoid conflicts
///           ),
///         ),
///       ),
///     );
///   },
///   child: YourToolsCard(),
/// )
/// ```
/// 
/// **2. For Multiple Cards with Different Data:**
/// ```dart
/// Column(
///   children: [
///     // Card 1: Rama definitions
///     ReusablePageManager.createIndependentWordDefinePage(
///       preloadedWord: "rama", 
///       uniqueKey: "card_rama",
///       hideWelcomeMessage: true,
///     ),
///     
///     // Card 2: Sita definitions  
///     ReusablePageManager.createIndependentWordDefinePage(
///       preloadedWord: "sita",
///       uniqueKey: "card_sita", 
///       hideWelcomeMessage: true,
///     ),
///   ],
/// )
/// ```
/// 
/// **3. For Streaming Results (Unified Search):**
/// ```dart
/// StreamingResultsWrapper(
///   resultsStream: unifiedSearchController.stream,
///   onNewResults: (results) {
///     // Show each result as it arrives
///     for (final result in results) {
///       if (result.type == 'definition') {
///         // Show WordDefine result immediately
///       } else if (result.type == 'verse') {
///         // Show QuickVerse result immediately
///       }
///     }
///   },
///   child: YourResultsPage(),
/// )
/// ```
