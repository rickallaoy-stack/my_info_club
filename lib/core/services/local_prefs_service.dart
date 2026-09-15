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
