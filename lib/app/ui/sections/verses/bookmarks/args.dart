
import 'package:dharak_flutter/app/ui/constants.dart';

class VerseBookmarksArgsRequest {
  final String default1;
  const VerseBookmarksArgsRequest(
      {
      this.default1 = ""});
}

class VerseBookmarksArgsResult {
  late int resultCode;
  int requestCode;
  String? message;

 
  int? purpose;

  VerseBookmarksArgsResult(
      {required this.resultCode,
      this.requestCode = UiConstants.REQUEST_CODE_DEFAULT,
      this.message,
      this.purpose});

  // fromMao
}
