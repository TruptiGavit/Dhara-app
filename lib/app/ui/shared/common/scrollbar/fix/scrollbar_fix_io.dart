import 'package:flutter/material.dart';

class ScrollbarFix extends StatelessWidget {
  final Widget child;
  
  final Radius? radius;
  
  final bool? thumbVisibility;

  final ScrollController? scrollController;

  ScrollbarFix({
    // this.controller,
    required this.child, this.radius, this.thumbVisibility,
    this.scrollController
    // this.onPageSelected,
  }); //: super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    return Scrollbar(

              thumbVisibility: thumbVisibility,
              radius:radius,
              controller: scrollController,

      child: this.child
    );
  }

}
