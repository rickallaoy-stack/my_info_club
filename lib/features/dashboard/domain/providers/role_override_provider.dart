import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bascule locale : un membre qui connaît le code d'accès peut voir
/// la vue Formateur sans avoir de compte séparé.
/// ⚠️ Affichage uniquement — la vraie autorisation doit être vérifiée
/// côté Supabase (RLS) pour toute action sensible.
class FormateurModeNotifier extends StateNotifier<bool> {
  FormateurModeNotifier() : super(false);

  void unlock() => state = true;
  void lock() => state = false;
}

final formateurModeProvider =
    StateNotifierProvider<FormateurModeNotifier, bool>(
  (ref) => FormateurModeNotifier(),
);
