import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/user_profile.dart';

/// Encapsule tous les appels Supabase liés au profil utilisateur.
/// Aucune UI ne doit importer `supabase_flutter` directement : tout passe par ici.
///
/// ⚠️ Suppose une table `users` avec colonnes full_name, email, avatar_url,
/// bio, role, class_id -> classes(name), current_level_id -> levels(name),
/// et une table `user_skills(user_id, validated bool)`. Adapter les noms
/// ci-dessous si ton schéma diffère.
class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<UserProfile> fetchProfile() async {
    try {
      final uid = _client.auth.currentUser!.id;
      final row = await _client
          .from('users')
          .select(
            'id, full_name, email, avatar_url, bio, role, '
            'classes:class_id(name), levels:current_level_id(name)',
          )
          .eq('id', uid)
          .single();
      return UserProfile.fromMap(row);
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<void> updateProfile({required String fullName, String? bio}) async {
    try {
      final uid = _client.auth.currentUser!.id;
      await _client
          .from('users')
          .update({'full_name': fullName, 'bio': bio})
          .eq('id', uid);
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  /// Envoie l'image dans le bucket Storage `avatars` (à créer côté Supabase,
  /// public en lecture) puis enregistre l'URL sur le profil.
  Future<String> uploadAvatar(Uint8List bytes, String fileExtension) async {
    try {
      final uid = _client.auth.currentUser!.id;
      final path = '$uid/avatar.$fileExtension';

      await _client.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _client.storage.from('avatars').getPublicUrl(path);
      await _client.from('users').update({'avatar_url': url}).eq('id', uid);
      return url;
    } on StorageException catch (e) {
      throw Failure(e.message);
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<ProfileStats> fetchStats() async {
    try {
      final uid = _client.auth.currentUser!.id;
      final validated = await _client
          .from('user_skills')
          .select('id')
          .eq('user_id', uid)
          .eq('validated', true)
          .count(CountOption.exact);

      return ProfileStats(skillsValidated: validated.count);
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
