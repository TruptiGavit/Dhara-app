import 'package:dharak_flutter/app/core_module.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/args.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/controller.dart';
import 'package:dharak_flutter/app/ui/pages/prashna/page.dart';
import 'package:dharak_flutter/app/ui/pages/verses/controller.dart';
import 'package:dharak_flutter/app/ui/pages/words/controller.dart';
import 'package:flutter_modular/flutter_modular.dart';

class PrashnaModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.add(PrashnaController.new);
    // Add controllers for full functionality in embedded content
    i.add(VersesController.new);
    i.add(WordDefineController.new);
  }

  @override
  void routes(r) {
    r.child(
      '/',
      child: (_) => PrashnaPage(
        mRequestArgs: PrashnaArgsRequest(default1: "default1"),
      ),
    );
  }
}




