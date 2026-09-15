import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

/// Stream de l'état d'auth Supabase — utilisé par le router pour rediriger
/// automatiquement entre /login et /dashboard.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Utilisateur actuellement connecté (null si déconnecté).
final currentUserProvider = Provider<User?>((ref) {
  // On dépend du stream pour se recalculer à chaque changement d'état.
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).currentUser;
});

final currentProfileProvider = FutureProvider<AuthProfile?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).getCurrentProfile();
});
