import 'package:dharak_flutter/app/data/remote/api/parts/citation/api.dart';
import 'package:dharak_flutter/app/types/citation/citation.dart';
import 'package:dharak_flutter/app/types/citation/verse_citation.dart';
import 'package:logger/logger.dart';

class CitationService {
  final CitationApiRepo _citationApiRepo;
  final Logger _logger = Logger();

  CitationService(this._citationApiRepo);

  Future<CitationRM?> getDefinitionCitation(int dictRefId) async {
    try {
      _logger.i('Fetching citation for definition: $dictRefId');
      final result = await _citationApiRepo.getDefinitionCitation(dictRefId);
      
      if (result.data != null) {
        _logger.i('Citation fetched successfully for definition: $dictRefId');
        return result.data;
      } else {
        _logger.w('Failed to fetch citation for definition: $dictRefId, Error: ${result.error?.message}');
        return null;
      }
    } on CitationNotAvailableException catch (e) {
      _logger.w('Citation not available for definition: $dictRefId - ${e.message}');
      return null;
    } catch (e, stackTrace) {
      _logger.e('Exception while fetching definition citation: $dictRefId', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<VerseCitationRM> getVerseCitation(int versePk) async {
    try {
      _logger.i('Fetching citation for verse: $versePk');
      final result = await _citationApiRepo.getVerseCitation(versePk);
      
      if (result.data != null) {
        _logger.i('Citation fetched successfully for verse: $versePk');
        return result.data!;
      } else {
        _logger.w('Citation data is null for verse: $versePk');
        throw VerseCitationNotAvailableException('Citation not available for this verse.');
      }
    } catch (e, stackTrace) {
      _logger.e('Exception while fetching verse citation: $versePk', error: e, stackTrace: stackTrace);
      if (e is VerseCitationNotAvailableException) {
        rethrow; // Re-throw specific exception
      } else {
        throw VerseCitationFetchException('Failed to fetch citation: ${e.toString()}');
      }
    }
  }
}

class CitationNotAvailableException implements Exception {
  final String message;
  CitationNotAvailableException(this.message);
}

class VerseCitationNotAvailableException implements Exception {
  final String message;
  VerseCitationNotAvailableException(this.message);
}

class VerseCitationFetchException implements Exception {
  final String message;
  VerseCitationFetchException(this.message);
}

