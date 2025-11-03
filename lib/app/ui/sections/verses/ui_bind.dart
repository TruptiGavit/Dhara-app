
import 'package:dharak_flutter/app/ui/sections/verses/bookmarks/controller.dart';
// import 'package:common/bloc/helper.dart';
import 'package:flutter_modular/flutter_modular.dart';


// export 'constants.dart';

// export '/auth_cubit_controller.dart';
class UiVerseBinds {
  static Function bindControllers = (Injector i) {
    i.add(VerseBookmarksController.new);
    //  i.add(AuthRootCubitController.new, config: cubitConfig());
  };

}
