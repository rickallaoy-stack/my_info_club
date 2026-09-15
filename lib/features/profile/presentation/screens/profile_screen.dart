import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/theme_mode_provider.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/providers/profile_provider.dart';
import '../widgets/stat_chip.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, __) => Center(child: Text('Erreur de chargement : $err')),
          data: (profile) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(userProfileProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _Header(profile: profile),
                const SizedBox(height: AppSpacing.lg),
                _StatsRow(),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSection(),
                const SizedBox(height: AppSpacing.lg),
                _SignOutButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
          child: profile.avatarUrl == null
              ? Icon(AppIcons.profile, size: 40, color: colorScheme.primary)
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(profile.fullName, style: textTheme.titleLarge),
        Text(profile.email, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            _roleLabel(profile.role),
            style: textTheme.labelSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          ),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Modifier le profil'),
        ),
      ],
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'formateur':
        return 'Formateur';
      case 'admin':
        return 'Admin';
      default:
        return 'Membre';
    }
  }
}

class _StatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final stats = ref.watch(profileStatsProvider).valueOrNull;

    return Row(
      children: [
        StatChip(
          icon: AppIcons.validation,
          value: '${stats?.skillsValidated ?? '—'}',
          label: 'Compétences validées',
        ),
        const SizedBox(width: AppSpacing.sm),
        StatChip(
          icon: AppIcons.classes,
          value: profile?.className ?? '—',
          label: 'Classe',
        ),
        const SizedBox(width: AppSpacing.sm),
        StatChip(
          icon: AppIcons.path,
          value: profile?.levelName ?? '—',
          label: 'Niveau',
        ),
      ],
    );
  }
}

class _SettingsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Paramètres', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _SettingsTile(
          icon: Icons.dark_mode_outlined,
          title: 'Thème',
          trailing: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined, size: 16)),
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.smartphone, size: 16)),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined, size: 16)),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) => ref.read(themeModeProvider.notifier).set(selection.first),
          ),
        ),
        _SettingsTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          trailing: Switch(
            value: notificationsEnabled,
            onChanged: (value) => ref.read(notificationsEnabledProvider.notifier).set(value),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.trailing});
  final IconData icon;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(title)),
          trailing,
        ],
      ),
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        minimumSize: const Size.fromHeight(48),
      ),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Se déconnecter ?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Déconnexion')),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(profileRepositoryProvider).signOut();
          // Le router redirige automatiquement vers /login via authStateChangesProvider.
        }
      },
      icon: const Icon(Icons.logout, size: 18),
      label: const Text('Se déconnecter'),
    );
  }
}
