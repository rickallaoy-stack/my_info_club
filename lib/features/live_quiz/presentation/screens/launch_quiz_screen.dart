import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/providers/live_quiz_provider.dart';

/// Écran formateur/admin : choisit un quiz dans la banque et le lance
/// en direct pour tout le monde. À exposer via un bouton (ex. dans
/// l'écran Profil ou un menu formateur) conditionné par `isQuizStaffProvider`.
class LaunchQuizScreen extends ConsumerWidget {
  const LaunchQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizBank = ref.watch(quizBankProvider);
    final activeSession = ref.watch(activeLiveQuizSessionProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Lancer un quiz')),
      body: quizBank.when(
        data: (quizzes) {
          if (quizzes.isEmpty) {
            return const Center(child: Text('Aucun quiz dans la banque pour le moment.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: quizzes.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: Text(quiz.title),
                  subtitle: quiz.description != null ? Text(quiz.description!) : null,
                  trailing: FilledButton(
                    onPressed: activeSession != null
                        ? null // un quiz est déjà en cours (contrainte DB)
                        : () => _launch(context, ref, quiz.id),
                    child: const Text('Lancer'),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(child: Text('Erreur de chargement : $err')),
      ),
    );
  }

  Future<void> _launch(BuildContext context, WidgetRef ref, String quizId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lancer ce quiz ?'),
        content: const Text('Il apparaîtra immédiatement chez tous les membres connectés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lancer')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(liveQuizRepositoryProvider).startLiveQuiz(quizId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz lancé.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }
}
