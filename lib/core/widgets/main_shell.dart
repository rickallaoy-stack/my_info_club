import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/live_quiz/domain/providers/live_quiz_provider.dart';
import '../../features/live_quiz/presentation/screens/launch_quiz_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

/// Coquille de navigation principale, style Yango :
/// pas d'AppBar classique, une barre de nav flottante arrondie posée
/// au-dessus du contenu plutôt qu'une BottomNavigationBar plate.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    _TabData(icon: AppIcons.dashboardOutlined, activeIcon: AppIcons.dashboard, label: 'Accueil'),
    _TabData(icon: AppIcons.classesOutlined, activeIcon: AppIcons.classes, label: 'Classes'),
    _TabData(icon: AppIcons.skillsOutlined, activeIcon: AppIcons.skills, label: 'Compétences'),
    _TabData(icon: AppIcons.profileOutlined, activeIcon: AppIcons.profile, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          const DashboardScreen(),
          _ComingSoon(label: _tabs[1].label, colorScheme: colorScheme),
          _ComingSoon(label: _tabs[2].label, colorScheme: colorScheme),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _FloatingNavBar(
        tabs: _tabs,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
      // Visible uniquement pour formateur/admin : accès rapide pour
      // déclencher un quiz en direct depuis n'importe quel onglet.
      floatingActionButton: Consumer(
        builder: (context, ref, _) {
          final isStaff = ref.watch(isQuizStaffProvider).valueOrNull ?? false;
          if (!isStaff) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LaunchQuizScreen()),
            ),
            icon: const Icon(Icons.bolt_rounded),
            label: const Text('Quiz'),
          );
        },
      ),
    );
  }
}

class _TabData {
  const _TabData({required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.tabs, required this.currentIndex, required this.onTap});

  final List<_TabData> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final selected = i == currentIndex;
              final tab = tabs[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    padding: EdgeInsets.symmetric(horizontal: selected ? AppSpacing.md : 0),
                    decoration: BoxDecoration(
                      color: selected ? colorScheme.primaryContainer : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? tab.activeIcon : tab.icon,
                          size: 22,
                          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                        if (selected) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            tab.label,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.label, required this.colorScheme});
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label — bientôt disponible',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
