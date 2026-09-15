import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final List<String> content;
  static const documentVersion = 'Version du 14 septembre 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                documentVersion,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 16),
              for (final paragraph in content)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    paragraph,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class LegalPages {
  const LegalPages._();

  static const privacyPolicy = [
    'Responsable du traitement : le Club Informatique. Cette politique décrit les données nécessaires au fonctionnement de la plateforme et à la formation des membres.',
    'Données collectées : nom, prénom, adresse e-mail, rôle, classe, niveau, résultats de quiz, activités, remises, évaluations et points de compétences.',
    'Finalités : créer et sécuriser le compte, organiser les classes et sessions, suivre la progression pédagogique, permettre le suivi par les formateurs et gérer les remises.',
    'Base légale : l’exécution des services demandés par le membre et, lorsque requis, son consentement. Les données ne sont pas utilisées pour de la publicité ciblée.',
    'Destinataires : les administrateurs et formateurs autorisés, uniquement dans le cadre de leurs responsabilités. Les accès sont contrôlés par les règles de sécurité Supabase.',
    'Durée et sécurité : les données sont conservées pendant la durée d’utilisation du compte puis selon les obligations applicables. Des mesures techniques et organisationnelles limitent les accès non autorisés.',
    'Vos droits : accès, rectification, effacement, limitation et opposition lorsque ces droits s’appliquent. Contactez l’administrateur du club pour exercer vos droits ou demander une précision.',
  ];

  static const terms = [
    'En créant un compte, vous confirmez que les informations saisies sont exactes et acceptez d’utiliser la plateforme dans le cadre pédagogique du Club Informatique.',
    'Vous devez conserver votre mot de passe confidentiel, utiliser une adresse e-mail qui vous appartient et signaler tout accès suspect à l’administrateur.',
    'Les contenus, réalisations et remises doivent respecter les règles du club, les droits des tiers et les consignes des formateurs. Les propos abusifs, la fraude et les usages non autorisés sont interdits.',
    'Les points de compétences et niveaux sont des indicateurs pédagogiques. Ils sont attribués selon les réalisations, la compréhension et les activités évaluées par les formateurs.',
    'Les administrateurs peuvent suspendre un compte en cas de risque de sécurité, de fraude ou de violation de ces conditions, en respectant les règles applicables.',
    'Ces conditions peuvent évoluer. Une nouvelle acceptation pourra être demandée lorsqu’une modification importante affecte les droits ou obligations des membres.',
  ];
}
