import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/learning_levels.dart';
import '../../../auth/domain/providers/auth_provider.dart';

class PlacementResultScreen extends ConsumerWidget {
  final LearningLevel level;

  const PlacementResultScreen({required this.level, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ton niveau')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_outlined, size: 64),
              const SizedBox(height: AppSpacing.md),
              Text(
                level.label,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Ce résultat sert de point de départ. Le formateur pourra ensuite suivre et ajuster ta progression.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () async {
                  final preferences = await SharedPreferences.getInstance();
                  final userId = ref.read(currentUserProvider)?.id;
                  if (userId == null) return;
                  await preferences.setBool(
                    'placement_completed_$userId',
                    true,
                  );
                  if (context.mounted) context.go('/dashboard');
                },
                child: const Text('Accéder à mon espace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
