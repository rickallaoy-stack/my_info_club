import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/live_quiz_entities.dart';

/// Encapsule tous les appels Supabase liés au quiz live.
/// Aucune UI ne doit importer `supabase_flutter` directement : tout passe par ici.
class LiveQuizRepository {
  final SupabaseClient _client;

  LiveQuizRepository(this._client);

  /// Banque de quiz pour le picker formateur/admin (sans les questions,
  /// pour rester léger).
  Future<List<Quiz>> fetchQuizBank() async {
    try {
      final rows = await _client
          .from('quizzes')
          .select('id, title, description')
          .order('created_at', ascending: false);
      return (rows as List).map((r) => Quiz.fromMap(r as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  /// Quiz complet (questions + options) pour l'affichage du popup.
  Future<Quiz> fetchQuizDetail(String quizId) async {
    try {
      final row = await _client
          .from('quizzes')
          .select('id, title, description, quiz_questions(id, statement, position, quiz_options(id, label, is_correct))')
          .eq('id', quizId)
          .order('position', referencedTable: 'quiz_questions')
          .single();
      return Quiz.fromMap(row);
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  /// Déclenche le popup chez tout le monde : un simple insert, capté
  /// ensuite par Realtime sur tous les clients abonnés.
  Future<void> startLiveQuiz(String quizId) async {
    try {
      await _client.from('live_quiz_sessions').insert({
        'quiz_id': quizId,
        'started_by': _client.auth.currentUser!.id,
      });
    } on PostgrestException catch (e) {
      // code 23505 = violation de l'index unique "un seul quiz actif à la fois"
      if (e.code == '23505') {
        throw const Failure('Un quiz est déjà en cours. Ferme-le avant d\'en relancer un.');
      }
      throw Failure(e.message, code: e.code);
    }
  }

  Future<void> closeLiveQuiz(String sessionId) async {
    try {
      await _client
          .from('live_quiz_sessions')
          .update({'status': 'closed', 'closed_at': DateTime.now().toIso8601String()})
          .eq('id', sessionId);
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  /// Session active en direct — émet `null` dès qu'elle est fermée ou
  /// qu'aucune n'est en cours.
  Stream<LiveQuizSession?> watchActiveSession() {
    return _client
        .from('live_quiz_sessions')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .map((rows) => rows.isEmpty ? null : LiveQuizSession.fromMap(rows.first));
  }

  Future<void> submitAnswer({
    required String sessionId,
    required String questionId,
    required QuizOption option,
  }) async {
    try {
      await _client.from('live_quiz_responses').insert({
        'session_id': sessionId,
        'question_id': questionId,
        'user_id': _client.auth.currentUser!.id,
        'option_id': option.id,
        'is_correct': option.isCorrect,
      });
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  /// Rôle de l'utilisateur courant, pour n'afficher le bouton "Lancer un
  /// quiz" qu'aux formateurs/admin.
  /// ⚠️ Adapter le nom de table ('users') si ton schéma en utilise un autre.
  Future<String?> fetchCurrentUserRole() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _client.from('users').select('role').eq('id', uid).maybeSingle();
      return row?['role'] as String?;
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }
}
