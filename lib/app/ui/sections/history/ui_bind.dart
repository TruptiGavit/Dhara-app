
import 'package:dharak_flutter/app/ui/sections/history/controller.dart';
// import 'package:common/bloc/helper.dart';
import 'package:flutter_modular/flutter_modular.dart';


class UiHistoryBinds {
  static Function bindControllers = (Injector i) {
    i.add(SearchHistoryController.new);
  };

}
