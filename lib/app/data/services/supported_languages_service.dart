import 'package:dharak_flutter/app/domain/verse/constants.dart';

/// Service to manage dynamically supported languages based on backend capabilities
/// This allows the frontend to automatically adapt when backend adds/removes language support
class SupportedLanguagesService {
  static final SupportedLanguagesService _instance = SupportedLanguagesService._internal();
  factory SupportedLanguagesService() => _instance;
  SupportedLanguagesService._internal();

  // Cache of tested languages that have been successfully used
  final Set<String> _testedSupportedLanguages = {};
  
  // Cache of languages that failed (to hide them from dropdown)
  final Set<String> _unsupportedLanguages = {};

  /// Get current supported languages
  /// Returns sorted map (A-Z) of all available languages minus any that have failed
  Map<String, String> getSupportedLanguages() {
    // Always return all languages except those that have explicitly failed
    return Map.fromEntries(
      VersesConstants.LANGUAGE_LABELS_MAP.entries
        .where((entry) => !_unsupportedLanguages.contains(entry.key))
        .toList()
        ..sort((a, b) => a.value.compareTo(b.value))
    );
  }

  /// Initialize supported languages from backend response
  /// This can be called when we get successful responses from language API
  void initializeFromBackend(List<String> supportedLanguageIds) {
    _testedSupportedLanguages.clear();
    _unsupportedLanguages.clear();
    
    // Mark all provided languages as tested and supported
    _testedSupportedLanguages.addAll(supportedLanguageIds);
    
    // Mark any language not in the list as unsupported (if we have a definitive list)
    for (String langId in VersesConstants.LANGUAGE_LABELS_MAP.keys) {
      if (!supportedLanguageIds.contains(langId)) {
        _unsupportedLanguages.add(langId);
      }
    }
  }

  /// Mark a language as supported (when backend accepts it)
  void markLanguageAsSupported(String languageId) {
    if (VersesConstants.LANGUAGE_LABELS_MAP.containsKey(languageId)) {
      _testedSupportedLanguages.add(languageId);
      _unsupportedLanguages.remove(languageId); // Remove from failed list if it was there
    }
  }

  /// Remove a language from supported list (when backend rejects it)
  void markLanguageAsUnsupported(String languageId) {
    _unsupportedLanguages.add(languageId);
    _testedSupportedLanguages.remove(languageId);
  }

  /// Check if a language is supported
  bool isLanguageSupported(String languageId) {
    // A language is supported if it's not in the unsupported set
    return VersesConstants.LANGUAGE_LABELS_MAP.containsKey(languageId) && 
           !_unsupportedLanguages.contains(languageId);
  }

  /// Reset to default state (all languages supported)
  void reset() {
    _testedSupportedLanguages.clear();
    _unsupportedLanguages.clear();
  }

  /// Get languages that have been successfully tested
  Set<String> getTestedLanguages() {
    return Set.from(_testedSupportedLanguages);
  }

  /// Get languages that have failed
  Set<String> getUnsupportedLanguages() {
    return Set.from(_unsupportedLanguages);
  }

  /// For future backend integration: parse supported languages from an API response
  /// This method can be expanded when backend provides a dedicated supported languages endpoint
  void updateFromApiResponse(Map<String, dynamic> response) {
    // Example implementation for future backend endpoint like:
    // GET /verse/supported_languages/ -> {"supported_languages": ["Devanagari", "Bengali", ...]}
    
    if (response.containsKey('supported_languages')) {
      final supportedList = response['supported_languages'] as List<dynamic>?;
      if (supportedList != null) {
        initializeFromBackend(supportedList.cast<String>());
      }
    }
  }
}