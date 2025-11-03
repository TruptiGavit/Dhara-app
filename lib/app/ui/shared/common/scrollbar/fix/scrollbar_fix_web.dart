import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ScrollbarFix extends StatelessWidget {
  final Widget child;

  final Radius? radius;
  
  final bool? thumbVisibility;
  final ScrollController? scrollController;
  ScrollbarFix({
    required this.child, this.radius, this.thumbVisibility,
    this.scrollController
  }); 

  @override
  Widget build(BuildContext context) {
    return this.child;
  }

}
