import 'package:dharak_flutter/app/core_module.dart';
import 'package:dharak_flutter/app/ui/pages/books/args.dart';
import 'package:dharak_flutter/app/ui/pages/books/controller.dart';
import 'package:dharak_flutter/app/ui/pages/books/page.dart';
import 'package:flutter_modular/flutter_modular.dart';

class BooksModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.add(BooksController.new);
  }

  @override
  void routes(r) {
    r.child(
      '/',
      child: (_) => BooksPage(
        mRequestArgs: BooksArgsRequest(default1: "default1"),
      ),
    );
  }
}
