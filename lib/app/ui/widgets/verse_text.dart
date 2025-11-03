import 'package:flutter/material.dart';
import 'package:dharak_flutter/app/domain/verse/constants.dart';

/// Simple text widget that applies appropriate fonts for verse content
/// Based on script detection to improve diacritical mark rendering
class VerseText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final String? language; // Current language setting from app

  const VerseText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.language,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the appropriate font family for the text
    final fontFamily = _getFontFamily();
    
    return Text(
      text,
      style: style?.copyWith(fontFamily: fontFamily) ?? TextStyle(fontFamily: fontFamily),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }

  /// Determine appropriate font based on language or script detection
  String? _getFontFamily() {
    // If language is set, use that for font selection
    if (language != null) {
      return _getFontForLanguage(language!);
    }
    
    // Fallback to script detection if no language specified
    return _detectScriptAndGetFont();
  }

  /// Get font family based on language setting
  String? _getFontForLanguage(String language) {
    switch (language) {
      // Scripts that need Noto Sans fonts for proper diacritic rendering
      case VersesConstants.LANGUAGE_ASSAMESE:
      case VersesConstants.LANGUAGE_BENGALI:
        return 'NotoSansBengali';
      case VersesConstants.LANGUAGE_GUJARATI:
        return 'NotoSansGujarati';
      case VersesConstants.LANGUAGE_GURMUKHI:
        return 'NotoSansGurmukhi';
      case VersesConstants.LANGUAGE_KANNADA:
        return 'NotoSansKannada';
      case VersesConstants.LANGUAGE_MALAYALAM:
        return 'NotoSansMalayalam';
      case VersesConstants.LANGUAGE_TAMIL:
        return 'NotoSansTamil';
      case VersesConstants.LANGUAGE_TELUGU:
        return 'NotoSansTelugu';
      // case VersesConstants.LANGUAGE_GRANTHA:
        // return 'NotoSansGrantha'; // Commented out for next release
        
      // Scripts that work fine with system fonts
      case VersesConstants.LANGUAGE_DEVANAGARI:
      case VersesConstants.LANGUAGE_HARVARD_KYOTO:
      case VersesConstants.LANGUAGE_IAST:
      case VersesConstants.LANGUAGE_ITRANS:
      case VersesConstants.LANGUAGE_SLP1:
      case VersesConstants.LANGUAGE_VELTHUIS:
      case VersesConstants.LANGUAGE_WX:
      //case VersesConstants.LANGUAGE_BRAHMI:
        return null; // Use system default font
        
      default:
        return null; // Use system default font
    }
  }

  /// Basic script detection for fallback when language is not set
  String? _detectScriptAndGetFont() {
    if (text.isEmpty) return null;
    
    // Check for specific Unicode ranges
    for (int i = 0; i < text.length; i++) {
      int codePoint = text.codeUnitAt(i);
      
      // Bengali/Assamese: U+0980–U+09FF
      if (codePoint >= 0x0980 && codePoint <= 0x09FF) {
        return 'NotoSansBengali';
      }
      
      // Gujarati: U+0A80–U+0AFF
      if (codePoint >= 0x0A80 && codePoint <= 0x0AFF) {
        return 'NotoSansGujarati';
      }
      
      // Gurmukhi: U+0A00–U+0A7F
      if (codePoint >= 0x0A00 && codePoint <= 0x0A7F) {
        return 'NotoSansGurmukhi';
      }
      
      // Kannada: U+0C80–U+0CFF
      if (codePoint >= 0x0C80 && codePoint <= 0x0CFF) {
        return 'NotoSansKannada';
      }
      
      // Malayalam: U+0D00–U+0D7F
      if (codePoint >= 0x0D00 && codePoint <= 0x0D7F) {
        return 'NotoSansMalayalam';
      }
      
      // Tamil: U+0B80–U+0BFF
      if (codePoint >= 0x0B80 && codePoint <= 0x0BFF) {
        return 'NotoSansTamil';
      }
      
      // Telugu: U+0C00–U+0C7F
      if (codePoint >= 0x0C00 && codePoint <= 0x0C7F) {
        return 'NotoSansTelugu';
      }
      
      // Grantha: U+11300–U+1137F (commented out for next release)
      // if (codePoint >= 0x11300 && codePoint <= 0x1137F) {
      //   return 'NotoSansGrantha';
      // }
    }
    
    // Default to system font for Devanagari and Roman scripts
    return null;
  }
}