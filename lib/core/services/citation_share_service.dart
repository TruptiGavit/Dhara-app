import 'package:dharak_flutter/app/data/services/citation_service.dart';
import 'package:dharak_flutter/app/data/services/share_service.dart';
import 'package:dharak_flutter/app/types/citation/citation.dart' as citation_types;
import 'package:dharak_flutter/app/types/citation/verse_citation.dart' as verse_citation_types;
import 'package:dharak_flutter/app/ui/widgets/citation_modal.dart';
import 'package:dharak_flutter/app/ui/widgets/share_modal.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Helper service that provides easy access to citation and share functionality
/// This makes it simple to use from any card or component
class CitationShareService {
  static final CitationShareService _instance = CitationShareService._internal();
  factory CitationShareService() => _instance;
  CitationShareService._internal();

  static CitationShareService get instance => _instance;

  CitationService get _citationService => Modular.get<CitationService>();
  ShareService get _shareService => Modular.get<ShareService>();

  /// Show citation modal for a dictionary definition
  Future<void> showDefinitionCitation(
    BuildContext context,
    int dictRefId, {
    AppThemeColors? themeColors,
  }) async {
    try {
      final citation = await _citationService.getDefinitionCitation(dictRefId)
          .timeout(Duration(seconds: 10));

      if (citation != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.3,
            builder: (context, scrollController) => CitationModal(
              citation: citation,
              themeColors: themeColors ?? Theme.of(context).extension<AppThemeColors>(),
              contentType: 'definition',
            ),
          ),
        );
      } else {
        _showErrorSnackbar(context, 'Citation not available for this definition');
      }
    } catch (e) {
      print('Citation error: $e'); // Debug log
      _showErrorSnackbar(context, 'Citation service temporarily unavailable');
    }
  }

  /// Show citation modal for a verse
  Future<void> showVerseCitation(
    BuildContext context,
    int versePk, {
    AppThemeColors? themeColors,
  }) async {
    try {
      final verseCitation = await _citationService.getVerseCitation(versePk)
          .timeout(Duration(seconds: 10));

      // Show simple citation modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.format_quote, color: const Color(0xFF189565)),
                  const SizedBox(width: 12),
                  const Text('Verse Citation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(verseCitation.footnote.isNotEmpty ? verseCitation.footnote : 'Citation not available'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  if (verseCitation.footnote.isNotEmpty) {
                    _copyToClipboard(context, verseCitation.footnote);
                  }
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Citation'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Verse citation error: $e'); // Debug log
      _showErrorSnackbar(context, 'Citation service temporarily unavailable');
    }
  }

  /// Show share modal for a definition
  Future<void> showDefinitionShare(
    BuildContext context,
    GlobalKey widgetKey,
    String definitionText,
    String? defId,
    String? searchedWord, {
    AppThemeColors? themeColors,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ShareModal(
        themeColors: themeColors ?? Theme.of(context).extension<AppThemeColors>(),
        textToShare: definitionText,
        contentType: 'definition',
        onCopyText: () => _copyDefinitionText(context, defId, searchedWord),
        onShareImage: () => _shareDefinitionImage(context, widgetKey, defId, definitionText, searchedWord),
      ),
    );
  }

  /// Show share modal for a verse
  Future<void> showVerseShare(
    BuildContext context,
    GlobalKey widgetKey,
    String verseText,
    String? verseId, {
    AppThemeColors? themeColors,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ShareModal(
        themeColors: themeColors ?? Theme.of(context).extension<AppThemeColors>(),
        textToShare: verseText,
        contentType: 'verse',
        onCopyText: () => _copyVerseText(context, verseId),
        onShareImage: () => _shareVerseImage(context, widgetKey, verseId, verseText),
      ),
    );
  }

  /// Copy definition text using the share service
  Future<void> _copyDefinitionText(BuildContext context, String? defId, String? searchedWord) async {
    try {
      bool success = false;
      if (defId != null) {
        success = await _shareService.copyDefinitionToClipboard(defId);
      } else if (searchedWord != null) {
        success = await _shareService.copyAllDefinitionsToClipboard(searchedWord);
      }

      if (success) {
        _showSuccessSnackbar(context, 'Definition copied to clipboard');
      } else {
        _showErrorSnackbar(context, 'Failed to copy definition');
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Error copying definition: ${e.toString()}');
    }
  }

  /// Copy verse text using the share service
  Future<void> _copyVerseText(BuildContext context, String? verseId) async {
    try {
      if (verseId != null) {
        final success = await _shareService.copyVerseToClipboard(verseId);
        if (success) {
          _showSuccessSnackbar(context, 'Verse copied to clipboard');
        } else {
          _showErrorSnackbar(context, 'Failed to copy verse');
        }
      } else {
        _showErrorSnackbar(context, 'Verse ID not available');
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Error copying verse: ${e.toString()}');
    }
  }

  /// Share definition as image using the share service
  Future<void> _shareDefinitionImage(
    BuildContext context,
    GlobalKey widgetKey,
    String? defId,
    String definitionText,
    String? searchedWord,
  ) async {
    try {
      final success = await _shareService.shareWidgetAsImage(
        widgetKey: widgetKey,
        contentType: 'definition',
        contentId: defId ?? definitionText.hashCode.toString(),
        contentText: definitionText,
        searchedWord: searchedWord,
      );

      if (!success) {
        _showErrorSnackbar(context, 'Failed to share definition image');
      }
    } on TooLongForImageException catch (e) {
      _showErrorSnackbar(context, e.message);
    } catch (e) {
      _showErrorSnackbar(context, 'Error sharing definition: ${e.toString()}');
    }
  }

  /// Share verse as image using the share service
  Future<void> _shareVerseImage(
    BuildContext context,
    GlobalKey widgetKey,
    String? verseId,
    String verseText,
  ) async {
    try {
      final success = await _shareService.shareWidgetAsImage(
        widgetKey: widgetKey,
        contentType: 'verse',
        contentId: verseId ?? verseText.hashCode.toString(),
        contentText: verseText,
      );

      if (!success) {
        _showErrorSnackbar(context, 'Failed to share verse image');
      }
    } on TooLongForImageException catch (e) {
      _showErrorSnackbar(context, e.message);
    } catch (e) {
      _showErrorSnackbar(context, 'Error sharing verse: ${e.toString()}');
    }
  }

  /// Copy text to clipboard with fallback
  Future<void> _copyToClipboard(BuildContext context, String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      _showSuccessSnackbar(context, 'Copied to clipboard');
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to copy: ${e.toString()}');
    }
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
