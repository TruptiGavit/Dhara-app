import 'package:dharak_flutter/app/ui/pages/search/complete_solution_demo.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CompleteSolutionModule extends Module {
  @override
  void routes(r) {
    r.child('/', child: (_) => const CompleteSolutionDemo());
  }
}


