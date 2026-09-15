import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  /// Les valeurs du fichier `.env` sont prioritaires pour le lancement local.
  /// `--dart-define` reste disponible pour la CI et les builds de production.
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing Flutter env: provide --dart-define=SUPABASE_URL=... and '
        '--dart-define=SUPABASE_ANON_KEY=... or use the VS Code launch config.',
      );
    }
  }
}
