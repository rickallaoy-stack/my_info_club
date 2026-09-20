import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../sections/presentation/section_header.dart';
import '../../../trainer/data/repositories/trainer_repository.dart';
import '../../../trainer/domain/providers/trainer_provider.dart';
import '../../../sessions/data/repositories/session_repository.dart';
import '../../../sessions/domain/providers/session_provider.dart';
import '../../domain/providers/role_override_provider.dart';
import '../../../../core/constants/env.dart';
import '../../../../core/domain/providers/group_provider.dart';

enum UserRole { membre, formateur }

final currentUserRoleProvider = Provider<UserRole>((ref) {
  final unlocked = ref.watch(formateurModeProvider);
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  final serverTrainer =
      profile != null && (profile.role == 'trainer' || profile.role == 'admin');
  // Le rôle serveur l'emporte, sinon utiliser le déblocage local si présent.
  return serverTrainer || unlocked ? UserRole.formateur : UserRole.membre;
});

class _DashboardError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Impossible de charger ton profil.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(currentProfileProvider).when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => _DashboardError(
            onRetry: () => ref.invalidate(currentProfileProvider),
          ),
          data: (profile) {
            final role = ref.watch(currentUserRoleProvider);
            final firstName = profile?.firstName.isNotEmpty == true
              ? profile!.firstName
              : 'membre';
            final colorScheme = Theme.of(context).colorScheme;

            return Scaffold(
              body: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      title: Text(
                        role == UserRole.formateur
                            ? 'Espace Formateur'
                            : 'Espace Membre',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      actions: [
                        IconButton(
                          onPressed: () => _signOut(context, ref),
                          icon: Icon(
                            PhosphorIconsBold.signOut,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        PopupMenuButton<String>(
                          tooltip: 'Groupe',
                          icon: Icon(Icons.group, color: colorScheme.onSurface),
                          onSelected: (value) =>
                              ref.read(currentGroupProvider.notifier).state = value,
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'membre', child: Text('Membre')),
                            const PopupMenuItem(value: 'formateur', child: Text('Formateur')),
                            const PopupMenuItem(value: 'admin', child: Text('Admin')),
                            const PopupMenuItem(value: 'guest', child: Text('Guest')),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      sliver: SliverList(
                          delegate: role == UserRole.formateur
                            ? _buildFormateurContent(context, ref, firstName)
                            : _buildMembreContent(context, ref, firstName),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) context.go('/login');
  }

  SliverChildListDelegate _buildMembreContent(BuildContext context, WidgetRef ref, String firstName) {
    return SliverChildListDelegate([
      const SectionHeader(),
      const SizedBox(height: 16),
      Text(
        'Bonjour $firstName',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: AppSpacing.lg),
      const _SectionTitle(title: 'Mes formations'),
      const SizedBox(height: AppSpacing.sm),
      const _EmptyCard(
        icon: PhosphorIconsBold.graduationCap,
        title: 'Aucune formation en course',
        subtitle: 'Rejoins une session pour commencer',
      ),
      const SizedBox(height: AppSpacing.lg),
      const _SectionTitle(title: 'Prochaines sessions'),
      const SizedBox(height: AppSpacing.sm),
      const _UpcomingSessions(),
      const SizedBox(height: AppSpacing.lg),
      const _SectionTitle(title: 'Resources'),
      const SizedBox(height: AppSpacing.sm),
      const _QuickAction(
        icon: PhosphorIconsBold.files,
        title: 'Documents',
        subtitle: 'Course, PDFs, supports',
      ),
      const SizedBox(height: AppSpacing.sm),
      const _QuickAction(
        icon: PhosphorIconsBold.code,
        title: 'Exercices',
        subtitle: 'Pratique et challenges',
      ),
      const SizedBox(height: AppSpacing.lg),
      _QuickAction(
        icon: PhosphorIconsBold.lockKey,
        title: 'Accès formateur',
        subtitle: 'Entrer le code pour basculer de vue',
        onTap: () => _promptTrainerAccess(context, ref),
      ),
    ]);
  }

  SliverChildListDelegate _buildFormateurContent(BuildContext context, WidgetRef ref, String firstName) {
    return SliverChildListDelegate([
      const SectionHeader(),
      const SizedBox(height: 16),
      Text(
        'Bonjour $firstName',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: AppSpacing.lg),
      const _SectionTitle(title: 'Vue d’ensemble'),
      const SizedBox(height: AppSpacing.sm),
      const Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Membres',
              value: '24',
              icon: PhosphorIconsBold.users,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatCard(
              label: 'Sessions',
              value: '6',
              icon: PhosphorIconsBold.calendarCheck,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      const _SectionTitle(title: 'Mes étudiants'),
      const SizedBox(height: AppSpacing.sm),
      const _TrainerStudentsList(),
      const SizedBox(height: AppSpacing.lg),
      const _SectionTitle(title: 'Actions rapides'),
      const SizedBox(height: AppSpacing.sm),
      const _QuickAction(
        icon: PhosphorIconsBold.plusCircle,
        title: 'Créer une session',
        subtitle: 'Planifier un nouveau course',
      ),
      const SizedBox(height: AppSpacing.sm),
      const _QuickAction(
        icon: PhosphorIconsBold.userPlus,
        title: 'Gérer les membres',
        subtitle: 'Ajouter ou retirer des participants',
      ),
      const SizedBox(height: AppSpacing.sm),
      const _QuickAction(
        icon: PhosphorIconsBold.notebook,
        title: 'Supports de course',
        subtitle: 'Uploader des documents',
      ),
      const SizedBox(height: AppSpacing.lg),
      _QuickAction(
        icon: PhosphorIconsBold.arrowUUpLeft,
        title: 'Repasser en membre',
        subtitle: 'Revenir à la vue standard',
        onTap: () => ref.read(formateurModeProvider.notifier).lock(),
      ),
      const SizedBox(height: AppSpacing.lg),
      const _SectionTitle(title: 'Sessions à venir'),
      const SizedBox(height: AppSpacing.sm),
      const _EmptyCard(
        icon: PhosphorIconsBold.calendarBlank,
        title: 'Aucune session planifiée',
        subtitle: 'Crée ta première session',
      ),
    ]);
  }

  Future<void> _promptTrainerAccess(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          String? error;
          return AlertDialog(
            title: const Text('Accès formateur'),
            content: TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Code formateur',
                errorText: error,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () {
                  if (controller.text == Env.trainerAccessCode &&
                      Env.trainerAccessCode.isNotEmpty) {
                    ref.read(formateurModeProvider.notifier).unlock();
                    Navigator.of(dialogContext).pop();
                  } else {
                    setState(() => error = 'Code incorrect');
                  }
                },
                child: const Text('Valider'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrainerStudentsList extends ConsumerWidget {
  const _TrainerStudentsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(trainerStudentsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Text(
            'Impossible de charger les étudiants.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          data: (students) {
            if (students.isEmpty) {
              return const _EmptyCard(
                icon: PhosphorIconsBold.users,
                title: 'Aucun étudiant',
                subtitle: 'Les étudiants de tes classes apparaîtront ici',
              );
            }

            return Column(
              children: [
                for (final student in students)
                  _StudentListTile(student: student),
              ],
            );
          },
        );
  }
}

class _StudentListTile extends StatelessWidget {
  final StudentProfile student;

  const _StudentListTile({required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            '${student.firstName.isNotEmpty ? student.firstName[0] : ''}'
                    '${student.lastName.isNotEmpty ? student.lastName[0] : ''}'
                .toUpperCase(),
          ),
        ),
        title: Text('${student.firstName} ${student.lastName}'),
        subtitle: Text(student.email),
        trailing: const Icon(PhosphorIconsBold.caretRight),
        onTap: () => context.push('/trainer/students/${student.id}'),
      ),
    );
  }
}

class _UpcomingSessions extends ConsumerWidget {
  const _UpcomingSessions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classId = ref.watch(currentProfileProvider).valueOrNull?.classId;
    if (classId == null) {
      return const _EmptyCard(
        icon: PhosphorIconsBold.calendarBlank,
        title: 'Aucune classe affectée',
        subtitle: 'Les sessions apparaîtront après ton affectation',
      );
    }

    return ref.watch(upcomingSessionsProvider(classId)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const _EmptyCard(
            icon: PhosphorIconsBold.warning,
            title: 'Sessions indisponibles',
            subtitle: 'Réessaie plus tard',
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return const _EmptyCard(
                icon: PhosphorIconsBold.calendarBlank,
                title: 'Rien de prévu pour le moment',
                subtitle: 'Les prochaines sessions apparaîtront ici',
              );
            }

            return Column(
              children: [
                for (final session in sessions) _SessionTile(session: session),
              ],
            );
          },
        );
  }
}

class _SessionTile extends StatelessWidget {
  final ClubSession session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: const Icon(PhosphorIconsBold.calendarCheck),
        title: Text(_sessionType(session.type)),
        subtitle: Text(_formatDate(session.date)),
      ),
    );
  }

  String _sessionType(String type) {
    switch (type) {
      case 'atelier':
        return 'Atelier';
      case 'evaluation':
        return 'Évaluation';
      default:
        return 'Cours';
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIconsBold.caretRight,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: colorScheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
