# Frontend — À reprendre plus tard (Dev B / intégration)

Ce fichier regroupe tout ce qui a été évoqué côté Flutter pendant la conception
du backend, pour ne pas le perdre. Rien ici n'est urgent tant que le backend
n'est pas stabilisé.

## 1. Initialisation Supabase (`main.dart`)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://<ton-projet>.supabase.co',
    anonKey: '<ta-anon-key>',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;
```

⚠️ URL/clé à mettre dans `.env` (via `flutter_dotenv`) ou `--dart-define`,
jamais en dur dans un fichier commité.

## 2. Repository Auth

```dart
class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nom,
    required String prenom,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'nom': nom, 'prenom': prenom}, // lu par le trigger handle_new_auth_user
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;
}
```

Important : le champ `data: {'nom': ..., 'prenom': ...}` doit correspondre
exactement à ce que lit le trigger SQL `handle_new_auth_user`
(`raw_user_meta_data->>'nom'`), sinon `nom`/`prenom` resteront vides dans
`public.users`.

## 3. Redirection GoRouter selon l'état d'auth

```dart
final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges),
    redirect: (context, state) {
      final isLoggedIn = authRepo.currentUser != null;
      final isAuthRoute = state.matchedLocation == '/login'
          || state.matchedLocation == '/register'
          || state.matchedLocation == '/splash';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [/* ... */],
  );
});
```

`GoRouterRefreshStream` reste à écrire : wrapper `ChangeNotifier` autour d'un
`Stream` (pattern standard, pas fourni nativement par GoRouter).

## 4. À faire plus tard (liste ouverte)

- Repository par domaine (`ClassRepository`, `ActivityRepository`,
  `SubmissionRepository`, `PlacementRepository`, etc.), un par table/domaine
  du schéma backend.
- Écran de quiz de placement : ne jamais afficher `est_correcte` avant que le
  membre ait répondu (voir note dans `rls_policies.sql` — nécessitera une vue
  ou une RPC dédiée côté backend).
- Écran de classement basé sur la vue `leaderboard`.
- Providers Riverpod par repository.