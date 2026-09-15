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
