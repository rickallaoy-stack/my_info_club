import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/live_quiz_entities.dart';
import '../../domain/providers/live_quiz_provider.dart';

/// Contenu du popup de quiz live : une question à la fois, on avance
/// au clic sur une réponse. Pas de retour arrière (c'est du direct).
class LiveQuizPopup extends ConsumerStatefulWidget {
  const LiveQuizPopup({super.key, required this.sessionId, required this.quiz});

  final String sessionId;
  final Quiz quiz;

  @override
  ConsumerState<LiveQuizPopup> createState() => _LiveQuizPopupState();
}

class _LiveQuizPopupState extends ConsumerState<LiveQuizPopup> {
  int _index = 0;
  QuizOption? _selected;
  bool _submitting = false;

  QuizQuestion get _question => widget.quiz.questions[_index];
  bool get _isLast => _index == widget.quiz.questions.length - 1;

  Future<void> _select(QuizOption option) async {
    if (_selected != null) return; // déjà répondu à cette question
    setState(() {
      _selected = option;
      _submitting = true;
    });

    try {
      await ref.read(liveQuizRepositoryProvider).submitAnswer(
            sessionId: widget.sessionId,
            questionId: _question.id,
            option: option,
          );
    } catch (_) {
      // On n'interrompt pas l'expérience du quiz pour une erreur réseau
      // ponctuelle sur l'enregistrement de la réponse.
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (_isLast) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _index++;
        _selected = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.quiz.questions.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('Ce quiz ne contient aucune question.')),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text('Quiz en direct', style: textTheme.titleMedium)),
              Text(
                '${_index + 1}/${widget.quiz.questions.length}',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(_question.statement, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ..._question.options.map((option) {
            final isSelected = _selected?.id == option.id;
            final showResult = _selected != null;
            final isCorrectOption = option.isCorrect;

            Color? tileColor;
            if (showResult) {
              if (isCorrectOption) {
                tileColor = Colors.green.withValues(alpha: 0.15);
              } else if (isSelected) {
                tileColor = Colors.red.withValues(alpha: 0.15);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Material(
                color: tileColor ?? colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: _submitting ? null : () => _select(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(child: Text(option.label, style: textTheme.bodyMedium)),
                        if (showResult && isCorrectOption)
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        if (showResult && isSelected && !isCorrectOption)
                          const Icon(Icons.cancel, color: Colors.red, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
