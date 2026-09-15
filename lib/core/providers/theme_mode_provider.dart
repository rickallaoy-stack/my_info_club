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
