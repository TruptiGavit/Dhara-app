import 'package:flutter/material.dart';
import 'package:dharak_flutter/app/ui/constants.dart';

/// Utility class for managing tab colors based on active sections
class TabColors {
  // Color definitions for each section
  static const Color unifiedColor = Color(0xFFFF6B35); // Orange
  static const Color dictColor = Color(0xFFE53E3E); // Red  
  static const Color verseColor = Color(0xFF38A169); // Green
  static const Color booksColor = Color(0xFF3182CE); // Blue
  static const Color prashnaColor = Color(0xFF6366F1); // Indigo

  /// Get color for main tab (QuickSearch or Prashna)
  static Color getMainTabColor(String tabName) {
    switch (tabName) {
      case '/quicksearch':
        return unifiedColor; // Default to unified when quicksearch is active
      case '/prashna':
        return prashnaColor;
      case '/word-define':
        return dictColor;
      case '/verse':
        return verseColor;
      default:
        return unifiedColor;
    }
  }

  /// Get color for QuickSearch sub-section
  static Color getQuickSearchSectionColor(String sectionName) {
    switch (sectionName.toLowerCase()) {
      case 'unified':
        return unifiedColor;
      case 'dictionary':
      case 'dict':
      case 'worddefine':
        return dictColor;
      case 'verse':
      case 'quickverse':
        return verseColor;
      case 'books':
        return booksColor;
      default:
        return unifiedColor;
    }
  }

  /// Get light shade of color for subtle effects
  static Color getLightShade(Color color, {double opacity = 0.1}) {
    return color.withOpacity(opacity);
  }

  /// Get appropriate text color for given background
  static Color getTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5 
        ? Colors.black87 
        : Colors.white;
  }

  /// Tab color mapping for legacy support
  static const Map<String, Color> tabColorMap = {
    '/unified': unifiedColor,
    '/word-define': dictColor,
    '/verse': verseColor,
    '/books': booksColor,
    '/quicksearch': unifiedColor,
    '/prashna': prashnaColor,
  };
}

