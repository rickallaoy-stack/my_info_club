import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/live_quiz_provider.dart';
import 'live_quiz_popup.dart';

/// À poser une seule fois, tout en haut de l'arbre (dans `app.dart`,
/// à l'intérieur du `MaterialApp.router` via `builder`).
///
/// Écoute `activeLiveQuizSessionProvider` : dès qu'une session passe à
/// 'active' (déclenchée par un formateur/admin), ouvre le popup en
/// `showDialog` non-annulable par-dessus l'écran courant, quel qu'il soit.
class LiveQuizOverlay extends ConsumerStatefulWidget {
  const LiveQuizOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LiveQuizOverlay> createState() => _LiveQuizOverlayState();
}

class _LiveQuizOverlayState extends ConsumerState<LiveQuizOverlay> {
  String? _shownForSessionId;

  @override
  Widget build(BuildContext context) {
    ref.listen(activeLiveQuizSessionProvider, (previous, next) {
      final session = next.valueOrNull;
      if (session == null) return;
      if (_shownForSessionId == session.id) return; // déjà affiché pour cette session

      _shownForSessionId = session.id;
      _openPopup(session.id, session.quizId);
    });

    return widget.child;
  }

  void _openPopup(String sessionId, String quizId) {
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog(
      context: navigator.context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final quizAsync = ref.watch(quizDetailProvider(quizId));
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: quizAsync.when(
                data: (quiz) => LiveQuizPopup(sessionId: sessionId, quiz: quiz),
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, __) => SizedBox(
                  height: 120,
                  child: Center(child: Text('Impossible de charger le quiz : $err')),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
