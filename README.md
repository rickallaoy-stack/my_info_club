# Plateforme du Club Informatique — Section Développement Mobile

Version pilote V1 · Suivi d'état et de logique du projet
Dernière mise à jour : *(à mettre à jour à chaque session de travail)*

> Ce README sert de **tableau de bord vivant** : à chaque avancée, on coche les cases,
> on met à jour le statut des tâches et on note les décisions prises. C'est la source
> de vérité entre les deux devs tant que le repo GitHub n'est pas encore en place.

---

## 1. Vision du projet

Plateforme permettant, pour la section Développement Mobile du club :
suivi des membres, gestion des classes, séances, dépôt d'activités,
validation des compétences, suivi de progression.

**Principe central : Progression = preuves + validation + feedback.**

---

## 2. Stack technique

| Couche         | Choix                        |
|----------------|-------------------------------|
| Framework      | Flutter / Dart                |
| State management | Riverpod                   |
| Navigation     | GoRouter                      |
| Backend        | Supabase (Auth, DB, Storage)  |
| Base de données| PostgreSQL                   |
| Versioning     | GitHub *(à mettre en place plus tard)* |

---

## 3. Équipe & répartition

| Rôle    | Responsable | Périmètre |
|---------|-------------|-----------|
| Dev A   | —           | Architecture, backend, Supabase, PostgreSQL, Auth, Storage, Riverpod, repositories, sécurité, permissions |
| Dev B   | —           | UI/UX, widgets, dashboard, parcours, écrans, responsive |

**Règle de revue** : chaque Pull Request est relue par l'autre développeur avant merge.

---

## 4. Architecture du code

Architecture **feature-first**, chaque feature suit un découpage `data / domain / presentation` :

```text
lib/
├── main.dart                      # point d'entrée, init Supabase
├── app/
│   ├── app.dart                   # widget racine (MaterialApp.router)
│   └── router.dart                # config GoRouter (routes centralisées)
├── core/
│   ├── constants/                 # Env (clés Supabase via --dart-define)
│   ├── theme/                     # thème Material 3
│   ├── services/                  # supabaseClientProvider
│   ├── errors/                    # Failure (erreurs génériques)
│   ├── utils/
│   └── widgets/                   # widgets partagés (boutons, cards, etc.)
└── features/
    ├── auth/                      # Splash, Login, Register
    ├── dashboard/                 # Accueil membre / formateur
    ├── classes/                   # Gestion des classes
    ├── learning_path/             # Parcours Flutter, niveaux
    ├── skills/                    # Compétences, critères
    ├── activities/                # Activités à réaliser
    ├── submissions/                # Remises (GitHub, fichier, déclaration IA)
    ├── trainer/                   # Espace formateur (évaluation, validation)
    ├── sessions/                  # Séances + présences
    └── profile/                   # Profil utilisateur
```

Chaque dossier de feature contient :

```text
<feature>/
├── data/
│   ├── models/          # DTOs / mapping Supabase ↔ Dart
│   └── repositories/    # accès Supabase (implémente les interfaces domain)
├── domain/
│   ├── entities/        # objets métier purs (sans dépendance Supabase)
│   └── providers/       # providers Riverpod (state, notifiers)
└── presentation/
    ├── screens/         # écrans (pages)
    └── widgets/         # widgets spécifiques à la feature
```

**Logique de dépendance** : `presentation` → `domain` → `data`.
Les écrans ne parlent jamais directement à Supabase, toujours via un repository exposé par un provider.

---

## 5. Modèle de données (résumé)

Tables principales (voir doc technique complet pour le détail des champs) :

`users`, `sections`, `classes`, `class_members`, `class_trainers`,
`learning_paths`, `levels`, `skills`, `activities`, `submissions`,
`evaluations`, `skill_validations`, `sessions`, `attendance`.

---

## 6. État d'avancement

Légende : ⬜ à faire · 🟨 en cours · ✅ terminé

| Tâche                          | Responsable | Priorité | Statut |
|--------------------------------|-------------|----------|--------|
| Architecture du projet Flutter | Dev A       | P0       | ✅ (squelette généré) |
| Config Supabase (projet + clés)| Dev A       | P0       | ⬜ |
| Auth (login/register/session)  | Dev A       | P0       | ⬜ |
| GoRouter + redirections auth   | Dev A       | P0       | 🟨 (routes de base posées, redirect à faire) |
| UI Dashboard                   | Dev B       | P0       | ⬜ |
| Parcours / Niveaux / Compétences| Dev B      | P0       | ⬜ |
| Activités + Remises            | Dev A       | P0       | ⬜ |
| Validation compétences         | Dev A       | P0       | ⬜ |
| Espace Formateur                | Dev B       | P0       | ⬜ |
| Tests                          | Les deux    | P0       | ⬜ |
| Repo GitHub + CI                | —           | P1       | ⬜ (prévu plus tard) |

---

## 7. Planning (4 semaines)

- **Semaine 1** — Architecture, base de données, auth, navigation → *Connexion fonctionnelle*
- **Semaine 2** — Dashboard, classe, parcours, compétences → *Progression visible*
- **Semaine 3** — Activités, remises, formateur, validations → *Cycle activité → validation complet*
- **Semaine 4** — Tests, bugs, sécurité, optimisation → *Version pilote stable*

---

## 8. Règles de travail

1. Commits fréquents.
2. Une fonctionnalité = une branche (`feature/...`).
3. Pas de code non relu (revue croisée obligatoire).
4. Stabiliser avant d'ajouter.
5. Tester chaque jour.
6. Point quotidien de 10 min : *Qu'ai-je terminé ? Mon blocage ? Ma prochaine tâche ?*

**Convention de commits** : `feat:`, `fix:`, `refactor:`, `docs:`, `test:`
Exemple : `feat(auth): login utilisateur`

**Définition de "terminé"** : code écrit → fonctionnel → testé → relu → push → merge.

---

## 9. Hors périmètre (V1)

Chat, IA automatique, badges avancés, statistiques complexes, notifications avancées.

---

## 10. Journal de décisions

*(à compléter au fil de l'eau — une ligne par décision structurante)*

- Architecture feature-first retenue (data/domain/presentation) pour isoler Supabase du reste du code.
- Repo GitHub volontairement reporté à plus tard — développement local d'abord.
