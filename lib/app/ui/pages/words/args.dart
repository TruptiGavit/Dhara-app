
import 'package:dharak_flutter/app/ui/constants.dart';

class WordDefineArgsRequest {
  String default1;
  WordDefineArgsRequest({required this.default1});
}

class WordDefineArgsResult {
  late int resultCode;
  int requestCode;
  String? message;
  
  int? purpose;

  WordDefineArgsResult(
      {required this.resultCode,
      this.requestCode = UiConstants.REQUEST_CODE_DEFAULT,
      this.message, this.purpose});

  // fromMao
}
