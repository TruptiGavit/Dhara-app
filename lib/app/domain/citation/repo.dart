import 'package:dharak_flutter/app/data/services/citation_service.dart';
import 'package:dharak_flutter/app/types/citation/citation.dart';
import 'package:dharak_flutter/app/types/citation/verse_citation.dart';
import 'package:dharak_flutter/app/domain/books/repo.dart';
import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CitationRepository {
  final CitationService _citationService;

  CitationRepository(this._citationService);

  Future<CitationRM?> getDefinitionCitation(int dictRefId) {
    return _citationService.getDefinitionCitation(dictRefId);
  }

  Future<VerseCitationRM> getVerseCitation(int versePk) {
    return _citationService.getVerseCitation(versePk);
  }

  Future<CitationRM?> getChunkCitation(int chunkRefId) async {
    try {
      print('Requesting citation for chunk ID: $chunkRefId');
      
      // Get BooksRepository from dependency injection
      final booksRepo = Modular.get<BooksRepository>();
      
      // Call the new BooksRepository citation method
      final result = await booksRepo.getChunkCitation(chunkRefId: chunkRefId);
      
      if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
        // Convert BookChunkCitationRM to CitationRM
        final bookCitation = result.data!;
        final footnote = bookCitation.citeData.footnote;
        
        return CitationRM(
          apa: footnote,
          mla: footnote,
          harvard: footnote,
          chicago: footnote,
          vancouver: footnote,
        );
      } else {
        print('Failed to get chunk citation: ${result.message}');
        return null;
      }
    } catch (e) {
      print('Error fetching chunk citation: $e');
      return null;
    }
  }
}