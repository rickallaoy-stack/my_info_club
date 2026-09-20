import 'package:flutter/material.dart';

import 'club_section.dart';

/// Couleur d'accent de la section, ajustée pour rester lisible
/// en thème clair comme en thème sombre.
Color sectionAccent(ClubSection section, Brightness brightness) {
  final hsl = HSLColor.fromColor(section.accent);
  return hsl
      .withLightness(brightness == Brightness.dark ? 0.62 : 0.40)
      .toColor();
}

/// Reprend ton thème actuel et remplace uniquement les couleurs d'accent.
/// Sans section choisie, le thème reste inchangé.
ThemeData buildSectionTheme(ThemeData base, ClubSection? section) {
  if (section == null) return base;

  final accent = sectionAccent(section, base.brightness);
  final onAccent =
      ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
          ? Colors.white
          : const Color(0xFF0D2240);

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: accent,
      onPrimary: onAccent,
      secondary: accent,
      onSecondary: onAccent,
    ),
  );
}
