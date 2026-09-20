import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/domain/providers/group_provider.dart';

/// Points d'entrée de l'application connectée.
///
/// Chaque entrée définit un [GoRoute] principal (chemin complet) et un
/// [IconData] pour la bottom navigation bar.
enum AppTab {
  dashboard(
    route: '/dashboard',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Accueil',
  ),
  learningPath(
    route: '/learning-path',
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book,
    label: 'Parcours',
  ),
  activities(
    route: '/activities',
    icon: Icons.sports_outlined,
    activeIcon: Icons.sports,
    label: 'Activités',
  ),
  resources(
    route: '/resources',
    icon: Icons.folder_open_outlined,
    activeIcon: Icons.folder_open,
    label: 'Ressources',
  ),
  profile(
    route: '/profile',
    icon: Icons.person_outlined,
    activeIcon: Icons.person,
    label: 'Profil',
  );

  const AppTab({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Scaffold principal avec bottom navigation bar.
///
/// Les écrans d'authentification (splash, login, register, etc.) ne passent
/// pas par ce shell : ils sont des [GoRoute] directement dans le routeur.
class MainScaffold extends ConsumerWidget {
  const MainScaffold({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  const _BottomNav();

  List<AppTab> _tabsForGroup(String group) {
    // Mapping simple : personnalisez selon les besoins métier.
    switch (group) {
      case 'formateur':
        return [AppTab.dashboard, AppTab.resources, AppTab.activities, AppTab.learningPath, AppTab.profile];
      case 'admin':
        return AppTab.values;
      case 'guest':
        return [AppTab.dashboard, AppTab.learningPath];
      case 'membre':
      default:
        return [AppTab.dashboard, AppTab.learningPath, AppTab.activities, AppTab.resources, AppTab.profile];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    final group = ref.watch(currentGroupProvider);
    final tabs = _tabsForGroup(group);
    final idx = tabs.indexWhere((tab) => location == tab.route);
    return BottomNavigationBar(
      currentIndex: idx >= 0 ? idx : 0,
      onTap: (index) {
        final tab = tabs[index];
        context.go(tab.route);
      },
      items: tabs
          .map(
            (tab) => BottomNavigationBarItem(
              icon: Icon(tab.icon),
              activeIcon: Icon(tab.activeIcon),
              label: tab.label,
            ),
          )
          .toList(),
    );
  }
}