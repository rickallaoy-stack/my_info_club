import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sora pour les titres (look technique), Inter pour le corps (lisibilité en dashboard dense).
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color onSurface, Color onSurfaceVariant) {
    final display = GoogleFonts.sora(color: onSurface, fontWeight: FontWeight.w600);
    final body = GoogleFonts.inter(color: onSurface);
    final bodyMuted = GoogleFonts.inter(color: onSurfaceVariant);

    return TextTheme(
      displayLarge: display.copyWith(fontSize: 40, letterSpacing: -0.5),
      displayMedium: display.copyWith(fontSize: 32, letterSpacing: -0.5),
      displaySmall: display.copyWith(fontSize: 28, letterSpacing: -0.25),
      headlineLarge: display.copyWith(fontSize: 26),
      headlineMedium: display.copyWith(fontSize: 22),
      headlineSmall: display.copyWith(fontSize: 20),
      titleLarge: display.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: body.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: body.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: body.copyWith(fontSize: 14, height: 1.5),
      bodySmall: bodyMuted.copyWith(fontSize: 12, height: 1.4),
      labelLarge: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: bodyMuted.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: bodyMuted.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
    );
  }
}