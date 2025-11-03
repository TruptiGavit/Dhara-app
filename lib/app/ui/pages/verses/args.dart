
import 'package:dharak_flutter/app/ui/constants.dart';

class VersesArgsRequest {
  String default1;
  VersesArgsRequest({required this.default1});
}

class VersesArgsResult {
  late int resultCode;
  int requestCode;
  String? message;
  
  int? purpose;

  VersesArgsResult(
      {required this.resultCode,
      this.requestCode = UiConstants.REQUEST_CODE_DEFAULT,
      this.message, this.purpose});

  // fromMao
}
