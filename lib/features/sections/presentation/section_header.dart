import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/sections/section_controller.dart';
import '../../../core/sections/section_theme.dart';

/// Bandeau affiché en haut du dashboard : rappelle la section active,
/// permet d'en changer, et liste le parcours de la section.
class SectionHeader extends ConsumerWidget {
  const SectionHeader({super.key, this.showModules = true});

  final bool showModules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(sectionProvider).value;
    if (section == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = sectionAccent(section, theme.brightness);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, color: accent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ci_ sections/${section.slug}/',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      section.label,
                      style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/sections'),
                child: const Text('Changer'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            section.tagline,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (showModules) ...[
            const SizedBox(height: 16),
            Text(
              'Parcours de la section',
              style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < section.modules.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${i + 1}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        section.modules[i],
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
