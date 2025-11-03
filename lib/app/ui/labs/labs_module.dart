
import 'package:dharak_flutter/app/app_module.dart';
import 'package:dharak_flutter/app/core_module.dart';
import 'package:dharak_flutter/app/ui/labs/labs_controller.dart';
import 'package:dharak_flutter/app/ui/labs/labs_page.dart';
import 'package:flutter_modular/flutter_modular.dart';
// import 'package:modular_bloc_bind/modular_bloc_bind.dart';

class LabsModule extends Module {
  // @override
  // final List<Bind> binds = [
  //   BlocBind.factory(
  //     (i) => LabsController(mAuthAccountRepo: i<AuthAccountRepository>()),
  //   ),

  // ];

  @override
  // TODO: implement imports
  List<Module> get imports => [
    CoreModule()
  ];

  @override
  void binds(i) {
    // i.add(BlocBind.factory((i) => LabsController()));
    //authApiRepo: i<AuthApiRepo>()
    i.add(LabsController.new);

    // i.add(LabsAuthController.new);

    // i.add()
  }

  @override
  void routes(r) {
    // r.child('/', child: (_) => BlocProvider(
    //     create: (_) => LabsController(),
    //     child:const LabsPage()));
    r.child('/', child: (_) => const LabsPage());
  }

}
