import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import '../core/sections/section_controller.dart';
import '../core/sections/section_theme.dart';
import '../core/theme/app_theme.dart';

class ClubInfoApp extends ConsumerWidget {
  final bool isConfigured;

  const ClubInfoApp({super.key, this.isConfigured = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isConfigured) {
      return MaterialApp(
        title: 'Club Informatique',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Configuration Supabase manquante.\n'
                'Ajoutez les variables SUPABASE_URL et SUPABASE_ANON_KEY, '
                'ou lancez via le script de dev.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final router = ref.watch(appRouterProvider);
    final section = ref.watch(sectionProvider).value;

    return MaterialApp.router(
      title: 'Club Informatique',
      debugShowCheckedModeBanner: false,
      theme: buildSectionTheme(AppTheme.light, section),
      darkTheme: buildSectionTheme(AppTheme.dark, section),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
