import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
// import 'package:hundi_flutter/res/colors.dart';
// import 'package:hundi_flutter/res/dimens.dart';

class TdResTextStyles {
  static const _light = FontWeight.w300;
  static const _regular = FontWeight.w400;
  static const _medium = FontWeight.w500;
  static const _semiBold = FontWeight.w600;
  static const _bold = FontWeight.w700;
  static const _bolder = FontWeight.w800;
  static const _black = FontWeight.w900;

  static const TextStyle textLight = TextStyle(
    fontWeight: _light,
  );

  static const TextStyle textNormal = TextStyle(
    fontWeight: _regular,
  );

  static const TextStyle textMedium = TextStyle(
    fontWeight: _medium,
  );

  static const TextStyle textSemiBold = TextStyle(
    fontWeight: _semiBold,
  );

  static const TextStyle textBold = TextStyle(
    fontWeight: _bold,
  );

  static const TextStyle textBolder = TextStyle(
    fontWeight: _bolder,
  );

  static const TextStyle textBlack = TextStyle(
    fontWeight: _black,
  );

  static final TextStyle l1 =
      GoogleFonts.plusJakartaSans(textStyle: textMedium, fontSize: 76);

  static final TextStyle l1Bold =
      GoogleFonts.plusJakartaSans(textStyle: textBold, fontSize: 76);

  static final TextStyle l3Bold =
      GoogleFonts.plusJakartaSans(textStyle: textBold, fontSize: 46);

  static final TextStyle l2Bold =
      GoogleFonts.plusJakartaSans(textStyle: textBold, fontSize: 64);

  static final TextStyle h0Bold =
      GoogleFonts.notoSans(textStyle: textBold, fontSize: 48);

  static final TextStyle h1 =
      GoogleFonts.albertSans(textStyle: textMedium, fontSize: 36);

  static final TextStyle h1SemiBold =
      GoogleFonts.albertSans(textStyle: textSemiBold, fontSize: 36);

  static final TextStyle h1Bold =
      GoogleFonts.albertSans(textStyle: textBold, fontSize: 36);
  // textMedium.copyWith();

  static final TextStyle h2 =
      GoogleFonts.albertSans(textStyle: textMedium, fontSize: 28);

  static final TextStyle h2Medium =
      GoogleFonts.albertSans(textStyle: textMedium, fontSize: 28);
  static final TextStyle h2SemiBold =
      GoogleFonts.albertSans(textStyle: textSemiBold, fontSize: 28);
  static final TextStyle h2Bold =
      GoogleFonts.albertSans(textStyle: textBold, fontSize: 28);

  static final TextStyle h3 =
      GoogleFonts.notoSans(textStyle: textNormal, fontSize: 22);

  static final TextStyle h3Medium =
      GoogleFonts.notoSans(textStyle: textMedium, fontSize: 22);

  static final TextStyle h3Bold =
      GoogleFonts.notoSans(textStyle: textBold, fontSize: 22);

  static final TextStyle h35Bold =
      GoogleFonts.notoSans(textStyle: textBold, fontSize: 20);

  static final TextStyle h4 =
      GoogleFonts.notoSans(textStyle: textNormal, fontSize: 18);

  static final TextStyle h4Medium =
      GoogleFonts.notoSans(textStyle: textMedium, fontSize: 18);

  static final TextStyle h4Bold =
      GoogleFonts.notoSans(textStyle: textBold, fontSize: 18);

  static final TextStyle h5 = GoogleFonts.notoSans(
      textStyle: textNormal,
      height: 1.4,
      textBaseline: TextBaseline.ideographic,
      fontSize: 16);

  static final TextStyle h5Medium = GoogleFonts.notoSans(
      textStyle: textMedium,
      height: 1.4,
      textBaseline: TextBaseline.ideographic,
      fontSize: 16);

  static final TextStyle h5SemiBold = GoogleFonts.notoSans(
      textStyle: textSemiBold,
      height: 1.4,
      textBaseline: TextBaseline.ideographic,
      fontSize: 16);

  static final TextStyle h5Bold = GoogleFonts.notoSans(
      textStyle: textBold,
      height: 1.4,
      textBaseline: TextBaseline.ideographic,
      fontSize: 16);

  static final TextStyle h6 =
      GoogleFonts.notoSans(textStyle: textNormal, fontSize: 15);

  static final TextStyle h6Medium =
      GoogleFonts.notoSans(textStyle: textMedium, fontSize: 14);

  static final TextStyle p1 =
      GoogleFonts.notoSans(textStyle: textNormal, fontSize: 18);
  static final TextStyle p1Medium =
      GoogleFonts.notoSans(textStyle: textMedium, fontSize: 18);

  static final TextStyle p2 =
      GoogleFonts.notoSans(textStyle: textNormal, fontSize: 15);

  static final TextStyle p3 =
      GoogleFonts.notoSans(textStyle: textNormal, fontSize: 13);
  static final TextStyle p3Medium =
      GoogleFonts.notoSans(textStyle: textMedium, fontSize: 13);

  static final TextStyle button =
      GoogleFonts.notoSans(textStyle: textMedium, fontSize: 16);

  static final TextStyle buttonSmall =
      GoogleFonts.notoSans(textStyle: textNormal, fontSize: 14);

  static final TextStyle caption =
      GoogleFonts.notoSans(textStyle: textNormal, fontSize: 12);

  static final TextStyle captionMedium =
      GoogleFonts.notoSans(textStyle: textMedium, fontSize: 12);
}
