import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
      // TODO: harmoniser avec la charte visuelle du club une fois définie.
    );
  }
}
