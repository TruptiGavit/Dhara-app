class VersesConstants{
  // New language constants - 14 supported scripts (matching backend capabilities)
  static const String LANGUAGE_ASSAMESE = "Assamese";
  static const String LANGUAGE_BENGALI = "Bengali";
  static const String LANGUAGE_DEVANAGARI = "Devanagari";
  static const String LANGUAGE_GUJARATI = "Gujarati";
  static const String LANGUAGE_GURMUKHI = "Gurmukhi";
  static const String LANGUAGE_KANNADA = "Kannada";
  static const String LANGUAGE_MALAYALAM = "Malayalam";
  static const String LANGUAGE_TAMIL = "Tamil";
  static const String LANGUAGE_TELUGU = "Telugu";
  static const String LANGUAGE_HARVARD_KYOTO = "HK";
  static const String LANGUAGE_IAST = "IAST";
  static const String LANGUAGE_ITRANS = "Itrans";
  static const String LANGUAGE_SLP1 = "SLP1";
  static const String LANGUAGE_VELTHUIS = "Velthuis";
  static const String LANGUAGE_WX = "WX";

  // Default language (keeping Devanagari as default)
  static const String LANGUAGE_DEFAULT = LANGUAGE_DEVANAGARI;

  // Legacy constants for backward compatibility
  @Deprecated('Use LANGUAGE_DEVANAGARI instead')
  static const String LANGUAGE_HINDI = LANGUAGE_DEVANAGARI;
  @Deprecated('Use LANGUAGE_IAST instead')
  static const String LANGUAGE_ROMAN = LANGUAGE_IAST;
  @Deprecated('Use LANGUAGE_TELUGU instead')
  static const String LANGUAGE_TELEGU = LANGUAGE_TELUGU;

  // Map of API identifiers to display names
  static final LANGUAGE_LABELS_MAP = <String, String>{
    LANGUAGE_ASSAMESE: "Assamese",
    LANGUAGE_BENGALI: "Bengali",
    LANGUAGE_DEVANAGARI: "Devanagari",
    LANGUAGE_GUJARATI: "Gujarati",
    LANGUAGE_GURMUKHI: "Gurmukhi",
    LANGUAGE_KANNADA: "Kannada",
    LANGUAGE_MALAYALAM: "Malayalam",
    LANGUAGE_TAMIL: "Tamil",
    LANGUAGE_TELUGU: "Telugu",
    LANGUAGE_HARVARD_KYOTO: "Roman (Harvard–Kyoto)",
    LANGUAGE_IAST: "Roman (IAST)",
    LANGUAGE_ITRANS: "Roman (ITRANS)",
    LANGUAGE_SLP1: "Roman (SLP1)",
    LANGUAGE_VELTHUIS: "Roman (Velthuis)",
    LANGUAGE_WX: "Roman (WX)",
  };
}