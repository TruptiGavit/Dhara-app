
import 'package:dharak_flutter/app/ui/constants.dart';

class DashboardArgsRequest {
  String default1;
  DashboardArgsRequest({required this.default1});
}

class DashboardArgsResult {
  late int resultCode;
  int requestCode;
  String? message;
  
  int? purpose;

  DashboardArgsResult(
      {required this.resultCode,
      this.requestCode = UiConstants.REQUEST_CODE_DEFAULT,
      this.message, this.purpose});

  // fromMao
}
