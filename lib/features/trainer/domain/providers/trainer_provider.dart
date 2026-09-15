import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/repositories/trainer_repository.dart';

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
