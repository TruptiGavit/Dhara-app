import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/app/types/books/chunk.dart';

class BooksArgsRequest {
  String default1;
  bool hideSearchBar;
  bool hideWelcomeMessage;
  BookChunksResponseRM? preloadedChunks;
  BooksArgsRequest({
    required this.default1, 
    this.hideSearchBar = false, 
    this.hideWelcomeMessage = false,
    this.preloadedChunks,
  });
}

class BooksArgsResult {
  late int resultCode;
  int requestCode;
  String? message;
  
  int? purpose;

  BooksArgsResult(
      {required this.resultCode,
      this.requestCode = UiConstants.REQUEST_CODE_DEFAULT,
      this.message, this.purpose});

  // fromMap
}

