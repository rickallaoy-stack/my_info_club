import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/learning_levels.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/sections/section_controller.dart';
import 'placement_survey_screen.dart';

class PlacementQuizScreen extends ConsumerStatefulWidget {
  final PlacementSurveyAnswers survey;

  const PlacementQuizScreen({required this.survey, super.key});

  @override
  ConsumerState<PlacementQuizScreen> createState() => _PlacementQuizScreenState();
}

class _PlacementQuizScreenState extends ConsumerState<PlacementQuizScreen> {
  int _questionIndex = 0;
  final Map<int, int> _answers = {};
  List<PlacementQuestion> _questions = [];
  bool _loading = true;
  String? _error;
  String? _quizId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadQuizAndQuestions();
  }

  Future<void> _loadQuizAndQuestions() async {
    try {
      final section = ref.read(sectionProvider).value;
      final client = Supabase.instance.client;

      // 1. Chercher le quiz de placement pour cette section
      if (section != null) {
        final quizRow = await client
            .from('placement_quizzes')
            .select('id')
            .eq('section', section.slug)
            .maybeSingle();
        _quizId = quizRow?['id'] as String?;
      }

      // 2. Repli : quiz sans section (premier quiz trouvé) si pas de quiz pour la section
      _quizId ??= await client
          .from('placement_quizzes')
          .select('id')
          .limit(1)
          .maybeSingle()
          .then((row) => row?['id'] as String?);

      if (_quizId == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Aucun quiz de placement configuré pour cette section. Contactez un administrateur.';
        });
        return;
      }

      // 3. Charger les questions via RPC (sécurisé, sans est_correcte)
      final result = await client.rpc('get_placement_questions', params: {
        'p_quiz_id': _quizId,
      });

      final loadedQuestions = <PlacementQuestion>[];
      final questionsJson = result as List<dynamic>;

      for (final qJson in questionsJson) {
        final optionsJson = qJson['options'] as List<dynamic>? ?? [];
        final options = optionsJson.map((o) => o['texte'] as String).toList();

        loadedQuestions.add(PlacementQuestion(
          id: qJson['id'] as String,
          enonce: qJson['enonce'] as String,
          options: options,
          optionIds: optionsJson.map((o) => o['id'] as String).toList(),
        ));
      }

      if (loadedQuestions.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Ce quiz ne contient aucune question. Contactez un administrateur.';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _questions = loadedQuestions;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[PlacementQuizScreen] Erreur chargement quiz: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger le quiz: $e';
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _loadQuizAndQuestions();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz de placement')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Erreur',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _retry,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(
          child: Text(
            'Aucune question disponible',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final question = _questions[_questionIndex];
    final selected = _answers[_questionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz ${_questionIndex + 1}/${_questions.length}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          LinearProgressIndicator(
            value: (_questionIndex + 1) / _questions.length,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(question.enonce, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < question.options.length; index++)
            RadioListTile<int>(
              value: index,
              groupValue: selected,
              title: Text(question.options[index]),
              onChanged: (value) {
                if (value != null)
                  setState(() => _answers[_questionIndex] = value);
              },
            ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _submitting || selected == null ? null : _next,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _questionIndex == _questions.length - 1
                        ? 'Voir mon niveau'
                        : 'Question suivante',
                  ),
          ),
        ],
      ),
    );
  }

  void _next() {
    if (_questionIndex < _questions.length - 1) {
      setState(() => _questionIndex++);
      return;
    }

    // Dernière question -> soumettre au serveur
    _submitToServer();
  }

  Future<void> _submitToServer() async {
    setState(() => _submitting = true);

    try {
      final client = Supabase.instance.client;

      // Construire le payload des réponses pour la RPC
      final answersForRpc = _answers.entries.map((entry) {
        final q = _questions[entry.key];
        final optionId = entry.value < q.optionIds.length
            ? q.optionIds[entry.value]
            : q.optionIds.first;
        return {
          'question_id': q.id,
          'option_id': optionId,
        };
      }).toList();

      // Appel RPC submit_placement
      final result = await client.rpc('submit_placement', params: {
        'p_quiz_id': _quizId,
        'p_answers': answersForRpc,
      });

      if (!mounted) return;

      final levelId = result as String;

      // Récupérer le LearningLevel depuis levelId (via ordre)
      final levelRow = await client
          .from('levels')
          .select('ordre')
          .eq('id', levelId)
          .maybeSingle();

      LearningLevel level;
      if (levelRow != null) {
        final ordre = levelRow['ordre'] as int;
        level = switch (ordre) {
          1 => LearningLevel.debutant,
          2 => LearningLevel.novice,
          3 => LearningLevel.intermediaire,
          4 => LearningLevel.expert,
          _ => LearningLevel.debutant,
        };
      } else {
        level = LearningLevel.debutant;
      }

      // Marquer le placement comme complété localement (SEULEMENT après succès serveur)
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('placement_completed_$userId', true);
      }

      if (!mounted) return;
      context.go('/placement/result', extra: level);
    } catch (e) {
      debugPrint('[PlacementQuizScreen] Erreur RPC submit_placement: $e');
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Erreur lors de l\'enregistrement: $e';
      });
    }
  }
}

class PlacementQuestion {
  final String id;
  final String enonce;
  final List<String> options;
  final List<String> optionIds;

  const PlacementQuestion({
    required this.id,
    required this.enonce,
    required this.options,
    required this.optionIds,
  });
}