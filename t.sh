#!/usr/bin/env bash
# Crée toute l'arborescence lib/ + supabase/migrations/ pour le projet.
# À lancer depuis la RACINE de ton projet Flutter (là où se trouve pubspec.yaml).
set -e

mkdir -p \
  "lib" \
  "lib/app" \
  "lib/core/providers" \
  "lib/core/services" \
  "lib/core/widgets" \
  "lib/features/dashboard/presentation/screens" \
  "lib/features/dashboard/presentation/widgets" \
  "lib/features/live_quiz/data/repositories" \
  "lib/features/live_quiz/domain/entities" \
  "lib/features/live_quiz/domain/providers" \
  "lib/features/live_quiz/presentation/screens" \
  "lib/features/live_quiz/presentation/widgets" \
  "lib/features/profile/data/repositories" \
  "lib/features/profile/domain/entities" \
  "lib/features/profile/domain/providers" \
  "lib/features/profile/presentation/screens" \
  "lib/features/profile/presentation/widgets" \
  "supabase/migrations"

cat > "lib/app/app.dart" << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/theme_mode_provider.dart';
import '../features/live_quiz/presentation/widgets/live_quiz_overlay.dart';

class ClubInfoApp extends ConsumerWidget {
  const ClubInfoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Club Informatique',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      // Actif sur toute l'appli : dès qu'un formateur/admin lance un quiz,
      // le popup s'ouvre par-dessus l'écran courant, quel qu'il soit.
      builder: (context, child) => LiveQuizOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}
DARTEOF

cat > "lib/app/router.dart" << 'DARTEOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/go_router_refresh_stream.dart';
import '../core/widgets/main_shell.dart';
import '../features/auth/domain/providers/auth_provider.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';

/// Provider central du routeur.
/// `redirect` : tant que Supabase n'a pas confirmé l'état de session (null =
/// pas encore su), on reste sur `/`. Ensuite, connecté → /dashboard,
/// déconnecté → /login (sauf si déjà sur /register).
final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final isLoggedIn = authRepository.currentUser != null;
      final goingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !goingToAuth) return '/login';
      if (isLoggedIn && (goingToAuth || state.matchedLocation == '/')) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
      // /dashboard porte désormais la coquille avec nav flottante
      // (onglets Accueil / Classes / Compétences / Profil).
      GoRoute(
          path: '/dashboard',
          builder: (context, state) => const MainShell()),
      // TODO: /classes, /learning-path, /skills, /activities, /submissions,
      // /trainer/*, /sessions, /profile — à ajouter au fur et à mesure des
      // features (et à sortir de MainShell vers des routes dédiées si elles
      // ont besoin de sous-navigation propre).
    ],
  );
});
DARTEOF

cat > "lib/core/providers/theme_mode_provider.dart" << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/local_prefs_service.dart';

const _themeModeKey = 'theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _read(SharedPreferences prefs) {
    switch (prefs.getString(_themeModeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void set(ThemeMode mode) {
    state = mode;
    _prefs.setString(_themeModeKey, mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});

const _notificationsKey = 'notifications_enabled';

class NotificationsPrefNotifier extends StateNotifier<bool> {
  NotificationsPrefNotifier(this._prefs) : super(_prefs.getBool(_notificationsKey) ?? true);

  final SharedPreferences _prefs;

  void set(bool enabled) {
    state = enabled;
    _prefs.setBool(_notificationsKey, enabled);
  }
}

// Préférence locale seulement pour l'instant (pas encore branchée sur un
// vrai système de push — à faire quand les notifications seront implémentées).
final notificationsEnabledProvider = StateNotifierProvider<NotificationsPrefNotifier, bool>((ref) {
  return NotificationsPrefNotifier(ref.watch(sharedPreferencesProvider));
});
DARTEOF

cat > "lib/core/services/local_prefs_service.dart" << 'DARTEOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instance résolue une seule fois au démarrage (voir `main.dart`) puis
/// injectée via `overrideWithValue` — évite un FutureProvider à watcher
/// partout où on a besoin d'une préférence locale.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider doit être surchargé dans main.dart après '
    'SharedPreferences.getInstance().',
  );
});
DARTEOF

cat > "lib/core/widgets/main_shell.dart" << 'DARTEOF'
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
DARTEOF

cat > "lib/features/dashboard/presentation/screens/dashboard_screen.dart" << 'DARTEOF'
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
DARTEOF

cat > "lib/features/dashboard/presentation/widgets/quick_action_card.dart" << 'DARTEOF'
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Tuile d'action rapide façon Yango : icône dans un badge coloré,
/// libellé court en dessous, fond neutre, coins très arrondis.
class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
DARTEOF

cat > "lib/features/live_quiz/data/repositories/live_quiz_repository.dart" << 'DARTEOF'
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/live_quiz_entities.dart';

/// Encapsule tous les appels Supabase liés au quiz live.
/// Aucune UI ne doit importer `supabase_flutter` directement : tout passe par ici.
class LiveQuizRepository {
  final SupabaseClient _client;

  LiveQuizRepository(this._client);

  /// Banque de quiz pour le picker formateur/admin (sans les questions,
  /// pour rester léger).
  Future<List<Quiz>> fetchQuizBank() async {
    try {
      final rows = await _client
          .from('quizzes')
          .select('id, title, description')
          .order('created_at', ascending: false);
      return (rows as List).map((r) => Quiz.fromMap(r as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  /// Quiz complet (questions + options) pour l'affichage du popup.
  Future<Quiz> fetchQuizDetail(String quizId) async {
    try {
      final row = await _client
          .from('quizzes')
          .select('id, title, description, quiz_questions(id, statement, position, quiz_options(id, label, is_correct))')
          .eq('id', quizId)
          .order('position', referencedTable: 'quiz_questions')
          .single();
      return Quiz.fromMap(row);
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  /// Déclenche le popup chez tout le monde : un simple insert, capté
  /// ensuite par Realtime sur tous les clients abonnés.
  Future<void> startLiveQuiz(String quizId) async {
    try {
      await _client.from('live_quiz_sessions').insert({
        'quiz_id': quizId,
        'started_by': _client.auth.currentUser!.id,
      });
    } on PostgrestException catch (e) {
      // code 23505 = violation de l'index unique "un seul quiz actif à la fois"
      if (e.code == '23505') {
        throw const Failure('Un quiz est déjà en cours. Ferme-le avant d\'en relancer un.');
      }
      throw Failure(e.message, code: e.code);
    }
  }

  Future<void> closeLiveQuiz(String sessionId) async {
    try {
      await _client
          .from('live_quiz_sessions')
          .update({'status': 'closed', 'closed_at': DateTime.now().toIso8601String()})
          .eq('id', sessionId);
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  /// Session active en direct — émet `null` dès qu'elle est fermée ou
  /// qu'aucune n'est en cours.
  Stream<LiveQuizSession?> watchActiveSession() {
    return _client
        .from('live_quiz_sessions')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .map((rows) => rows.isEmpty ? null : LiveQuizSession.fromMap(rows.first));
  }

  Future<void> submitAnswer({
    required String sessionId,
    required String questionId,
    required QuizOption option,
  }) async {
    try {
      await _client.from('live_quiz_responses').insert({
        'session_id': sessionId,
        'question_id': questionId,
        'user_id': _client.auth.currentUser!.id,
        'option_id': option.id,
        'is_correct': option.isCorrect,
      });
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  /// Rôle de l'utilisateur courant, pour n'afficher le bouton "Lancer un
  /// quiz" qu'aux formateurs/admin.
  /// ⚠️ Adapter le nom de table ('users') si ton schéma en utilise un autre.
  Future<String?> fetchCurrentUserRole() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _client.from('users').select('role').eq('id', uid).maybeSingle();
      return row?['role'] as String?;
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }
}
DARTEOF

cat > "lib/features/live_quiz/domain/entities/live_quiz_entities.dart" << 'DARTEOF'
class QuizOption {
  final String id;
  final String label;
  final bool isCorrect;

  const QuizOption({required this.id, required this.label, required this.isCorrect});

  factory QuizOption.fromMap(Map<String, dynamic> map) {
    return QuizOption(
      id: map['id'] as String,
      label: map['label'] as String,
      isCorrect: map['is_correct'] as bool? ?? false,
    );
  }
}

class QuizQuestion {
  final String id;
  final String statement;
  final List<QuizOption> options;

  const QuizQuestion({required this.id, required this.statement, required this.options});

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    final options = (map['quiz_options'] as List<dynamic>? ?? [])
        .map((o) => QuizOption.fromMap(o as Map<String, dynamic>))
        .toList();
    return QuizQuestion(
      id: map['id'] as String,
      statement: map['statement'] as String,
      options: options,
    );
  }
}

/// Un quiz de la banque, avec ses questions (chargées à la demande
/// quand une session live démarre — la liste pour le picker n'a pas
/// besoin des questions).
class Quiz {
  final String id;
  final String title;
  final String? description;
  final List<QuizQuestion> questions;

  const Quiz({
    required this.id,
    required this.title,
    this.description,
    this.questions = const [],
  });

  factory Quiz.fromMap(Map<String, dynamic> map) {
    final questions = (map['quiz_questions'] as List<dynamic>? ?? [])
        .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => 0); // l'ordre vient déjà du .order('position') côté requête
    return Quiz(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      questions: questions,
    );
  }
}

class LiveQuizSession {
  final String id;
  final String quizId;
  final String status;
  final DateTime startedAt;

  const LiveQuizSession({
    required this.id,
    required this.quizId,
    required this.status,
    required this.startedAt,
  });

  factory LiveQuizSession.fromMap(Map<String, dynamic> map) {
    return LiveQuizSession(
      id: map['id'] as String,
      quizId: map['quiz_id'] as String,
      status: map['status'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
    );
  }
}
DARTEOF

cat > "lib/features/live_quiz/domain/providers/live_quiz_provider.dart" << 'DARTEOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/repositories/live_quiz_repository.dart';
import '../entities/live_quiz_entities.dart';

final liveQuizRepositoryProvider = Provider<LiveQuizRepository>((ref) {
  return LiveQuizRepository(ref.watch(supabaseClientProvider));
});

/// true si l'utilisateur courant peut déclencher un quiz (formateur/admin).
final isQuizStaffProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(liveQuizRepositoryProvider).fetchCurrentUserRole();
  return role == 'formateur' || role == 'admin';
});

/// Session live active, mise à jour en temps réel — null si aucun quiz
/// n'est en cours. C'est ce provider que l'overlay écoute pour ouvrir
/// le popup chez tout le monde.
final activeLiveQuizSessionProvider = StreamProvider<LiveQuizSession?>((ref) {
  return ref.watch(liveQuizRepositoryProvider).watchActiveSession();
});

/// Banque de quiz pour l'écran de déclenchement (formateur/admin).
final quizBankProvider = FutureProvider<List<Quiz>>((ref) {
  return ref.watch(liveQuizRepositoryProvider).fetchQuizBank();
});

/// Détail (questions + options) du quiz de la session active.
/// `.family` car l'id du quiz dépend de la session en cours.
final quizDetailProvider = FutureProvider.family<Quiz, String>((ref, quizId) {
  return ref.watch(liveQuizRepositoryProvider).fetchQuizDetail(quizId);
});
DARTEOF

cat > "lib/features/live_quiz/presentation/screens/launch_quiz_screen.dart" << 'DARTEOF'
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
DARTEOF

cat > "lib/features/live_quiz/presentation/widgets/live_quiz_overlay.dart" << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/live_quiz_provider.dart';
import 'live_quiz_popup.dart';

/// À poser une seule fois, tout en haut de l'arbre (dans `app.dart`,
/// à l'intérieur du `MaterialApp.router` via `builder`).
///
/// Écoute `activeLiveQuizSessionProvider` : dès qu'une session passe à
/// 'active' (déclenchée par un formateur/admin), ouvre le popup en
/// `showDialog` non-annulable par-dessus l'écran courant, quel qu'il soit.
class LiveQuizOverlay extends ConsumerStatefulWidget {
  const LiveQuizOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LiveQuizOverlay> createState() => _LiveQuizOverlayState();
}

class _LiveQuizOverlayState extends ConsumerState<LiveQuizOverlay> {
  String? _shownForSessionId;

  @override
  Widget build(BuildContext context) {
    ref.listen(activeLiveQuizSessionProvider, (previous, next) {
      final session = next.valueOrNull;
      if (session == null) return;
      if (_shownForSessionId == session.id) return; // déjà affiché pour cette session

      _shownForSessionId = session.id;
      _openPopup(session.id, session.quizId);
    });

    return widget.child;
  }

  void _openPopup(String sessionId, String quizId) {
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog(
      context: navigator.context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final quizAsync = ref.watch(quizDetailProvider(quizId));
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: quizAsync.when(
                data: (quiz) => LiveQuizPopup(sessionId: sessionId, quiz: quiz),
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, __) => SizedBox(
                  height: 120,
                  child: Center(child: Text('Impossible de charger le quiz : $err')),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
DARTEOF

cat > "lib/features/live_quiz/presentation/widgets/live_quiz_popup.dart" << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/live_quiz_entities.dart';
import '../../domain/providers/live_quiz_provider.dart';

/// Contenu du popup de quiz live : une question à la fois, on avance
/// au clic sur une réponse. Pas de retour arrière (c'est du direct).
class LiveQuizPopup extends ConsumerStatefulWidget {
  const LiveQuizPopup({super.key, required this.sessionId, required this.quiz});

  final String sessionId;
  final Quiz quiz;

  @override
  ConsumerState<LiveQuizPopup> createState() => _LiveQuizPopupState();
}

class _LiveQuizPopupState extends ConsumerState<LiveQuizPopup> {
  int _index = 0;
  QuizOption? _selected;
  bool _submitting = false;

  QuizQuestion get _question => widget.quiz.questions[_index];
  bool get _isLast => _index == widget.quiz.questions.length - 1;

  Future<void> _select(QuizOption option) async {
    if (_selected != null) return; // déjà répondu à cette question
    setState(() {
      _selected = option;
      _submitting = true;
    });

    try {
      await ref.read(liveQuizRepositoryProvider).submitAnswer(
            sessionId: widget.sessionId,
            questionId: _question.id,
            option: option,
          );
    } catch (_) {
      // On n'interrompt pas l'expérience du quiz pour une erreur réseau
      // ponctuelle sur l'enregistrement de la réponse.
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (_isLast) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _index++;
        _selected = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.quiz.questions.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('Ce quiz ne contient aucune question.')),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text('Quiz en direct', style: textTheme.titleMedium)),
              Text(
                '${_index + 1}/${widget.quiz.questions.length}',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(_question.statement, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ..._question.options.map((option) {
            final isSelected = _selected?.id == option.id;
            final showResult = _selected != null;
            final isCorrectOption = option.isCorrect;

            Color? tileColor;
            if (showResult) {
              if (isCorrectOption) {
                tileColor = Colors.green.withValues(alpha: 0.15);
              } else if (isSelected) {
                tileColor = Colors.red.withValues(alpha: 0.15);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Material(
                color: tileColor ?? colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: _submitting ? null : () => _select(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(child: Text(option.label, style: textTheme.bodyMedium)),
                        if (showResult && isCorrectOption)
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        if (showResult && isSelected && !isCorrectOption)
                          const Icon(Icons.cancel, color: Colors.red, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
DARTEOF

cat > "lib/features/profile/data/repositories/profile_repository.dart" << 'DARTEOF'
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/user_profile.dart';

/// Encapsule tous les appels Supabase liés au profil utilisateur.
/// Aucune UI ne doit importer `supabase_flutter` directement : tout passe par ici.
///
/// ⚠️ Suppose une table `users` avec colonnes full_name, email, avatar_url,
/// bio, role, class_id -> classes(name), current_level_id -> levels(name),
/// et une table `user_skills(user_id, validated bool)`. Adapter les noms
/// ci-dessous si ton schéma diffère.
class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<UserProfile> fetchProfile() async {
    try {
      final uid = _client.auth.currentUser!.id;
      final row = await _client
          .from('users')
          .select(
            'id, full_name, email, avatar_url, bio, role, '
            'classes:class_id(name), levels:current_level_id(name)',
          )
          .eq('id', uid)
          .single();
      return UserProfile.fromMap(row);
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<void> updateProfile({required String fullName, String? bio}) async {
    try {
      final uid = _client.auth.currentUser!.id;
      await _client.from('users').update({
        'full_name': fullName,
        'bio': bio,
      }).eq('id', uid);
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  /// Envoie l'image dans le bucket Storage `avatars` (à créer côté Supabase,
  /// public en lecture) puis enregistre l'URL sur le profil.
  Future<String> uploadAvatar(Uint8List bytes, String fileExtension) async {
    try {
      final uid = _client.auth.currentUser!.id;
      final path = '$uid/avatar.$fileExtension';

      await _client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _client.storage.from('avatars').getPublicUrl(path);
      await _client.from('users').update({'avatar_url': url}).eq('id', uid);
      return url;
    } on StorageException catch (e) {
      throw Failure(e.message);
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<ProfileStats> fetchStats() async {
    try {
      final uid = _client.auth.currentUser!.id;
      final validated = await _client
          .from('user_skills')
          .select('id')
          .eq('user_id', uid)
          .eq('validated', true)
          .count(CountOption.exact);

      return ProfileStats(skillsValidated: validated.count);
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
DARTEOF

cat > "lib/features/profile/domain/entities/user_profile.dart" << 'DARTEOF'
class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final String role;
  final String? className;
  final String? levelName;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.bio,
    required this.role,
    this.className,
    this.levelName,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      role: map['role'] as String? ?? 'membre',
      className: (map['classes'] as Map<String, dynamic>?)?['name'] as String?,
      levelName: (map['levels'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }
}

class ProfileStats {
  final int skillsValidated;

  const ProfileStats({required this.skillsValidated});
}
DARTEOF

cat > "lib/features/profile/domain/providers/profile_provider.dart" << 'DARTEOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/repositories/profile_repository.dart';
import '../entities/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

/// `autoDispose` volontairement absent : le profil reste en cache tant que
/// l'utilisateur est connecté. Après une modification, on appelle
/// `ref.invalidate(userProfileProvider)` pour le rafraîchir.
final userProfileProvider = FutureProvider<UserProfile>((ref) {
  return ref.watch(profileRepositoryProvider).fetchProfile();
});

final profileStatsProvider = FutureProvider((ref) {
  return ref.watch(profileRepositoryProvider).fetchStats();
});
DARTEOF

cat > "lib/features/profile/presentation/screens/edit_profile_screen.dart" << 'DARTEOF'
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  File? _pickedAvatar;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (picked != null) {
      setState(() => _pickedAvatar = File(picked.path));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(profileRepositoryProvider);

    try {
      if (_pickedAvatar != null) {
        final ext = _pickedAvatar!.path.split('.').last;
        await repo.uploadAvatar(await _pickedAvatar!.readAsBytes(), ext);
      }
      await repo.updateProfile(
        fullName: _nameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      );
      ref.invalidate(userProfileProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Pré-remplissage une seule fois, quand le profil arrive.
    if (!_initialized && profileAsync.hasValue) {
      _nameController.text = profileAsync.value!.fullName;
      _bioController.text = profileAsync.value!.bio ?? '';
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(child: Text('Erreur : $err')),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: _pickedAvatar != null
                          ? FileImage(_pickedAvatar!)
                          : (profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null) as ImageProvider?,
                      child: _pickedAvatar == null && profile.avatarUrl == null
                          ? Icon(AppIcons.profile, size: 44, color: colorScheme.primary)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.primary,
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio (optionnel)'),
            ),
          ],
        ),
      ),
    );
  }
}
DARTEOF

cat > "lib/features/profile/presentation/screens/profile_screen.dart" << 'DARTEOF'
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
DARTEOF

cat > "lib/features/profile/presentation/widgets/stat_chip.dart" << 'DARTEOF'
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: textTheme.titleMedium),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
DARTEOF

cat > "lib/main.dart" << 'DARTEOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'core/constants/env.dart';
import 'core/services/local_prefs_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Env.validate();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ClubInfoApp(),
    ),
  );
}
DARTEOF

cat > "supabase/migrations/20260914_live_quiz.sql" << 'DARTEOF'
-- Live quiz : un formateur/admin déclenche un quiz de la banque,
-- qui apparaît instantanément (via Realtime) chez tous les membres connectés.
--
-- ⚠️ Ce fichier suppose une table de rôle nommée `users` avec une colonne
-- `role` contenant 'formateur' / 'admin' / 'membre'. Si ton schéma existant
-- utilise un autre nom (ex. `profiles`), remplace `users` par le bon nom
-- dans les 5 policies "_staff" ci-dessous avant d'exécuter.

-- Banque de quiz réutilisable (placement, révisions, live...)
create table if not exists quizzes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references quizzes(id) on delete cascade,
  position int not null default 0,
  statement text not null,
  created_at timestamptz not null default now()
);

create table if not exists quiz_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references quiz_questions(id) on delete cascade,
  label text not null,
  is_correct boolean not null default false
);

-- Une ligne = un déclenchement du bouton "Lancer un quiz"
create table if not exists live_quiz_sessions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references quizzes(id),
  status text not null default 'active' check (status in ('active', 'closed')),
  started_by uuid not null references auth.users(id),
  started_at timestamptz not null default now(),
  closed_at timestamptz
);

-- Un seul quiz live actif à la fois dans toute l'appli
create unique index if not exists one_active_live_quiz
  on live_quiz_sessions (status)
  where status = 'active';

create table if not exists live_quiz_responses (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references live_quiz_sessions(id) on delete cascade,
  question_id uuid not null references quiz_questions(id),
  user_id uuid not null references auth.users(id),
  option_id uuid not null references quiz_options(id),
  is_correct boolean not null,
  answered_at timestamptz not null default now(),
  unique (session_id, question_id, user_id)
);

alter table quizzes enable row level security;
alter table quiz_questions enable row level security;
alter table quiz_options enable row level security;
alter table live_quiz_sessions enable row level security;
alter table live_quiz_responses enable row level security;

-- Lecture ouverte à tout utilisateur connecté (banque + sessions)
create policy "quizzes_select_authenticated" on quizzes
  for select to authenticated using (true);

create policy "quiz_questions_select_authenticated" on quiz_questions
  for select to authenticated using (true);

create policy "quiz_options_select_authenticated" on quiz_options
  for select to authenticated using (true);

create policy "live_quiz_sessions_select_authenticated" on live_quiz_sessions
  for select to authenticated using (true);

-- Écriture sur la banque de quiz réservée formateur/admin
create policy "quizzes_write_staff" on quizzes
  for all to authenticated
  using (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')))
  with check (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')));

create policy "quiz_questions_write_staff" on quiz_questions
  for all to authenticated
  using (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')))
  with check (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')));

create policy "quiz_options_write_staff" on quiz_options
  for all to authenticated
  using (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')))
  with check (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')));

-- Déclenchement / fermeture d'une session live réservés formateur/admin
create policy "live_quiz_sessions_insert_staff" on live_quiz_sessions
  for insert to authenticated
  with check (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')));

create policy "live_quiz_sessions_update_staff" on live_quiz_sessions
  for update to authenticated
  using (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')))
  with check (exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin')));

-- Réponses : chacun écrit/lit les siennes, le staff peut tout lire
create policy "live_quiz_responses_insert_own" on live_quiz_responses
  for insert to authenticated
  with check (auth.uid() = user_id);

create policy "live_quiz_responses_select_own_or_staff" on live_quiz_responses
  for select to authenticated
  using (
    auth.uid() = user_id
    or exists (select 1 from users u where u.id = auth.uid() and u.role in ('formateur', 'admin'))
  );

-- Realtime : c'est cette ligne qui permet au popup d'apparaître
-- instantanément chez tout le monde dès l'insertion d'une session 'active'.
alter publication supabase_realtime add table live_quiz_sessions;
DARTEOF

echo "Terminé : fichiers créés/écrasés."