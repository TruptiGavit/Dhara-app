import 'package:dharak_flutter/app/ui/constants.dart';

class Error404ArgsResult {
  late int resultCode;
  int requestCode;
  String? message;

  Error404ArgsResult(
      {required this.resultCode,
      this.requestCode = UiConstants.REQUEST_CODE_DEFAULT,
      this.message});

  // fromMao

}
