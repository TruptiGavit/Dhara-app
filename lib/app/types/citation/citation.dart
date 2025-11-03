class CitationRM {
  final String apa;
  final String mla;
  final String harvard;
  final String chicago;
  final String vancouver;

  CitationRM({
    required this.apa,
    required this.mla,
    required this.harvard,
    required this.chicago,
    required this.vancouver,
  });

  factory CitationRM.fromJson(Map<String, dynamic> json) {
    // Handle nested cite_data structure
    final citeData = json['cite_data'] ?? json;
    
    return CitationRM(
      apa: citeData['APA'] ?? '',
      mla: citeData['MLA'] ?? '',
      harvard: citeData['Harvard'] ?? '',
      chicago: citeData['Chichago'] ?? citeData['Chicago'] ?? '', // Handle API typo
      vancouver: citeData['Vancouver'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apa': apa,
      'mla': mla,
      'harvard': harvard,
      'chicago': chicago,
      'vancouver': vancouver,
    };
  }
}

class CitationNotAvailableException implements Exception {
  final String message;
  
  CitationNotAvailableException(this.message);
  
  @override
  String toString() => 'CitationNotAvailableException: $message';
}
