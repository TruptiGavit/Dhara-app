import 'dart:math';

import 'package:dharak_flutter/res/extensions/hex_color.dart';


class UtilString {
  static bool isColor(String? string1) {
    // print("isColor: ");
    if (string1 == null) {
      return false;
    }
    if (string1.isEmpty) {
      return false;
    }

    if (string1.trim().isEmpty) {
      return false;
    }

    try {
      HexColor.fromHex(string1);
    } catch (e) {
      return false;
    }
    // print("isColor:4");

    return true;
  }

  static bool isStringsEmpty(String? string1) {
    if (string1 == null || string1.isEmpty) {
      return true;
    }

    return false;
  }

  static bool areStringsEqualOrNull(String? string1, String? string2) {
    if (string1 != null && string2 != null) {
      return string1 == string2;
    }

    // var isString  string1?.isEmpty
    return (string1?.isEmpty ?? true) == (string2?.isEmpty ?? true);
  }

  static bool isInputStringsEqualOrAmount(String? string1, int? amount, {int factor = 100}) {

    // print("isInputStringsEqualOrAmount: ${string1} ${amount}");
    if (string1 != null && string1.isNotEmpty && amount != null) {
      int? parsedInt = int.tryParse(string1);

      if (parsedInt != null && parsedInt * 100 == amount) {
        
    // print("isInputStringsEqualOrAmount 1: ");
        return true;
      }
      
    // print("isInputStringsEqualOrAmount 2: ");
      return false;
    }
    // print("isInputStringsEqualOrAmount 3: ");

    return (string1?.isEmpty ?? true) == (amount == null || amount == 0);
  }

  static int? toAmount(String? string1, {int factor = 100}) {
    if (string1 != null && string1.isNotEmpty) {
      int? parsedInt = int.tryParse(string1);

      if (parsedInt != null) {
        return parsedInt * factor;
      }
    }

    return null;
  }

  static int? toInt(String? string1) {
    if (string1 != null && string1.isNotEmpty) {
      int? parsedInt = int.tryParse(string1);

      if (parsedInt != null) {
        return parsedInt;
      }
    }

    return null;
  }

  static String getCustomUniqueId() {
    const String pushChars =
        '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
    int lastPushTime = 0;
    List lastRandChars = [];
    int now = DateTime.now().millisecondsSinceEpoch;
    bool duplicateTime = (now == lastPushTime);
    lastPushTime = now;
    List timeStampChars = List<String>.filled(8, '0');
    for (int i = 7; i >= 0; i--) {
      timeStampChars[i] = pushChars[now % 64];
      now = (now / 64).floor();
    }
    if (now != 0) {
      print("Id should be unique");
    }
    String uniqueId = timeStampChars.join('');
    if (!duplicateTime) {
      for (int i = 0; i < 12; i++) {
        lastRandChars.add((Random().nextDouble() * 64).floor());
      }
    } else {
      int i = 0;
      for (int i = 11; i >= 0 && lastRandChars[i] == 63; i--) {
        lastRandChars[i] = 0;
      }
      lastRandChars[i]++;
    }
    for (int i = 0; i < 12; i++) {
      uniqueId += pushChars[lastRandChars[i]];
    }
    return uniqueId;
  }
}
