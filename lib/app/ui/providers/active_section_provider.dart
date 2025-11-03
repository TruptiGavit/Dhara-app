import 'package:flutter/foundation.dart';

/// Provider to track the currently active section in QuickSearch
/// This allows the bottom navigation bar to change colors dynamically
class ActiveSectionProvider extends ChangeNotifier {
  String _activeSection = 'unified'; // Default to unified
  
  String get activeSection => _activeSection;
  
  /// Update the active section (unified, dictionary, verse, books)
  void setActiveSection(String section) {
    if (_activeSection != section) {
      _activeSection = section;
      notifyListeners();
    }
  }
  
  /// Reset to default unified section
  void resetToUnified() {
    setActiveSection('unified');
  }
}



























