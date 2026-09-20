import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'club_section.dart';

/// Section active de l'utilisateur (null = pas encore choisie).
///
/// - Source de vérité : colonne `users.section` dans Supabase.
/// - Copie locale (par utilisateur) pour fonctionner hors ligne.
final sectionProvider =
    AsyncNotifierProvider<SectionController, ClubSection?>(SectionController.new);

class SectionController extends AsyncNotifier<ClubSection?> {
  static const _baseKey = 'club_section';

  SupabaseClient get _client => Supabase.instance.client;

  String _key(String? userId) => userId == null ? _baseKey : '$_baseKey:$userId';

  @override
  Future<ClubSection?> build() async {
    final startUserId = _client.auth.currentUser?.id;

    // Recharge la section quand l'utilisateur change (connexion / déconnexion).
    final sub = _client.auth.onAuthStateChange.listen((_) {
      if (_client.auth.currentUser?.id != startUserId) ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);

    final prefs = await SharedPreferences.getInstance();
    final local = ClubSection.fromSlug(prefs.getString(_key(startUserId)));
    if (startUserId == null) return local;

    try {
      final row = await _client
          .from('users')
          .select('section')
          .eq('id', startUserId)
          .maybeSingle();
      final remote = ClubSection.fromSlug(row?['section'] as String?);

      if (remote != null) {
        await prefs.setString(_key(startUserId), remote.slug);
        return remote;
      }
      // Choix fait hors ligne : on le synchronise maintenant.
      if (local != null) await _pushRemote(startUserId, local);
    } catch (e) {
      debugPrint('[SectionController.build] Erreur lecture section: $e');
      // Hors ligne ou colonne absente : on garde le choix local.
    }
    return local;
  }

  Future<void> select(ClubSection section) async {
    state = AsyncData(section);
    final userId = _client.auth.currentUser?.id;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), section.slug);

    if (userId != null) {
      try {
        await _pushRemote(userId, section);
      } catch (e) {
        debugPrint('[SectionController.select] Erreur écriture section: $e');
        // Sera resynchronisé au prochain démarrage.
      }
    }
  }

  Future<void> _pushRemote(String userId, ClubSection section) async {
    await _client
        .from('users')
        .update({'section': section.slug}).eq('id', userId);
  }
}