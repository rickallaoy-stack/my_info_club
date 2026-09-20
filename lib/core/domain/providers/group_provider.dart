import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Représente le groupe/segment sélectionné pour l'application.
/// Valeurs libres (string) pour rester flexibles selon le back-end.
final currentGroupProvider = StateProvider<String>((ref) => 'membre');
