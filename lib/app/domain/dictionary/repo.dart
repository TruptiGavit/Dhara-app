
import 'package:dharak_flutter/app/data/remote/api/base/dto/error_dto.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/dictionary/api.dart';
import 'package:dharak_flutter/app/domain/base/domain_helper.dart';
import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/types/dictionary/word_definitions.dart';
import 'package:dharak_flutter/app/types/search-history/result.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

class DictionaryRepository extends Disposable {
  var mLogger = Logger();
  final DictionaryApiRepo mDictionaryApiRepo;


 
    final PublishSubject<String> _mEventSearchQuery = PublishSubject<String>();
  PublishSubject<String> get mEventSearchQuery => _mEventSearchQuery;

  DictionaryRepository({
    required this.mDictionaryApiRepo,
  });

  @override
  void dispose() {

    _mEventSearchQuery.close();
  }

    void initData() {

    
  }


  void onNewSearchQuery(String? searchQuery) {
    
    if(searchQuery==null)return;

    _mEventSearchQuery.sink.add(searchQuery);
  }


  Future<DomainResult<DictWordDefinitionsRM>> getDefinition({required String word}) async {

    
    return await domainCallBeforeSave<DictWordDefinitionsRM, DictWordDefinitionsRM, ErrorDto,
        DictWordDefinitionsRM>(
      networkCall: () async {
        return await mDictionaryApiRepo.getDefinition(word: word);
        // if(apiResponse.)
      },
      saveCallResult: (remoteData) {
       
        return Future.value(remoteData);
      },
      finalResult: (savedData) => savedData,
    );
  }

  Future<DomainResult<SearchHistoryResultRM>> getSearchHistory() async {
    
     return await domainCallBeforeSave<SearchHistoryResultRM, SearchHistoryResultRM, ErrorDto,
        SearchHistoryResultRM>(
      networkCall: () async {
        return await mDictionaryApiRepo.getSearchHistory();
      },
      saveCallResult: (remoteData) {
       
        return Future.value(remoteData);
      },
      finalResult: (savedData) => savedData,
    );
  }



}
