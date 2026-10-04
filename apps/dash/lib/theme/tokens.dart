// KOEBELT design system tokens, ported 1:1 from `_ds/.../tokens/*.css`.
// Dark is the only surface; lime is the only saturated colour.
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

const fontArchivo = 'Archivo', fontMono = 'JetBrainsMono';

abstract final class K {
  // base neutrals
  static const white = Color(0xFFFFFFFF);
  static const ink025 = Color(0xFFE8E5E4);
  static const ink050 = Color(0xFFDAD6D5);
  static const ink100 = Color(0xFFB8B3B1);
  static const ink200 = Color(0xFF8C8685);
  static const ink300 = Color(0xFF625C5B);
  static const ink400 = Color(0xFF443F40);
  static const ink500 = Color(0xFF2E2B2C);
  static const ink600 = Color(0xFF262324);
  static const ink700 = Color(0xFF1D1A1B);
  static const ink800 = Color(0xFF161415);
  static const ink900 = Color(0xFF0D0C0C);
  static const ink950 = Color(0xFF060505);

  // accent
  static const lime100 = Color(0xFFF4FDC6);
  static const lime300 = Color(0xFFE4FC6D);
  static const lime500 = Color(0xFFDCFB47);
  static const lime600 = Color(0xFFCDEC2A);
  static const lime900 = Color(0xFF6E8110);

  // signals
  static const positive = Color(0xFF8FDC9B);
  static const warning = Color(0xFFEFC067);
  static const negative = Color(0xFFEE7A63);
  static const info = Color(0xFF8FB9E0);

  // alpha utilities
  static const whiteA06 = Color(0x0FFFFFFF);
  static const whiteA08 = Color(0x14FFFFFF);
  static const whiteA12 = Color(0x1FFFFFFF);
  static const whiteA20 = Color(0x33FFFFFF);
  static const whiteA60 = Color(0x99FFFFFF);
  static const inkA40 = Color(0x660D0C0C);
  static const inkA55 = Color(0x8C0D0C0C);
  static const inkA60 = Color(0x990D0C0C);
  static const inkA62 = Color(0x9E0D0C0C);
  static const inkA70 = Color(0xB30D0C0C);
  static const limeA16 = Color(0x29DCFB47);
  static const limeA32 = Color(0x52DCFB47);

  // semantic
  static const surfacePage = ink800;
  static const surfaceSunken = ink900;
  static const surfaceDeep = ink950;
  static const surfaceRaised = ink700;
  static const surfaceHover = ink600;
  static const surfaceInverse = white;
  static const surfaceAccentSoft = limeA16;

  static const textPrimary = white;
  static const textSecondary = ink100;
  static const textMuted = ink200;
  static const textFaint = ink300;
  static const textInverse = ink700;
  static const textAccent = lime500;
  static const textOnAccent = ink800;

  static const borderHairline = whiteA12;
  static const borderSubtle = whiteA20;
  static const borderStrong = ink100;

  static const accent = lime500;
  static const accentHover = lime300;
  static const accentPress = lime600;

  static const scrim = Color(0xB80D0C0C);

  // radius
  static const radiusControl = 2.0;
  static const radiusCard = 4.0;
  static const radiusPill = 999.0;

  // spacing (2px base)
  static const s1 = 2.0, s2 = 4.0, s3 = 8.0, s4 = 12.0, s5 = 16.0, s6 = 20.0;
  static const s7 = 24.0, s8 = 32.0, s9 = 40.0, s10 = 56.0;

  // motion
  static const durFast = Duration(milliseconds: 140);
  static const durBase = Duration(milliseconds: 220);
  static const easeStandard = Cubic(.2, .8, .2, 1);
  static const pressScale = 0.985;

  static const shadowOverlay = [BoxShadow(color: Color(0x8C000000), offset: Offset(0, 24), blurRadius: 64)];

  // typography
  static const trLabel = 0.14; // em
  static const trHeading = -0.02;
  static const trDisplay = -0.035;
}

/// Text styles. Archivo for display/body, JetBrains Mono for every label.
abstract final class KText {
  static TextStyle display({double size = 40, FontWeight w = FontWeight.w600, Color? color, double height = 0.94}) =>
      TextStyle(fontFamily: fontArchivo, fontSize: size, fontWeight: w, height: height, letterSpacing: size * K.trDisplay, color: color ?? K.textPrimary);

  static TextStyle archivo(double size, FontWeight w, double height, {Color? color, double tracking = -0.005}) =>
      TextStyle(fontFamily: fontArchivo, fontSize: size, fontWeight: w, height: height, letterSpacing: size * tracking, color: color ?? K.textPrimary);

  static TextStyle mono(double size, {FontWeight w = FontWeight.w500, Color? color, double tracking = 0, double height = 1}) =>
      TextStyle(fontFamily: fontMono, fontSize: size, fontWeight: w, height: height, letterSpacing: size * tracking, color: color ?? K.textPrimary);

  static TextStyle get headingLg => archivo(40, FontWeight.w600, 1.1, tracking: K.trHeading);
  static TextStyle get headingMd => archivo(32, FontWeight.w600, 1.1, tracking: K.trHeading);
  static TextStyle get headingSm => archivo(24, FontWeight.w600, 1.2, tracking: K.trHeading);
  static TextStyle get headingXs => archivo(20, FontWeight.w500, 1.2, tracking: K.trHeading);
  static TextStyle get bodyLg => archivo(18, FontWeight.w400, 1.55);
  static TextStyle get bodyMd => archivo(16, FontWeight.w400, 1.55);
  static TextStyle get bodySm => archivo(14, FontWeight.w400, 1.55);

  /// `.mono-label`: 11px uppercase mono, 0.14em tracking, muted.
  static TextStyle label({double size = 11, Color? color, double height = 1}) => mono(size, color: color ?? K.textMuted, tracking: K.trLabel, height: height);
  static TextStyle labelMd({Color? color}) => mono(13, color: color ?? K.textPrimary, tracking: K.trLabel);
}
