import 'dart:ui';

import 'package:flutter/widgets.dart';

class UtilColor {
  /**
   * For human name
   */
  static Color colorFor(String text) {
    var hash = 0;
    print("colorFor $text");
    for (var i = 0; i < text.length; i++) {
      print("colorFor ${text.codeUnitAt(i)} ${text.codeUnitAt(i) ~/ 2}");
      hash = text.codeUnitAt(i) ~/ 2 + ((hash << 5) - hash);
    }
    print("colorFor: $hash ");
    final finalHash = hash.abs() % (256 * 256 * 256);
    print("colorFor: $finalHash");
    final red = ((finalHash & 0xFF0000) >> 16);
    final blue = ((finalHash & 0xFF00) >> 8);
    final green = ((finalHash & 0xFF));
    final color = Color.fromRGBO(red, green, blue, 1);
    return color;
  }

  static Color darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  static Color lighten(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }
}
