
import 'package:flutter/widgets.dart';

class RouteObserverWithCallback extends NavigatorObserver {
  final Function(Route<dynamic>, Route<dynamic>?) onRouteChanged;
  // final Function(String path)? onTabsPathNotified;

  RouteObserverWithCallback( {required this.onRouteChanged});

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);

    print("didPush: ${route.settings.name}");
    onRouteChanged(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    
    print("didPop: ${route.settings.name}");
    onRouteChanged(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    
    print("didReplace: ${newRoute?.settings.name}");
    onRouteChanged(newRoute!, oldRoute);
  }



  
}