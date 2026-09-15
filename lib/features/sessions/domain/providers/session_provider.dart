import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/repositories/session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(supabaseClientProvider));
});

final upcomingSessionsProvider =
    FutureProvider.family<List<ClubSession>, String>((ref, classId) {
  return ref.watch(sessionRepositoryProvider).getUpcomingForClass(classId);
});
