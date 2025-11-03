import 'package:dharak_flutter/app/ui/sections/books/bookmarks/controller.dart';
import 'package:dharak_flutter/app/ui/pages/books/controller.dart';
import 'package:flutter_modular/flutter_modular.dart';

class UiBooksBinds {
  static Function bindControllers = (Injector i) {
    i.add(BookChunkBookmarksController.new);
    i.add(BooksController.new);
  };
}



