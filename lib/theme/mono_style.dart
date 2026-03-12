import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// Roboto Mono style for live counters and volume numbers.
abstract final class MonoStyle {
  static TextStyle number({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    return GoogleFonts.robotoMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
