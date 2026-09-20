import 'package:flutter/material.dart';

/// Les cinq sections du Club Informatique de l'ESATIC.
///
/// Les slugs et les phrases d'accroche viennent du site
/// (clubinfo-esatic.com/sections/<slug>/).
/// Les `modules` sont une proposition de départ : à faire valider
/// par les formateurs de chaque section.
enum ClubSection {
  cybersecurite(
    slug: 'cybersecurite',
    label: 'Cybersécurité',
    tagline: 'Protéger les systèmes, les réseaux et les données.',
    accent: Color(0xFF2ECC71),
    icon: Icons.shield_outlined,
    modules: [
      'Réseaux et systèmes : les bases',
      'Mots de passe et cryptographie',
      'Sécurité web (OWASP)',
      'Analyse de vulnérabilités',
      'Premier CTF',
    ],
  ),
  iot(
    slug: 'iot',
    label: 'IoT',
    tagline: 'Relier capteurs et objets pour mesurer et agir sur le monde réel.',
    accent: Color(0xFF22D3EE),
    icon: Icons.sensors,
    modules: [
      'Électronique et capteurs',
      'Arduino et ESP32',
      'Protocoles : MQTT et LoRa',
      'Tableau de bord de données',
      'Mini-projet connecté',
    ],
  ),
  devWeb(
    slug: 'dev-web',
    label: 'Développement web',
    tagline: 'Concevoir des sites et des applications web.',
    accent: Color(0xFF3B82F6),
    icon: Icons.language,
    modules: [
      'HTML et CSS',
      'JavaScript',
      'Backend et API',
      'Bases de données',
      'Mise en ligne',
    ],
  ),
  devMobile(
    slug: 'dev-mobile',
    label: 'Développement mobile',
    tagline: 'Créer des applications pour Android et iOS.',
    accent: Color(0xFF8B5CF6),
    icon: Icons.phone_android,
    modules: [
      'Dart et bases de Flutter',
      'Widgets et navigation',
      'State management avec Riverpod',
      'API et Supabase',
      'Publier son application',
    ],
  ),
  iaAutomatisation(
    slug: 'ia-automatisation',
    label: 'IA et automatisation',
    tagline: 'Modèles d’intelligence artificielle et automatisation de tâches.',
    accent: Color(0xFFF59E0B),
    icon: Icons.smart_toy_outlined,
    modules: [
      'Python et données',
      'Machine learning',
      'Modèles de langage et prompts',
      'Automatiser avec des scripts et workflows',
      'Mini-projet IA',
    ],
  );

  const ClubSection({
    required this.slug,
    required this.label,
    required this.tagline,
    required this.accent,
    required this.icon,
    required this.modules,
  });

  /// Identifiant stocké en base (profiles.section) et utilisé dans les URLs du site.
  final String slug;
  final String label;
  final String tagline;
  final Color accent;
  final IconData icon;

  /// Parcours de départ affiché dans le dashboard.
  final List<String> modules;

  static ClubSection? fromSlug(String? slug) {
    for (final s in ClubSection.values) {
      if (s.slug == slug) return s;
    }
    return null;
  }
}
