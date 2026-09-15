import 'dart:async';
import 'package:flutter/foundation.dart';

/// Convertit un Stream en Listenable pour `GoRouter.refreshListenable`,
/// afin que le router se ré-évalue (et donc redirige) à chaque
/// changement d'état d'authentification.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
