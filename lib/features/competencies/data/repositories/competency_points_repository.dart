import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';

enum CompetencyPointCategory {
  realisation,
  comprehensionExercice,
  miniHackathon,
}

extension CompetencyPointCategoryLabel on CompetencyPointCategory {
  String get label {
    switch (this) {
      case CompetencyPointCategory.realisation:
        return 'Réalisation';
      case CompetencyPointCategory.comprehensionExercice:
        return 'Compréhension d’exercice';
      case CompetencyPointCategory.miniHackathon:
        return 'Mini-hackathon';
    }
  }

  String get databaseValue {
    switch (this) {
      case CompetencyPointCategory.realisation:
        return 'realisation';
      case CompetencyPointCategory.comprehensionExercice:
        return 'comprehension_exercice';
      case CompetencyPointCategory.miniHackathon:
        return 'mini_hackathon';
    }
  }
}

class CompetencyPointsRepository {
  final SupabaseClient _client;

  CompetencyPointsRepository(this._client);

  Future<List<CompetencyPoint>> getForStudent(String studentId) async {
    try {
      final rows = await _client
          .from('competency_points')
          .select('id, category, points, commentaire, created_at')
          .eq('user_id', studentId)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((row) => CompetencyPoint.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<void> award({
    required String studentId,
    required String trainerId,
    required CompetencyPointCategory category,
    required int points,
    String? comment,
  }) async {
    try {
      await _client.from('competency_points').insert({
        'user_id': studentId,
        'trainer_id': trainerId,
        'category': category.databaseValue,
        'points': points,
        'commentaire': comment?.trim().isEmpty == true ? null : comment?.trim(),
      });
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }
}

class CompetencyPoint {
  final String id;
  final CompetencyPointCategory category;
  final int points;
  final String? comment;
  final DateTime createdAt;

  const CompetencyPoint({
    required this.id,
    required this.category,
    required this.points,
    required this.comment,
    required this.createdAt,
  });

  factory CompetencyPoint.fromJson(Map<String, dynamic> json) {
    final category = switch (json['category']) {
      'realisation' => CompetencyPointCategory.realisation,
      'comprehension_exercice' => CompetencyPointCategory.comprehensionExercice,
      _ => CompetencyPointCategory.miniHackathon,
    };
    return CompetencyPoint(
      id: json['id'] as String,
      category: category,
      points: json['points'] as int,
      comment: json['commentaire'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
