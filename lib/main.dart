import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/constants/env.dart';
import 'core/domain/providers/group_provider.dart';
import 'features/auth/domain/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env', isOptional: true);

  if (!Env.validateOrWarn()) {
    runApp(const ProviderScope(child: ClubInfoApp(isConfigured: false)));
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: _GroupBootstrap(child: ClubInfoApp()),
    ),
  );
}

/// Met à jour le groupe dès que le profil est chargé,
/// sans bloquer l'affichage de l'app.
class _GroupBootstrap extends ConsumerWidget {
  const _GroupBootstrap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(currentProfileProvider, (previous, next) {
      final profile = next.valueOrNull;
      if (profile == null) return;

      String? group;
      try {
        group = (profile as dynamic).group as String?;
      } catch (_) {
        group = null;
      }

      if (group != null && group.isNotEmpty) {
        Future.microtask(() {
          ref.read(currentGroupProvider.notifier).state = group!;
        });
      }
    });

    return child;
  }
}