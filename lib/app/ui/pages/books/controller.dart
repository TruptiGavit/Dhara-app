import 'dart:async';

import 'package:dharak_flutter/app/domain/auth/auth_account_repo.dart';
import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/domain/books/repo.dart';
import 'package:dharak_flutter/app/types/books/chunk.dart';
import 'package:dharak_flutter/app/types/user/user.dart';
import 'package:dharak_flutter/app/ui/pages/books/args.dart';
import 'package:dharak_flutter/app/ui/pages/books/cubit_states.dart';
import 'package:dharak_flutter/app/utils/util_string.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class BooksController extends Cubit<BooksCubitState> {
  var mLogger = Logger();

  final TextEditingController mSearchController = TextEditingController();

  final BooksRepository mBooksRepository;
  
  // 🚀 PERFORMANCE: Progressive rendering for instant UI
  List<BookChunkRM> _allChunks = [];
  List<BookChunkRM> _displayedChunks = [];
  Timer? _progressiveLoadingTimer;
  static const int _batchSize = 5; // Show 5 chunks at a time
  static const Duration _batchDelay = Duration(milliseconds: 300); // Optimal batching speed
  final AuthAccountRepository mAuthAccountRepository;

  StreamSubscription<UserRM?>? _mAccountCommonSubscription;
  StreamSubscription<String>? _mSearchQuerySubscription;

  Timer? _mSearchDebounce;

  // ===== CACHE SUBSCRIPTIONS =====
  StreamSubscription<BookChunksResponseRM?>? _mCachedChunksSubscription;
  StreamSubscription<String>? _mCachedWordSubscription;

  BooksController({
    required this.mAuthAccountRepository,
    required this.mBooksRepository,
  }) : super(
         BooksCubitState(),
       ) {
    _formCreate();
  }

  @override
  Future<void> close() {
    _mAccountCommonSubscription?.cancel();
    _mSearchQuerySubscription?.cancel();
    
    // Cancel cache subscriptions
    _mCachedChunksSubscription?.cancel();
    _mCachedWordSubscription?.cancel();

    mSearchController.dispose();
    _mSearchDebounce?.cancel();
    _progressiveLoadingTimer?.cancel(); // 🚀 PERFORMANCE: Cleanup progressive timer
    return super.close();
  }

  Future<void> initData(BooksArgsRequest args) async {
    _subscribeBloc();
    
    // Handle preloaded data if provided (for unified search)
    if (args.preloadedChunks != null) {
      mLogger.d("BooksController: Using preloaded chunks data");
      emit(state.copyWith(
        booksResponse: args.preloadedChunks,
        bookChunks: args.preloadedChunks!.data,
        searchCounter: state.searchCounter + 1,
      ));
    } else {
      _restoreFromCache();
    }
  }

  void _subscribeBloc() {
    _mSearchQuerySubscription = mBooksRepository.mEventSearchQuery.listen(
      (value) {
        onSearchDirectQuery(value);
      },
    );

    // ===== CACHE SUBSCRIPTIONS =====
    // Subscribe to cached chunk results - automatically restores state when switching back to this tab
    _mCachedChunksSubscription = mBooksRepository.mChunkResultsObservable.listen((cachedChunks) {
      // Only update if we don't already have these chunks (avoid infinite loops)
      if (cachedChunks != null && 
          (state.booksResponse == null || 
           state.booksResponse != cachedChunks)) {
        
        
        // 🚀 PERFORMANCE: Apply progressive loading to cached results too
        _allChunks = cachedChunks.data;
        _displayedChunks.clear();
        
        if (_allChunks.isNotEmpty) {
          // Show first batch immediately
          final firstBatch = _allChunks.take(_batchSize).toList();
          _displayedChunks.addAll(firstBatch);
          
          emit(state.copyWith(
            booksResponse: cachedChunks,
            bookChunks: _displayedChunks,
            searchCounter: state.searchCounter + 1,
          ));
          
          _startProgressiveLoading();
        } else {
          emit(state.copyWith(
            booksResponse: cachedChunks,
            bookChunks: [],
            searchCounter: state.searchCounter + 1,
          ));
        }
      }
    });

    // Subscribe to cached search word - restores search field when switching back
    _mCachedWordSubscription = mBooksRepository.mCurrentSearchWordObservable.listen((cachedWord) {
      if (cachedWord.isNotEmpty && state.formSearchText != cachedWord) {
        
        // Update text controller without triggering new search
        mSearchController.value = TextEditingValue(
          text: cachedWord,
          selection: TextSelection.fromPosition(TextPosition(offset: cachedWord.length)),
        );
        
        emit(state.copyWith(
          formSearchText: cachedWord,
          searchQuery: cachedWord,
        ));
      }
    });
  }

  /// Restore state from repository cache when controller is created
  void _restoreFromCache() {
    // Get current cached state
    final cachedWord = mBooksRepository.mCurrentSearchWordObservable.valueOrNull ?? '';
    final cachedChunks = mBooksRepository.mChunkResultsObservable.valueOrNull;
    
    if (cachedWord.isNotEmpty || cachedChunks != null) {
      
      // Restore search word and text field
      if (cachedWord.isNotEmpty) {
        mSearchController.value = TextEditingValue(
          text: cachedWord,
          selection: TextSelection.fromPosition(TextPosition(offset: cachedWord.length)),
        );
      }
      
      // Restore state
      // 🚀 PERFORMANCE: Apply progressive loading to manual cache restore too
      if (cachedChunks != null) {
        _allChunks = cachedChunks.data;
        _displayedChunks.clear();
        
        if (_allChunks.isNotEmpty) {
          final firstBatch = _allChunks.take(_batchSize).toList();
          _displayedChunks.addAll(firstBatch);
          
          emit(state.copyWith(
            formSearchText: cachedWord.isEmpty ? null : cachedWord,
            searchQuery: cachedWord.isEmpty ? null : cachedWord,
            booksResponse: cachedChunks,
            bookChunks: _displayedChunks,
            searchCounter: cachedWord.isNotEmpty ? state.searchCounter + 1 : state.searchCounter,
          ));
          
          _startProgressiveLoading();
        } else {
          emit(state.copyWith(
            formSearchText: cachedWord.isEmpty ? null : cachedWord,
            searchQuery: cachedWord.isEmpty ? null : cachedWord,
            booksResponse: cachedChunks,
            bookChunks: [],
            searchCounter: cachedWord.isNotEmpty ? state.searchCounter + 1 : state.searchCounter,
          ));
        }
      } else {
        emit(state.copyWith(
          formSearchText: cachedWord.isEmpty ? null : cachedWord,
          searchQuery: cachedWord.isEmpty ? null : cachedWord,
          searchCounter: cachedWord.isNotEmpty ? state.searchCounter + 1 : state.searchCounter,
        ));
      }
      
    }
  }

  onFormSearchTextChanged(String? text) {
    if (_mSearchDebounce?.isActive ?? false) _mSearchDebounce?.cancel();

    if (text == null) {
      mSearchController.clear();
    }

    emit(state.copyWith(formSearchText: text));
  }

  onSearchDirectQuery(String query) async {
    mSearchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.fromPosition(TextPosition(offset: query.length)),
    );
    emit(state.copyWith(formSearchText: query));

    await _loadChunks();
  }

  onFormSubmit() async {
    await _loadChunks();
  }

  /*          *************************************************************8
   *                      form
   */

  _formCreate() {

    stream.listen((value) {
      formValidate();
    });
  }

  formValidate() {
    var isValid = true;

    if (isValid) {
      isValid = formHasChanges();
    }

    emit(state.copyWith(isSubmitEnabled: isValid));
  }

  bool formHasChanges() {
    var hasChanges = false;
    if (!UtilString.isStringsEmpty(state.formSearchText) &&
        !UtilString.areStringsEqualOrNull(
          state.searchQuery,
          state.formSearchText,
        )) {
      return true;
    }

    return hasChanges;
  }

  /* **************************************************************************************
   *                                      domain 
   */

  Future<bool> _loadChunks() async {
    var searchQuery = state.formSearchText;

    if (searchQuery == null || searchQuery.trim().isEmpty) {
      return false;
    }
    
    emit(state.copyWith(isLoading: true));

    var result = await mBooksRepository.searchChunks(
      query: searchQuery.trim(),
    );

    // 🚀 PERFORMANCE: Combine loading=false with data update in single emit
    
    if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
      print("getChunks: ${result}");

      // 🚀 PERFORMANCE: Progressive rendering for instant UI
      _allChunks = result.data?.data ?? [];
      _displayedChunks.clear();
      
      if (_allChunks.isNotEmpty) {
        // Show first batch immediately for instant feedback
        final firstBatch = _allChunks.take(_batchSize).toList();
        _displayedChunks.addAll(firstBatch);
        
        // Emit initial state with first batch
        emit(
          state.copyWith(
            isLoading: false,
            booksResponse: result.data,
            searchCounter: state.searchCounter + 1,
            bookChunks: _displayedChunks,
            searchQuery: searchQuery,
          ),
        );
        
        print("getChunks instant: Showing ${_displayedChunks.length}/${_allChunks.length} chunks");
        
        // Start progressive loading for remaining chunks
        _startProgressiveLoading();
      } else {
        // No chunks case
        emit(
          state.copyWith(
            isLoading: false,
            booksResponse: result.data,
            searchCounter: state.searchCounter + 1,
            bookChunks: [],
            searchQuery: searchQuery,
          ),
        );
      }

      print("getChunks success: ${_allChunks.length} total chunks found");
      return true;
    } else if (result.status == DomainResultStatus.ERROR) {
      print("getChunks error: ");
      
      // Use simple error handling
      bool shouldShowToast = true;
      String errorMessage = result.message ?? 'An error occurred while searching books';
      
      // 🚀 PERFORMANCE: Include isLoading=false in error state too
      emit(
        state.copyWith(
          isLoading: false,
          message: errorMessage,
          toastCounter: shouldShowToast ? (state.toastCounter ?? 0) + 1 : state.toastCounter,
        ),
      );
      print("getChunks error message: ${result.message}");
    }
    print("getChunks final: ${result}");

    return false;
  }

  String getAllText() {
    if (state.bookChunks.isEmpty) return "";
    
    final StringBuffer buffer = StringBuffer();
    
    for (int i = 0; i < state.bookChunks.length; i++) {
      final chunk = state.bookChunks[i];
      
      // Add chunk number and separator
      buffer.writeln("━━━ Chunk ${i + 1} ━━━");
      buffer.writeln(chunk.text);
      buffer.writeln("Reference: ${chunk.reference}");
      
      // Add spacing between chunks (except for the last one)
      if (i < state.bookChunks.length - 1) {
        buffer.writeln();
        buffer.writeln();
      }
    }
    
    return buffer.toString();
  }

  // 🚀 PERFORMANCE: Progressive loading for smooth UI
  void _startProgressiveLoading() {
    _progressiveLoadingTimer?.cancel();
    
    if (_displayedChunks.length >= _allChunks.length) {
      print("Progressive loading: All chunks already displayed");
      return;
    }
    
    // Start immediately without SchedulerBinding to ensure it works
    _loadNextBatch();
  }
  
  void _loadNextBatch() {
    if (_displayedChunks.length >= _allChunks.length) {
      print("Progressive loading: Complete - ${_allChunks.length} chunks displayed");
      return;
    }
    
    // Calculate next batch
    final currentCount = _displayedChunks.length;
    final remainingCount = _allChunks.length - currentCount;
    final batchSize = remainingCount > _batchSize ? _batchSize : remainingCount;
    
    // Add next batch
    final nextBatch = _allChunks.skip(currentCount).take(batchSize).toList();
    _displayedChunks.addAll(nextBatch);
    
    print("Progressive loading: Added batch ${nextBatch.length}, total: ${_displayedChunks.length}/${_allChunks.length}");
    
    // Update UI with new batch - force new list instance to trigger BlocBuilder
    final newChunks = List<BookChunkRM>.from(_displayedChunks);
    print("Progressive loading: Emitting state with ${newChunks.length} chunks");
    emit(state.copyWith(
      bookChunks: newChunks,
      searchCounter: state.searchCounter + 1, // Force counter increment to trigger rebuild
    ));
    
    // Schedule next batch if needed
    if (_displayedChunks.length < _allChunks.length) {
      _progressiveLoadingTimer = Timer(_batchDelay, _loadNextBatch);
    }
  }
}





