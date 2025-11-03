import 'package:flutter/material.dart';
import 'package:dharak_flutter/app/core/reusable_pages/reusable_page_manager.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';

/// **UNIFIED STREAMING DISPLAY**
/// This widget shows unified search results as they stream in
/// Each module result appears immediately when received from backend
/// Perfect for your dummy.json streaming format
class UnifiedStreamingDisplay extends StatefulWidget {
  final Stream<Map<String, dynamic>>? unifiedStream;
  final bool hideSearchBars;
  
  const UnifiedStreamingDisplay({
    super.key,
    this.unifiedStream,
    this.hideSearchBars = true,
  });
  
  @override
  State<UnifiedStreamingDisplay> createState() => _UnifiedStreamingDisplayState();
}

class _UnifiedStreamingDisplayState extends State<UnifiedStreamingDisplay> {
  late AppThemeColors themeColors;
  
  // Accumulated results by type
  Map<String, dynamic>? splitsData;
  List<Map<String, dynamic>> definitionData = [];
  List<Map<String, dynamic>> verseData = [];
  List<Map<String, dynamic>> chunkData = [];
  
  // Track what we've received for progressive display
  bool hasSplits = false;
  bool hasDefinitions = false;
  bool hasVerses = false;
  bool hasChunks = false;
  
  @override
  void initState() {
    super.initState();
    _listenToUnifiedStream();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    themeColors = Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: const Color(0xFF6CE18D), isDark: false);
  }
  
  void _listenToUnifiedStream() {
    widget.unifiedStream?.listen((streamData) {
      if (mounted) {
        final type = streamData['type'] as String?;
        final data = streamData['data'];
        
        setState(() {
          switch (type) {
            case 'splits':
              splitsData = data;
              hasSplits = true;
              break;
              
            case 'definition':
              definitionData.add(data);
              hasDefinitions = true;
              break;
              
            case 'verse':
              if (data is List) {
                verseData.addAll(data.cast<Map<String, dynamic>>());
              } else {
                verseData.add(data);
              }
              hasVerses = true;
              break;
              
            case 'chunk':
              if (data is List) {
                chunkData.addAll(data.cast<Map<String, dynamic>>());
              } else {
                chunkData.add(data);
              }
              hasChunks = true;
              break;
          }
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show splits information if available
          if (hasSplits && splitsData != null) _buildSplitsSection(),
          
          // Show definitions as they arrive
          if (hasDefinitions) _buildDefinitionsSection(),
          
          // Show verses as they arrive
          if (hasVerses) _buildVersesSection(),
          
          // Show book chunks as they arrive
          if (hasChunks) _buildChunksSection(),
          
          // Show loading state if nothing received yet
          if (!hasSplits && !hasDefinitions && !hasVerses && !hasChunks)
            _buildLoadingState(),
        ],
      ),
    );
  }
  
  Widget _buildSplitsSection() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Query Analysis',
                style: TdResTextStyles.h5.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSplitItem('Nouns', splitsData!['nouns'], Colors.green),
          _buildSplitItem('Verbs', splitsData!['verbs'], Colors.orange),
          _buildSplitItem('Quoted Texts', splitsData!['quoted_texts'], Colors.purple),
          if (splitsData!['heritage_query']?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Heritage Query: ${splitsData!['heritage_query']}',
                style: TdResTextStyles.caption.copyWith(
                  color: Colors.blue.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSplitItem(String label, List<dynamic>? items, Color color) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Wrap(
        children: [
          Text(
            '$label: ',
            style: TdResTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          ...items.map((item) => Container(
            margin: const EdgeInsets.only(right: 6.0, top: 2.0),
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              item.toString(),
              style: TdResTextStyles.caption.copyWith(color: color),
            ),
          )).toList(),
        ],
      ),
    );
  }
  
  Widget _buildDefinitionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Word Definitions', Icons.local_library_outlined, const Color(0xFFF9140C)),
        ...definitionData.map((defData) => _buildDefinitionCard(defData)).toList(),
      ],
    );
  }
  
  Widget _buildDefinitionCard(Map<String, dynamic> defData) {
    final word = defData['given_word'] as String? ?? 'Unknown';
    final success = defData['success'] as bool? ?? false;
    final foundMatch = defData['found_match'] as bool? ?? false;
    
    if (!success || !foundMatch) {
      return _buildNoResultCard(word, 'definition');
    }
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: Card(
        elevation: 2,
        child: ExpansionTile(
          leading: Icon(Icons.local_library_outlined, color: const Color(0xFFF9140C)),
          title: Text(
            word.toUpperCase(),
            style: TdResTextStyles.h5.copyWith(
              color: const Color(0xFFF9140C),
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Tap to view full WordDefine page',
            style: TdResTextStyles.caption.copyWith(
              color: themeColors.onSurfaceMedium,
            ),
          ),
          children: [
            Container(
              height: 400, // Fixed height for embedded page
              child: ReusablePageManager.createIndependentWordDefinePage(
                preloadedWord: word,
                preloadedData: defData,
                hideSearchBar: widget.hideSearchBars,
                hideWelcomeMessage: true,
                uniqueKey: 'unified_def_$word',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVersesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Verses & Shlokas', Icons.keyboard_command_key, const Color(0xFF189565)),
        _buildVersesCard(),
      ],
    );
  }
  
  Widget _buildVersesCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: Card(
        elevation: 2,
        child: ExpansionTile(
          leading: Icon(Icons.keyboard_command_key, color: const Color(0xFF189565)),
          title: Text(
            'VERSES (${verseData.length} found)',
            style: TdResTextStyles.h5.copyWith(
              color: const Color(0xFF189565),
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Tap to view full QuickVerse page with streaming',
            style: TdResTextStyles.caption.copyWith(
              color: themeColors.onSurfaceMedium,
            ),
          ),
          children: [
            Container(
              height: 400, // Fixed height for embedded page
              child: ReusablePageManager.createIndependentQuickVersePage(
                preloadedVerses: verseData,
                hideSearchBar: widget.hideSearchBars,
                hideWelcomeMessage: true,
                uniqueKey: 'unified_verses',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChunksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Book Excerpts', Icons.menu_book, Colors.blue),
        _buildChunksCard(),
      ],
    );
  }
  
  Widget _buildChunksCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: Card(
        elevation: 2,
        child: ExpansionTile(
          leading: Icon(Icons.menu_book, color: Colors.blue),
          title: Text(
            'BOOK EXCERPTS (${chunkData.length} found)',
            style: TdResTextStyles.h5.copyWith(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Tap to view full Books page',
            style: TdResTextStyles.caption.copyWith(
              color: themeColors.onSurfaceMedium,
            ),
          ),
          children: [
            Container(
              height: 400, // Fixed height for embedded page
              child: ReusablePageManager.createIndependentBooksPage(
                preloadedChunks: chunkData,
                hideSearchBar: widget.hideSearchBars,
                hideWelcomeMessage: true,
                uniqueKey: 'unified_chunks',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TdResTextStyles.h4.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: color.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoResultCard(String query, String type) {
    final colors = {
      'definition': const Color(0xFFF9140C),
      'verse': const Color(0xFF189565),
      'chunk': Colors.blue,
    };
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colors[type]?.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No ${type}s found for "$query"',
                  style: TdResTextStyles.h6.copyWith(
                    color: themeColors.onSurfaceMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: themeColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Searching across all modules...',
              style: TdResTextStyles.h6.copyWith(
                color: themeColors.onSurfaceMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Results will appear as they arrive',
              style: TdResTextStyles.caption.copyWith(
                color: themeColors.onSurfaceMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


