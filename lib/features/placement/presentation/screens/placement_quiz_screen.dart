import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/learning_levels.dart';
import '../../../../core/theme/app_spacing.dart';
import 'placement_survey_screen.dart';

class PlacementQuizScreen extends StatefulWidget {
  final PlacementSurveyAnswers survey;

  const PlacementQuizScreen({required this.survey, super.key});

  @override
  State<PlacementQuizScreen> createState() => _PlacementQuizScreenState();
}

class _PlacementQuizScreenState extends State<PlacementQuizScreen> {
  int _questionIndex = 0;
  final Map<int, int> _answers = {};

  static const _questions = [
    (
      'Quelle valeur contient une variable ?',
      ['Une donnée', 'Une image uniquement', 'Un écran', 'Une connexion'],
      0,
    ),
    (
      'Quel mot-clé crée une condition en Dart ?',
      ['loop', 'if', 'when', 'case-only'],
      1,
    ),
    (
      'Quel est le rôle principal d’une fonction ?',
      [
        'Stocker une image',
        'Regrouper une logique réutilisable',
        'Créer un mot de passe',
        'Fermer l’application'
      ],
      1,
    ),
    (
      'Quel outil permet de versionner un projet ?',
      ['Git', 'Figma', 'SMTP', 'JSON'],
      0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final question = _questions[_questionIndex];
    final selected = _answers[_questionIndex];

    return Scaffold(
      appBar: AppBar(
          title: Text('Quiz ${_questionIndex + 1}/${_questions.length}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          LinearProgressIndicator(
            value: (_questionIndex + 1) / _questions.length,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(question.$1, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < question.$2.length; index++)
            RadioListTile<int>(
              value: index,
              groupValue: selected,
              title: Text(question.$2[index]),
              onChanged: (value) {
                if (value != null)
                  setState(() => _answers[_questionIndex] = value);
              },
            ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: selected == null ? null : _next,
            child: Text(
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

    final correctAnswers = _answers.entries
        .where((entry) => entry.value == _questions[entry.key].$3)
        .length;
    final surveyScore = (widget.survey.comfort + widget.survey.experience) / 2;
    final total = correctAnswers + surveyScore;
    final level = total <= 2
        ? LearningLevel.debutant
        : total <= 4
            ? LearningLevel.novice
            : total <= 6
                ? LearningLevel.intermediaire
                : LearningLevel.expert;

    context.go('/placement/result', extra: level);
  }
}
