import 'package:flutter/widgets.dart';

class TdResColors {
  static double alpha(TdResColorEmphasize emphasize) {
    switch (emphasize) {
      case TdResColorEmphasize.original:
        return 1;

      case TdResColorEmphasize.medium:
        return 0.6;

      case TdResColorEmphasize.high:
        return 0.85;

      case TdResColorEmphasize.lowest:
        return 0.05;
      case TdResColorEmphasize.disabled:
        return 0.3;

      default:
        return 0.04;
    }
  }

  static Color invert(Color color) {
    final r = 255 - color.red;
    final g = 255 - color.green;
    final b = 255 - color.blue;

    return Color.fromARGB((color.opacity * 255).round(), r, g, b);
  }

  
  static const Color colorPrimary40 = Color(0xFF189565);
  //13296c Color(0xFF03865F);
  static const Color colorSecondary20 = Color(0xFF660A03);
  static const Color colorSecondary30 = Color(0xFFA30505);
  static const Color colorSecondary50 = Color(0xFFF9140C);
  static const Color colorSecondary70 = Color(0xFFFF4B45);
  static const Color colorTertiary40 = Color(0xFFC70528);
  static const Color colorSecondary80 = Color(0xFFE9A08E);

  // Dhara brand colors
  static const Color colorDharaBlue = Color(0xFF1565C0);
  static const Color colorDutchOrange = Color(0xFFFF6B35); // Dutch orange for Shodh
  
  static const Color colorInput = Color(0xFFA2431D);
  static const Color colorSuccess = Color(0xFF039241);
 
}

enum TdResColorEmphasize { lowest, disabled, medium, high, original }