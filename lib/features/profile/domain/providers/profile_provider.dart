import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/repositories/profile_repository.dart';
import '../entities/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

/// `autoDispose` volontairement absent : le profil reste en cache tant que
/// l'utilisateur est connecté. Après une modification, on appelle
/// `ref.invalidate(userProfileProvider)` pour le rafraîchir.
final userProfileProvider = FutureProvider<UserProfile>((ref) {
  return ref.watch(profileRepositoryProvider).fetchProfile();
});

final profileStatsProvider = FutureProvider((ref) {
  return ref.watch(profileRepositoryProvider).fetchStats();
});
