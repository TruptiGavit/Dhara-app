import 'package:flutter_modular/flutter_modular.dart';
import 'plugin_search_page.dart';

/// Module for the plugin-based search page
/// This is just for testing the plugin system
class PluginSearchModule extends Module {
  @override
  List<Bind> get binds => [];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, args) => const PluginSearchPage()),
  ];
}


