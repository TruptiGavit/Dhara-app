import 'package:dharak_flutter/app/ui/constants.dart';

class BookChunkBookmarksArgsRequest {
  
  BookChunkBookmarksArgsRequest();
}

class BookChunkBookmarksArgsResult {
  int resultCode;
  String? message;
  int? purpose;

  BookChunkBookmarksArgsResult({
    this.resultCode = 2, // UiConstants.BundleArgs.resultCanceled
    this.message,
    this.purpose,
  });
}
