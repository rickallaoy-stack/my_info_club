import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/repositories/live_quiz_repository.dart';
import '../entities/live_quiz_entities.dart';

final liveQuizRepositoryProvider = Provider<LiveQuizRepository>((ref) {
  return LiveQuizRepository(ref.watch(supabaseClientProvider));
});

/// true si l'utilisateur courant peut déclencher un quiz (formateur/admin).
final isQuizStaffProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(liveQuizRepositoryProvider).fetchCurrentUserRole();
  return role == 'formateur' || role == 'admin';
});

/// Session live active, mise à jour en temps réel — null si aucun quiz
/// n'est en cours. C'est ce provider que l'overlay écoute pour ouvrir
/// le popup chez tout le monde.
final activeLiveQuizSessionProvider = StreamProvider<LiveQuizSession?>((ref) {
  return ref.watch(liveQuizRepositoryProvider).watchActiveSession();
});

/// Banque de quiz pour l'écran de déclenchement (formateur/admin).
final quizBankProvider = FutureProvider<List<Quiz>>((ref) {
  return ref.watch(liveQuizRepositoryProvider).fetchQuizBank();
});

/// Détail (questions + options) du quiz de la session active.
/// `.family` car l'id du quiz dépend de la session en cours.
final quizDetailProvider = FutureProvider.family<Quiz, String>((ref, quizId) {
  return ref.watch(liveQuizRepositoryProvider).fetchQuizDetail(quizId);
});
