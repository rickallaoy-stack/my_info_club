import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/quick_action_card.dart';

// TODO: contenu différent selon le rôle (membre vs formateur),
// à brancher sur un provider `currentUserRoleProvider`.
// TODO: remplacer les données statiques (nom, progression, activités)
// par des providers réels (dashboardProvider, learningPathProvider...).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              sliver: SliverToBoxAdapter(child: _Header(textTheme: textTheme, colorScheme: colorScheme)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
              sliver: SliverToBoxAdapter(
                child: _SearchBar(colorScheme: colorScheme, textTheme: textTheme),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              sliver: SliverToBoxAdapter(child: _QuickActionsRow()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
              sliver: SliverToBoxAdapter(
                child: _ProgressCard(colorScheme: colorScheme, textTheme: textTheme),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
              sliver: SliverToBoxAdapter(
                child: Text('Activité récente', style: textTheme.titleMedium),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxl + 80),
              sliver: SliverList.separated(
                itemCount: _demoActivity.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => _ActivityTile(
                  item: _demoActivity[index],
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.textTheme, required this.colorScheme});
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(AppIcons.profile, color: colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bonjour 👋', style: textTheme.bodySmall),
              Text('Angelo', style: textTheme.titleLarge),
            ],
          ),
        ),
        _IconBadgeButton(icon: AppIcons.bell, colorScheme: colorScheme, onTap: () {}),
      ],
    );
  }
}

class _IconBadgeButton extends StatelessWidget {
  const _IconBadgeButton({required this.icon, required this.colorScheme, required this.onTap});
  final IconData icon;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colorScheme.onSurface, size: 20),
      ),
    );
  }
}

/// Barre "Où allons-nous ?" façon Yango, reconvertie ici en
/// raccourci de recherche dans les classes/compétences/activités.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.colorScheme, required this.textTheme});
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
          child: Row(
            children: [
              Icon(AppIcons.search, size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text('Rechercher une classe, une compétence...', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;
}

class _QuickActionsRow extends StatelessWidget {
  static final _actions = [
    _QuickAction(AppIcons.classes, 'Mes classes', AppColors.primary),
    _QuickAction(AppIcons.activities, 'Activités', AppColors.secondary),
    _QuickAction(AppIcons.skills, 'Compétences', AppColors.tertiary),
    _QuickAction(AppIcons.path, 'Parcours', AppColors.success),
    _QuickAction(AppIcons.github, 'GitHub', AppColors.pending),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final a = _actions[index];
          return QuickActionCard(icon: a.icon, label: a.label, color: a.color, onTap: () {});
        },
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.colorScheme, required this.textTheme});
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    const progress = 0.62; // TODO: brancher sur learningPathProvider

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Votre progression',
                  style: textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Niveau actuel : Intermédiaire — 3 compétences à valider',
            style: textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem(this.icon, this.title, this.subtitle, this.color);
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

final _demoActivity = [
  _ActivityItem(AppIcons.validation, 'Compétence validée', 'Structures de données — il y a 2h', AppColors.success),
  _ActivityItem(AppIcons.upload, 'Rendu soumis', 'TP Arbres binaires — en attente de correction', AppColors.tertiary),
  _ActivityItem(AppIcons.classes, 'Nouvelle session', 'Classe Développement Mobile — demain 14h', AppColors.primary),
];

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item, required this.colorScheme, required this.textTheme});
  final _ActivityItem item;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: textTheme.titleSmall),
                Text(item.subtitle, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
