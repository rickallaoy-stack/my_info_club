import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/learning_levels.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../competencies/data/repositories/competency_points_repository.dart';
import '../../../competencies/domain/providers/competency_points_provider.dart';
import '../../data/repositories/trainer_repository.dart';
import '../../domain/providers/trainer_provider.dart';

class StudentProfileScreen extends ConsumerWidget {
  final String studentId;

  const StudentProfileScreen({required this.studentId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentProfileProvider).valueOrNull?.role;
    if (role != 'trainer' && role != 'admin') {
      return const Scaffold(
        body: Center(child: Text('Cette page est réservée aux formateurs.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil étudiant')),
      body: ref.watch(studentProfileProvider(studentId)).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const Center(
              child: Text('Impossible de charger ce profil.'),
            ),
            data: (student) {
              if (student == null) {
                return const Center(child: Text('Étudiant introuvable.'));
              }

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  CircleAvatar(
                    radius: 38,
                    child: Text(
                      _initials(student),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${student.firstName} ${student.lastName}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    student.email,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _InfoTile(
                    label: 'Classe',
                    value: student.classId ?? 'Non affecté',
                  ),
                  _InfoTile(
                    label: 'Niveau actuel',
                    value: _levelLabel(student.currentLevelName),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PointsSection(studentId: student.id),
                ],
              );
            },
          ),
    );
  }

  String _levelLabel(String? name) {
    return learningLevelFromName(name)?.label ?? 'Non évalué';
  }

  String _initials(StudentProfile student) {
    final first = student.firstName.isNotEmpty ? student.firstName[0] : '';
    final last = student.lastName.isNotEmpty ? student.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }
}

class _PointsSection extends ConsumerWidget {
  final String studentId;

  const _PointsSection({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(studentCompetencyPointsProvider(studentId)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              const Text('Impossible de charger les points de compétences.'),
          data: (points) {
            final total = points.fold<int>(0, (sum, item) => sum + item.points);
            final nextThreshold = _nextThreshold(total);
            final progress = nextThreshold == null
                ? 1.0
                : (total / nextThreshold).clamp(0.0, 1.0);
            final userId = ref.watch(currentUserProvider)?.id;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Points de compétences',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('$total points',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: AppSpacing.sm),
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          nextThreshold == null
                              ? 'Palier Expert atteint'
                              : '${nextThreshold - total} points avant le prochain palier',
                        ),
                        if (userId != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          FilledButton.icon(
                            onPressed: () => _showAwardDialog(
                              context,
                              ref,
                              userId,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Attribuer des points'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final item in points)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.category.label),
                    subtitle: Text(item.comment ?? 'Aucun commentaire'),
                    trailing: Text('+${item.points}'),
                  ),
              ],
            );
          },
        );
  }

  int? _nextThreshold(int total) {
    for (final threshold in [100, 250, 500]) {
      if (total < threshold) return threshold;
    }
    return null;
  }

  Future<void> _showAwardDialog(
    BuildContext context,
    WidgetRef ref,
    String trainerId,
  ) async {
    final pointsController = TextEditingController();
    final commentController = TextEditingController();
    var category = CompetencyPointCategory.realisation;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Attribuer des points'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<CompetencyPointCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: CompetencyPointCategory.values
                      .map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => category = value);
                  },
                ),
                TextField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Points (1 à 100)',
                  ),
                ),
                TextField(
                  controller: commentController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Commentaire'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final points = int.tryParse(pointsController.text);
                if (points == null || points < 1 || points > 100) return;
                await ref.read(competencyPointsRepositoryProvider).award(
                      studentId: studentId,
                      trainerId: trainerId,
                      category: category,
                      points: points,
                      comment: commentController.text,
                    );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );

    if (submitted == true) {
      ref.invalidate(studentCompetencyPointsProvider(studentId));
    }
    pointsController.dispose();
    commentController.dispose();
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
