import 'package:dharak_flutter/res/layouts/breakpoints.dart';
import 'package:flutter/material.dart';

@immutable
class AppThemeDisplay  {
  final double height; // = Colors.black;
  final double width; // = Colors.black;
  final BreakpointType breakpointType;

  final bool isSamllHeight;
  

   AppThemeDisplay({this.height = 0, this.width = 0,  this.isSamllHeight = false,}): breakpointType = Breakpoints.get(width);
}