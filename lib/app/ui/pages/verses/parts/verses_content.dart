import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/ui/pages/verses/parts/item.dart';
import 'package:dharak_flutter/app/domain/share/repo.dart';
import 'package:dharak_flutter/app/domain/citation/repo.dart';
import 'package:dharak_flutter/app/ui/widgets/share_modal.dart';
import 'package:dharak_flutter/app/ui/widgets/verse_citation_modal.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Lightweight verses content widget for unified page
/// Contains all verse functionality without page overhead
class VersesContentWidget extends StatefulWidget {
  final List<VerseRM> verses;
  final AppThemeColors themeColors;
  final AppThemeDisplay? appThemeDisplay;
  final String? language;
  final Function(VerseRM, bool)? onBookmarkToggle;
  final Function(String)? onPreviousVerse;
  final Function(String)? onNextVerse;

  const VersesContentWidget({
    super.key,
    required this.verses,
    required this.themeColors,
    this.appThemeDisplay,
    this.language,
    this.onBookmarkToggle,
    this.onPreviousVerse,
    this.onNextVerse,
  });

  @override
  State<VersesContentWidget> createState() => _VersesContentWidgetState();
}

class _VersesContentWidgetState extends State<VersesContentWidget> {
  final ShareRepository _shareRepo = Modular.get<ShareRepository>();
  final CitationRepository _citationRepo = Modular.get<CitationRepository>();

  @override
  Widget build(BuildContext context) {
    if (widget.verses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Text(
          "No verses found",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: widget.themeColors.onSurfaceDisable,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.verses.length,
      itemBuilder: (context, index) {
        final verse = widget.verses[index];
        return Container(
          key: ValueKey('verse_unified_${verse.versePk}'),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: VerseItemWidget(
            key: ValueKey('verse_item_${verse.versePk}'),
            entity: verse,
            themeColors: widget.themeColors,
            appThemeDisplay: widget.appThemeDisplay,
            language: widget.language,
            onAddToBookmark: widget.onBookmarkToggle,
            onPreviousVerse: widget.onPreviousVerse,
            onNextVerse: widget.onNextVerse,
            onClickCopy: (message) => _copyToClipboard(message),
            onClickShare: (widgetKey) => _showShareModal(verse, widgetKey),
            onClickCitation: (versePk) => _showCitationModal(versePk),
          ),
        );
      },
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showShareModal(VerseRM verse, GlobalKey widgetKey) {
    ShareModal.show(
      context: context,
      themeColors: widget.themeColors,
      textToShare: verse.verseText ?? '',
      onCopyText: () {
        final versePk = verse.versePk;
        if (versePk != null) {
          _copyVerseToClipboard(versePk);
        } else {
          _copyToClipboard(verse.verseText ?? '');
        }
      },
      onShareImage: () => _handleShareImage(verse, widgetKey),
      contentType: 'verse',
    );
  }

  void _showCitationModal(int versePk) {
    // Get citation data and show modal
    _citationRepo.getVerseCitation(versePk).then((citation) {
      showModalBottomSheet(
        context: context,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.67,
        ),
        builder: (modalContext) => VerseCitationModal(
          citation: citation,
          themeColors: widget.themeColors,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Citation not available')),
      );
    });
  }

  void _copyVerseToClipboard(int versePk) {
    // Find the verse in our list by PK and copy its text
    final verse = widget.verses.firstWhere(
      (v) => v.versePk == versePk,
      orElse: () => widget.verses.first,
    );
    _copyToClipboard(verse.verseText ?? 'Verse text not available');
  }

  void _handleShareImage(VerseRM verse, GlobalKey widgetKey) {
    // Handle image sharing - implementation can be simple for now
    print('🖼️ Share image for verse: ${verse.versePk}');
  }
}