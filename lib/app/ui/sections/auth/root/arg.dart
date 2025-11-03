
import 'package:dharak_flutter/app/ui/constants.dart';

class AuthRootArgsRequest {
  int purpose;
  // String? googleIdToken;
  AuthRootArgsRequest({required this.purpose});
}


class AuthRootArgsResult{

  late int resultCode;
  int requestCode;
  String? message;
  
  String?  id;

  AuthRootArgsResult({ required this.resultCode, 
  this.requestCode = UiConstants.REQUEST_CODE_DEFAULT, 
  this.message, this.id});

  // fromMao

}