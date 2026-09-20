import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';

/// Encapsule tous les appels Supabase liés à l'authentification.
/// Aucune UI ne doit importer `supabase_flutter` directement : tout passe par ici.
class AuthRepository {
  final SupabaseClient _client;
  GoogleSignIn? _googleSignIn;

  AuthRepository(this._client);

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  GoogleSignIn _getGoogleSignIn() {
    _googleSignIn ??= GoogleSignIn(
      serverClientId: const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
    );
    return _googleSignIn!;
  }

  Future<void> initializeGoogleSignIn() async {
    // Lazy initialization - only when actually needed
    _getGoogleSignIn();
  }

  Future<AuthProfile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('users')
          .select(
            'nom, prenom, role, class_id, current_level_id, '
            'levels(nom)',
          )
          .eq('id', user.id)
          .maybeSingle();
      return data == null ? null : AuthProfile.fromJson(data);
    } on PostgrestException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final account = await _getGoogleSignIn().signIn();
      if (account == null) {
        throw Failure('Connexion Google annulée');
      }

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Failure('Impossible de récupérer le token Google');
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
    } on AuthException catch (e) {
      throw Failure(e.message, code: e.code);
    } catch (e) {
      throw Failure('Erreur lors de la connexion Google: $e');
    }
  }

  Future<void> signInAnonymously() async {
    try {
      await _client.auth.signInAnonymously();
    } on AuthException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<void> resetPasswordForEmail({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  /// Inscrit l'utilisateur. Retourne `true` si une session a été créée
  /// immédiatement (confirmation email désactivée), `false` sinon.
  Future<bool> signUp({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required bool acceptedPrivacy,
    required bool acceptedTerms,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'nom': nom,
          'prenom': prenom,
          'privacy_policy_version': '2026-09-14',
          'terms_version': '2026-09-14',
          'privacy_policy_accepted': acceptedPrivacy,
          'terms_accepted': acceptedTerms,
        },
      );
      return response.session != null;
    } on AuthException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    await _client.auth.signOut();
  }

  Future<void> linkAnonymousToEmail({
    required String email,
    required String password,
    required String nom,
    required String prenom,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null || !user.isAnonymous) {
        throw Failure('Aucun utilisateur anonyme à lier');
      }

      await _client.auth.updateUser(
        UserAttributes(email: email, password: password, data: {
          'nom': nom,
          'prenom': prenom,
        }),
      );
    } on AuthException catch (e) {
      throw Failure(e.message, code: e.code);
    }
  }
}

class AuthProfile {
  final String firstName;
  final String lastName;
  final String role;
  final String? classId;
  final String? currentLevelId;
  final String? currentLevelName;

  const AuthProfile({
    required this.firstName,
    required this.lastName,
    required this.role,
    this.classId,
    this.currentLevelId,
    this.currentLevelName,
  });

  factory AuthProfile.fromJson(Map<String, dynamic> json) {
    return AuthProfile(
      firstName: json['prenom'] as String? ?? '',
      lastName: json['nom'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      classId: json['class_id'] as String?,
      currentLevelId: json['current_level_id'] as String?,
      currentLevelName:
          (json['levels'] as Map<String, dynamic>?)?['nom'] as String?,
    );
  }
}