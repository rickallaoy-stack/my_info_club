import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';

class PlacementSurveyScreen extends StatefulWidget {
  const PlacementSurveyScreen({super.key});

  @override
  State<PlacementSurveyScreen> createState() => _PlacementSurveyScreenState();
}

class _PlacementSurveyScreenState extends State<PlacementSurveyScreen> {
  int _comfort = 0;
  int _experience = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avant le quiz')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Faisons connaissance',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Ce sondage nous aide à adapter le parcours. Il ne compte pas dans le score du quiz.',
          ),
          const SizedBox(height: AppSpacing.xl),
          _Question(
            title: 'Quel est ton niveau de confort avec le code ?',
            options: const [
              'Je découvre complètement',
              'Je connais quelques notions',
              'Je suis à l’aise avec les bases',
              'Je peux construire un projet',
            ],
            value: _comfort,
            onChanged: (value) => setState(() => _comfort = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Question(
            title: 'As-tu déjà réalisé un projet informatique ?',
            options: const [
              'Jamais',
              'Quelques exercices',
              'Un ou deux projets',
              'Plusieurs projets',
            ],
            value: _experience,
            onChanged: (value) => setState(() => _experience = value),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _comfort == 0 || _experience == 0
                ? null
                : () => context.push(
                      '/placement/quiz',
                      extra: PlacementSurveyAnswers(
                        comfort: _comfort,
                        experience: _experience,
                      ),
                    ),
            child: const Text('Commencer le quiz'),
          ),
        ],
      ),
    );
  }
}

class PlacementSurveyAnswers {
  final int comfort;
  final int experience;

  const PlacementSurveyAnswers({
    required this.comfort,
    required this.experience,
  });
}

class _Question extends StatelessWidget {
  final String title;
  final List<String> options;
  final int value;
  final ValueChanged<int> onChanged;

  const _Question({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < options.length; index++)
          RadioListTile<int>(
            value: index + 1,
            groupValue: value,
            contentPadding: EdgeInsets.zero,
            title: Text(options[index]),
            onChanged: (selected) {
              if (selected != null) onChanged(selected);
            },
          ),
      ],
    );
  }
}
