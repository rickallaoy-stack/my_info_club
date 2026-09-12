class Env {
  Env._();

  /// À fournir via `--dart-define=SUPABASE_URL=...` (ne jamais committer les clés en dur).
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
