import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';

class TrainerRepository {
  final SupabaseClient _client;

  TrainerRepository(this._client);

  Future<List<StudentProfile>> getStudents() async {
    try {
      final rows = await _client
          .from('users')
          .select(
            'id, nom, prenom, email, role, class_id, current_level_id, '
            'levels(nom)',
          )
          .eq('role', 'member')
          .order('nom');

      return (rows as List)
          .map((row) => StudentProfile.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<StudentProfile?> getStudent(String id) async {
    try {
      final row = await _client
          .from('users')
          .select(
            'id, nom, prenom, email, role, class_id, current_level_id, '
            'levels(nom)',
          )
          .eq('id', id)
          .eq('role', 'member')
          .maybeSingle();

      return row == null ? null : StudentProfile.fromJson(row);
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

  const StudentProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.classId,
    this.currentLevelId,
    this.currentLevelName,
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
    );
  }
}
