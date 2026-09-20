import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/learning_levels.dart';

import '../core/utils/go_router_refresh_stream.dart';
import '../features/auth/domain/providers/auth_provider.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/legal_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/sections/presentation/section_picker_screen.dart';
import '../features/trainer/presentation/screens/student_profile_screen.dart';
import '../features/placement/presentation/screens/placement_survey_screen.dart';
import '../features/placement/presentation/screens/placement_quiz_screen.dart';
import '../features/placement/presentation/screens/placement_result_screen.dart';

/// Provider central du routeur.
/// Le splash décide de la première destination après le chargement initial.
/// Ensuite, le routeur protège les écrans privés et garde les écrans publics
/// accessibles quel que soit l'état de connexion.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLoggedIn = authRepository.currentUser != null;
      final isSplash = location == '/';
      final isPublic = location == '/login' ||
          location == '/register' ||
          location == '/privacy-policy' ||
          location == '/terms';

      // Ne pas court-circuiter le splash : il garantit un écran stable pendant
      // la restauration de session Supabase.
      if (isSplash) return null;

      // Rediriger vers login si non connecté et route protégée
      if (!isLoggedIn && !isPublic) return '/login';

      // Rediriger utilisateur connecté loin des pages d'auth
      if (isLoggedIn && (location == '/login' || location == '/register')) {
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
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const LegalScreen(
          title: 'Politique de confidentialité',
          content: LegalPages.privacyPolicy,
        ),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const LegalScreen(
          title: 'Conditions générales',
          content: LegalPages.terms,
        ),
      ),
      GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen()),
      GoRoute(
        path: '/sections',
        builder: (context, state) => const SectionPickerScreen(),
      ),
      GoRoute(
        path: '/placement/survey',
        builder: (context, state) => const PlacementSurveyScreen(),
      ),
      GoRoute(
        path: '/placement/quiz',
        builder: (context, state) => PlacementQuizScreen(
          survey: state.extra! as PlacementSurveyAnswers,
        ),
      ),
      GoRoute(
        path: '/placement/result',
        builder: (context, state) => PlacementResultScreen(
          level: state.extra! as LearningLevel,
        ),
      ),
      GoRoute(
        path: '/trainer/students/:studentId',
        builder: (context, state) => StudentProfileScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      // TODO: /classes, /learning-path, /skills, /activities, /submissions,
      // /trainer/*, /sessions, /profile — à ajouter au fur et à mesure des features.
    ],
  );
});