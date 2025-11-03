import 'package:flutter/material.dart';
import 'package:dharak_flutter/app/core/reusable_pages/reusable_page_manager.dart';
import 'package:dharak_flutter/app/ui/widgets/unified_streaming_display.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'dart:async';
import 'dart:convert';

/// **COMPLETE SOLUTION DEMO**
/// This demonstrates all your requirements:
/// 1. Exact same pages reusable anywhere without BLoC conflicts
/// 2. Streaming results from unified search (dummy.json format)
/// 3. Tools cards that expand to show full pages
/// 4. Multiple instances of same module with different data
class CompleteSolutionDemo extends StatefulWidget {
  const CompleteSolutionDemo({super.key});

  @override
  State<CompleteSolutionDemo> createState() => _CompleteSolutionDemoState();
}

class _CompleteSolutionDemoState extends State<CompleteSolutionDemo>
    with TickerProviderStateMixin {
  late AppThemeColors themeColors;
  late TabController _tabController;
  
  // Streaming controller for unified search demo
  final StreamController<Map<String, dynamic>> _unifiedStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    themeColors = Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: const Color(0xFF6CE18D), isDark: false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Solution Demo'),
        backgroundColor: themeColors.primary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Multiple Cards'),
            Tab(text: 'Tools Expansion'),
            Tab(text: 'Streaming Demo'),
            Tab(text: 'Independent Pages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMultipleCardsDemo(),
          _buildToolsExpansionDemo(),
          _buildStreamingDemo(),
          _buildIndependentPagesDemo(),
        ],
      ),
    );
  }
  
  /// **TAB 1: MULTIPLE CARDS DEMO**
  /// Shows how you can have multiple cards with same module but different data
  /// Solves your "rama and sita separate cards" requirement
  Widget _buildMultipleCardsDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDemoHeader(
            'Multiple Cards with Same Module',
            'Each card has its own independent controller instance.\nNo BLoC conflicts!',
            Icons.view_column,
            Colors.green,
          ),
          
          const SizedBox(height: 20),
          
          // Row of cards showing different words
          Row(
            children: [
              // Card 1: Rama
              Expanded(
                child: _buildWordCard(
                  word: 'Rama',
                  description: 'Joy, delight, lover',
                  color: const Color(0xFFF9140C),
                  onTap: () => _showWordDialog('Rama'),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Card 2: Sita  
              Expanded(
                child: _buildWordCard(
                  word: 'Sita',
                  description: 'White, bound, arrow',
                  color: const Color(0xFFF9140C),
                  onTap: () => _showWordDialog('Sita'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Embedded pages showing side by side
          Text(
            'Embedded Pages (Side by Side)',
            style: TdResTextStyles.h5.copyWith(
              color: themeColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            height: 400,
            child: Row(
              children: [
                // Left: Rama WordDefine page
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFF9140C)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ReusablePageManager.createIndependentWordDefinePage(
                      preloadedWord: 'Rama',
                      hideWelcomeMessage: true,
                      uniqueKey: 'embedded_rama',
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Right: Sita WordDefine page
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFF9140C)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ReusablePageManager.createIndependentWordDefinePage(
                      preloadedWord: 'Sita',
                      hideWelcomeMessage: true,
                      uniqueKey: 'embedded_sita',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// **TAB 2: TOOLS EXPANSION DEMO**
  /// Shows how tools cards can expand to show full pages
  /// Like your tools tab in prashna
  Widget _buildToolsExpansionDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDemoHeader(
            'Tools Card Expansion',
            'Click on any tool to expand and see the full page.\nJust like your tools tab in Prashna!',
            Icons.build,
            Colors.orange,
          ),
          
          const SizedBox(height: 20),
          
          // Tools grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildToolCard(
                title: 'Word Definitions',
                icon: Icons.local_library_outlined,
                color: const Color(0xFFF9140C),
                description: 'Sanskrit meanings & etymology',
                onTap: () => _showToolExpansion('WordDefine'),
              ),
              
              _buildToolCard(
                title: 'Verses & Shlokas',
                icon: Icons.keyboard_command_key,
                color: const Color(0xFF189565),
                description: 'Sacred texts & poetry',
                onTap: () => _showToolExpansion('QuickVerse'),
              ),
              
              _buildToolCard(
                title: 'Ancient Books',
                icon: Icons.menu_book,
                color: Colors.blue,
                description: 'Scriptures & literature',
                onTap: () => _showToolExpansion('Books'),
              ),
              
              _buildToolCard(
                title: 'AI Chat',
                icon: Icons.chat_bubble_outline,
                color: Colors.indigo,
                description: 'Personalized insights',
                onTap: () => _showToolExpansion('Prashna'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// **TAB 3: STREAMING DEMO**
  /// Shows unified search with streaming results from dummy.json format
  Widget _buildStreamingDemo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildDemoHeader(
                'Unified Streaming Search',
                'Results appear as they stream in from backend.\nJust like your dummy.json format!',
                Icons.stream,
                Colors.purple,
              ),
              
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: _startStreamingDemo,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Streaming Demo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: UnifiedStreamingDisplay(
            unifiedStream: _unifiedStreamController.stream,
            hideSearchBars: true,
          ),
        ),
      ],
    );
  }
  
  /// **TAB 4: INDEPENDENT PAGES DEMO**
  /// Shows full independent pages that can be used anywhere
  Widget _buildIndependentPagesDemo() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: _buildDemoHeader(
              'Independent Pages',
              'Full pages with their own controllers.\nUse anywhere without conflicts!',
              Icons.web,
              Colors.teal,
            ),
          ),
          
          const TabBar(
            tabs: [
              Tab(text: 'WordDefine'),
              Tab(text: 'QuickVerse'),
              Tab(text: 'Books'),
              Tab(text: 'Prashna'),
            ],
          ),
          
          Expanded(
            child: TabBarView(
              children: [
                ReusablePageManager.createIndependentWordDefinePage(
                  uniqueKey: 'demo_worddefine',
                ),
                
                ReusablePageManager.createIndependentQuickVersePage(
                  uniqueKey: 'demo_quickverse',
                ),
                
                ReusablePageManager.createIndependentBooksPage(
                  uniqueKey: 'demo_books',
                ),
                
                ReusablePageManager.createIndependentPrashnaPage(
                  uniqueKey: 'demo_prashna',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDemoHeader(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TdResTextStyles.h4.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TdResTextStyles.h6.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWordCard({
    required String word,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_library_outlined, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  word,
                  style: TdResTextStyles.h4.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TdResTextStyles.h6.copyWith(
                color: color.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to view full page',
              style: TdResTextStyles.caption.copyWith(
                color: color.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildToolCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TdResTextStyles.h6.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TdResTextStyles.caption.copyWith(
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showWordDialog(String word) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9140C),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4.0),
                    topRight: Radius.circular(4.0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_library_outlined, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      '$word - WordDefine',
                      style: TdResTextStyles.h5.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ReusablePageManager.createIndependentWordDefinePage(
                  preloadedWord: word,
                  hideSearchBar: false, // Allow searching within dialog
                  uniqueKey: 'dialog_$word',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showToolExpansion(String toolType) {
    Widget page;
    String title;
    Color color;
    IconData icon;
    
    switch (toolType) {
      case 'WordDefine':
        page = ReusablePageManager.createIndependentWordDefinePage(
          uniqueKey: 'tool_worddefine',
        );
        title = 'WordDefine Tool';
        color = const Color(0xFFF9140C);
        icon = Icons.local_library_outlined;
        break;
        
      case 'QuickVerse':
        page = ReusablePageManager.createIndependentQuickVersePage(
          uniqueKey: 'tool_quickverse',
        );
        title = 'QuickVerse Tool';
        color = const Color(0xFF189565);
        icon = Icons.keyboard_command_key;
        break;
        
      case 'Books':
        page = ReusablePageManager.createIndependentBooksPage(
          uniqueKey: 'tool_books',
        );
        title = 'Books Tool';
        color = Colors.blue;
        icon = Icons.menu_book;
        break;
        
      case 'Prashna':
        page = ReusablePageManager.createIndependentPrashnaPage(
          uniqueKey: 'tool_prashna',
        );
        title = 'Prashna Tool';
        color = Colors.indigo;
        icon = Icons.chat_bubble_outline;
        break;
        
      default:
        return;
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4.0),
                    topRight: Radius.circular(4.0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TdResTextStyles.h5.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              Expanded(child: page),
            ],
          ),
        ),
      ),
    );
  }
  
  void _startStreamingDemo() {
    // Simulate your dummy.json streaming format
    final dummyData = [
      {
        "type": "splits",
        "data": {
          "nouns": ["rama", "sita", "gururbrambha"],
          "verbs": ["is", "give", "verse"],
          "quoted_texts": ["gururbrambha"],
          "heritage_query": "who is rama and sita and give me verse about \"gururbrambha\""
        }
      },
      {
        "type": "definition",
        "data": {
          "given_word": "rama",
          "success": true,
          "found_match": true,
          "details": {
            "word": "rama",
            "definitions": [
              {
                "text": "Joy, delight, pleasure",
                "short_text": "Joy, delight",
                "language": "English",
                "source": "Demo Dictionary"
              }
            ]
          }
        }
      },
      {
        "type": "definition",
        "data": {
          "given_word": "sita",
          "success": true,
          "found_match": true,
          "details": {
            "word": "sita",
            "definitions": [
              {
                "text": "White, bound, tied",
                "short_text": "White, bound",
                "language": "English",
                "source": "Demo Dictionary"
              }
            ]
          }
        }
      },
      {
        "type": "verse",
        "data": [
          {
            "verse_text": "Sample verse about Rama and Sita",
            "verse_ref": "Demo.1.1",
            "verse_pk": 1,
            "is_starred": false
          }
        ]
      },
      {
        "type": "chunk",
        "data": [
          {
            "text": "Sample book excerpt about Rama and Sita",
            "reference": "Demo Book Chapter 1",
            "chunk_ref_id": 1,
            "score": 0.85
          }
        ]
      }
    ];
    
    // Stream data with delays to simulate real streaming
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timer.tick > dummyData.length) {
        timer.cancel();
        return;
      }
      
      final dataIndex = timer.tick - 1;
      _unifiedStreamController.add(dummyData[dataIndex]);
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _unifiedStreamController.close();
    super.dispose();
  }
}


