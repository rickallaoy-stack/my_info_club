import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/repositories/competency_points_repository.dart';

final competencyPointsRepositoryProvider =
    Provider<CompetencyPointsRepository>((ref) {
  return CompetencyPointsRepository(ref.watch(supabaseClientProvider));
});

final studentCompetencyPointsProvider =
    FutureProvider.family<List<CompetencyPoint>, String>((ref, studentId) {
  return ref.watch(competencyPointsRepositoryProvider).getForStudent(studentId);
});
