import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/sections/club_section.dart';
import '../../../core/sections/section_controller.dart';
import '../../../features/auth/domain/providers/auth_provider.dart';

class SectionPickerScreen extends ConsumerStatefulWidget {
  const SectionPickerScreen({super.key});

  @override
  ConsumerState<SectionPickerScreen> createState() =>
      _SectionPickerScreenState();
}

class _SectionPickerScreenState extends ConsumerState<SectionPickerScreen> {
  ClubSection? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(sectionProvider).value;
  }

  Future<void> _confirm() async {
    final section = _selected;
    if (section == null || _saving) return;
    setState(() => _saving = true);

    await ref.read(sectionProvider.notifier).select(section);
    if (!mounted) return;

    // Détermine la route suivante selon le rôle et le niveau
    final profile = ref.read(currentProfileProvider).valueOrNull;
    final isMember = profile?.role == 'member';
    final hasLevel = profile?.currentLevelId != null;

    // Vérifie si le placement a déjà été fait (local)
    final prefs = await SharedPreferences.getInstance();
    final userId = ref.read(currentUserProvider)?.id;
    final placementCompleted = userId != null &&
        (prefs.getBool('placement_completed_$userId') ?? false);

    String nextRoute;
    if (isMember && !hasLevel && !placementCompleted) {
      nextRoute = '/placement/survey';
    } else {
      nextRoute = '/dashboard';
    }

    if (!mounted) return;
    context.go(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = _selected;

    return Scaffold(
      appBar: context.canPop() ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.filter_list_rounded, size: 56),
                const SizedBox(height: 12),
                Text(
                  'Choisis ta section',
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ton dashboard, tes parcours et tes points de '
                  'compétences s\'adaptent à la section choisie.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                for (final section in ClubSection.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SectionTile(
                      section: section,
                      selected: section == selected,
                      onTap: () => setState(() => _selected = section),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: selected == null || _saving ? null : _confirm,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          selected == null
                              ? 'Choisis une section'
                              : 'Rejoindre ${selected.slug}/',
                          style: theme.textTheme.labelLarge,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final ClubSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = section.accent;

    return Material(
      color: selected ? accent.withValues(alpha: 0.10) : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? accent : scheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  section.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            isDark(context) ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      section.tagline,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? accent : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isDark(BuildContext context) {
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }
}