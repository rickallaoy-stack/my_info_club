import 'package:flutter/material.dart';

/// Palette de marque du Club Informatique.
/// Choix : indigo (sérieux, tech) + cyan (énergie, "signal") + ambre (accent ponctuel).
class AppColors {
  AppColors._();

  // Marque
  static const primary = Color(0xFF4F46E5); // Indigo électrique
  static const primaryContainer = Color(0xFFE0E7FF);
  static const onPrimaryContainer = Color(0xFF1E1B4B);

  static const secondary = Color(0xFF0891B2); // Cyan profond
  static const secondaryContainer = Color(0xFFCFFAFE);
  static const onSecondaryContainer = Color(0xFF083344);

  static const tertiary = Color(0xFFD97706); // Ambre — accents, badges, progression
  static const tertiaryContainer = Color(0xFFFEF3C7);
  static const onTertiaryContainer = Color(0xFF78350F);

  static const error = Color(0xFFDC2626);
  static const errorContainer = Color(0xFFFEE2E2);
  static const onErrorContainer = Color(0xFF7F1D1D);

  // Statuts (validation de compétences, remises)
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const pending = Color(0xFF64748B);

  // Neutres — thème clair
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF1F5F9);
  static const lightOutline = Color(0xFFCBD5E1);
  static const lightOnSurface = Color(0xFF0F172A);
  static const lightOnSurfaceVariant = Color(0xFF475569);

  // Neutres — thème sombre
  static const darkBackground = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF111827);
  static const darkSurfaceVariant = Color(0xFF1E293B);
  static const darkOutline = Color(0xFF334155);
  static const darkOnSurface = Color(0xFFE2E8F0);
  static const darkOnSurfaceVariant = Color(0xFF94A3B8);
}