import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/repositories/trainer_repository.dart';
import '../../../auth/domain/providers/auth_provider.dart';

final trainerRepositoryProvider = Provider<TrainerRepository>((ref) {
  return TrainerRepository(ref.watch(supabaseClientProvider));
});

final trainerStudentsProvider = FutureProvider<List<StudentProfile>>((ref) {
  return ref.watch(trainerRepositoryProvider).getStudents();
});

final studentProfileProvider =
    FutureProvider.family<StudentProfile?, String>((ref, id) {
  return ref.watch(trainerRepositoryProvider).getStudent(id);
});

final trainerStudentCountProvider = FutureProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.watch(trainerRepositoryProvider).getStudentCountForTrainer(user.id);
});

final trainerUpcomingSessionCountProvider = FutureProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref
      .watch(trainerRepositoryProvider)
      .getUpcomingSessionCountForTrainer(user.id);
});
