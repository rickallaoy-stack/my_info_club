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
