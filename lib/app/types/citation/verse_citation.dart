class VerseCitationRM {
  final String footnote;

  VerseCitationRM({
    required this.footnote,
  });

  factory VerseCitationRM.fromJson(Map<String, dynamic> json) {
    // Handle nested cite_data structure from API
    final citeData = json['cite_data'] ?? json;
    
    return VerseCitationRM(
      footnote: citeData['Footnote'] ?? citeData['footnote'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'footnote': footnote,
    };
  }
}

class VerseCitationNotAvailableException implements Exception {
  final String message;
  
  VerseCitationNotAvailableException(this.message);
  
  @override
  String toString() => 'VerseCitationNotAvailableException: $message';
}

class VerseCitationFetchException implements Exception {
  final String message;
  
  VerseCitationFetchException(this.message);
  
  @override
  String toString() => 'VerseCitationFetchException: $message';
}
