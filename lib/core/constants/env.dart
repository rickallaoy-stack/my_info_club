import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  static Map<String, String> get _dotenvMap {
    try {
      return dotenv.env;
    } catch (_) {
      return const {};
    }
  }

  /// Les valeurs du fichier `.env` sont prioritaires pour le lancement local.
  /// `--dart-define` reste disponible pour la CI et les builds de production.
  static String get supabaseUrl =>
      _dotenvMap['SUPABASE_URL'] ??
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static String get supabaseAnonKey =>
      _dotenvMap['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get hasRequiredConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  /// Code local pour débloquer temporairement la vue Formateur.
  /// Uniquement un filtre d'affichage — pas une vraie autorisation serveur.
  static const trainerAccessCode =
      String.fromEnvironment('TRAINER_ACCESS_CODE', defaultValue: '');

  static bool validateOrWarn() {
    if (!hasRequiredConfig) {
      debugPrint(
        'Missing Flutter env: provide --dart-define=SUPABASE_URL=... and '
        '--dart-define=SUPABASE_ANON_KEY=... or use the VS Code launch config.',
      );
      return false;
    }
    return true;
  }

  static void validate() {
    if (!hasRequiredConfig) {
      throw StateError(
        'Missing Flutter env: provide --dart-define=SUPABASE_URL=... and '
        '--dart-define=SUPABASE_ANON_KEY=... or use the VS Code launch config.',
      );
    }
  }
}

