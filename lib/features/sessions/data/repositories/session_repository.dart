import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';

class SessionRepository {
  final SupabaseClient _client;

  SessionRepository(this._client);

  Future<List<ClubSession>> getUpcomingForClass(String classId) async {
    try {
      final rows = await _client
          .from('sessions')
          .select('id, date_seance, type')
          .eq('class_id', classId)
          .gte('date_seance', DateTime.now().toIso8601String().split('T').first)
          .order('date_seance');

      return (rows as List)
          .map((row) => ClubSession.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }
}

class ClubSession {
  final String id;
  final DateTime date;
  final String type;

  const ClubSession({
    required this.id,
    required this.date,
    required this.type,
  });

  factory ClubSession.fromJson(Map<String, dynamic> json) {
    return ClubSession(
      id: json['id'] as String,
      date: DateTime.parse(json['date_seance'] as String),
      type: json['type'] as String? ?? 'cours',
    );
  }
}
