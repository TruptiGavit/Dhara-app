import 'package:dharak_flutter/app/core_module.dart';
import 'package:dharak_flutter/app/ui/pages/verses/args.dart';
import 'package:dharak_flutter/app/ui/pages/verses/controller.dart';
import 'package:dharak_flutter/app/ui/pages/verses/page.dart';
import 'package:flutter_modular/flutter_modular.dart';

class VersesModule extends Module {
  // @override
  // final List<Bind> binds = [Bind.lazySingleton((i) => LandingCubitCubit()),];

  // @override
  // final List<ModularRoute> routes = [];

  @override
  List<Module> get imports => [CoreModule()];
    @override
  void binds(i) {

    i.add(VersesController.new);
    // i.add(BlocBind.factory((i) => LabsController()));
    // i.add(LabsController.new, config: cubitConfig());

    // i.add()
  }

  @override
  void routes(r) {
    r.child('/', child: (_) =>  VersesPage( mRequestArgs: VersesArgsRequest(default1: "default1"),
            ));
    // r.child('/', child: (_) => BlocProvider(
    //     create: (_) => LabsController(),
    //     child:const LabsPage()));
    // r.child('/', child: (_) => const LabsPage());
  }

}