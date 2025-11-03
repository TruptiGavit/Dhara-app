import 'package:dharak_flutter/app/ui/sections/auth/login/google/controller.dart';
import 'package:flutter_modular/flutter_modular.dart';

export 'constants.dart';

class UiAuthBinds {
  static Function bindControllers = (Injector i) {
    i.add(GoogleLoginController.new);
  };
}
