import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';

class TrainerRepository {
  final SupabaseClient _client;

  TrainerRepository(this._client);

  Future<String?> _getTrainerSection(String trainerId) async {
    try {
      final row = await _client
          .from('users')
          .select('section')
          .eq('id', trainerId)
          .maybeSingle();
      return row?['section'] as String?;
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<List<StudentProfile>> getStudents() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final trainerSection = await _getTrainerSection(user.id);

      var query = _client
          .from('users')
          .select(
            'id, nom, prenom, email, role, class_id, current_level_id, section, '
            'levels(nom)',
          )
          .eq('role', 'member');

      // Filtrer par section du formateur si disponible
      if (trainerSection != null) {
        query = query.eq('section', trainerSection);
      }

      final rows = await query.order('nom');

      return (rows as List)
          .map((row) => StudentProfile.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<StudentProfile?> getStudent(String id) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final trainerSection = await _getTrainerSection(user.id);

      var query = _client
          .from('users')
          .select(
            'id, nom, prenom, email, role, class_id, current_level_id, section, '
            'levels(nom)',
          )
          .eq('id', id)
          .eq('role', 'member');

      if (trainerSection != null) {
        query = query.eq('section', trainerSection);
      }

      final row = await query.maybeSingle();

      return row == null ? null : StudentProfile.fromJson(row);
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<int> getStudentCountForTrainer(String trainerId) async {
    try {
      final trainerSection = await _getTrainerSection(trainerId);
      if (trainerSection == null) return 0;

      final response = await _client
          .from('users')
          .select('id')
          .eq('role', 'member')
          .eq('section', trainerSection)
          .count(CountOption.exact);

      return response.count;
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<int> getUpcomingSessionCountForTrainer(String trainerId) async {
    try {
      final classIds = await _getTrainerClassIds(trainerId);
      if (classIds.isEmpty) return 0;

      final now = DateTime.now().toIso8601String().split('T').first;
      final response = await _client
          .from('sessions')
          .select('id')
          .inFilter('class_id', classIds)
          .gte('date_seance', now)
          .count(CountOption.exact);

      return response.count;
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<List<String>> _getTrainerClassIds(String trainerId) async {
    try {
      final rows = await _client
          .from('class_trainers')
          .select('class_id')
          .eq('user_id', trainerId);

      return (rows as List).map((r) => r['class_id'] as String).toList();
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }
}

class StudentProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? classId;
  final String? currentLevelId;
  final String? currentLevelName;
  final String? section;

  const StudentProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.classId,
    this.currentLevelId,
    this.currentLevelName,
    this.section,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as String,
      firstName: json['prenom'] as String? ?? '',
      lastName: json['nom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      classId: json['class_id'] as String?,
      currentLevelId: json['current_level_id'] as String?,
      currentLevelName:
          (json['levels'] as Map<String, dynamic>?)?['nom'] as String?,
      section: json['section'] as String?,
    );
  }
}