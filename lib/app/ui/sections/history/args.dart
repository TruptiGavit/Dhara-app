
import 'package:dharak_flutter/app/ui/constants.dart';

class SearchHistoryArgsRequest {
  final bool isForVerse;
  const SearchHistoryArgsRequest(
      {
      this.isForVerse = true});
}

class SearchHistoryArgsResult {
  late int resultCode;
  int requestCode;
  String? message;


String? searchQuery;
 
  int? purpose;

  SearchHistoryArgsResult(
      {required this.resultCode,
      this.requestCode = UiConstants.REQUEST_CODE_DEFAULT,
      this.searchQuery,
      this.message,
      this.purpose});

  // fromMao
}
