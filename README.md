# Plateforme du Club Informatique — Section Développement Mobile

Version pilote V1 · Suivi d'état et de logique du projet
Dernière mise à jour : 12 septembre 2026

> Ce README sert de tableau de bord vivant : à chaque avancée, on coche les cases,
> on met à jour le statut des tâches et on note les décisions prises.

---

## 1. Vision du projet

Plateforme permettant, pour la section Développement Mobile du club :
suivi des membres, gestion des classes, séances, dépôt d'activités,
validation des compétences, suivi de progression.

**Principe central : Progression = preuves + validation + feedback.**

---

## 2. Stack technique

| Couche | Choix |
|--------|-------|
| Framework | Flutter / Dart |
| State management | Riverpod |
| Navigation | GoRouter |
| Backend | Supabase (Auth, DB, Storage) |
| Base de données | PostgreSQL |
| Versioning | GitHub |

---

## 3. Équipe & répartition

| Rôle | Responsable | Périmètre |
|------|-------------|-----------|
| Dev A | — | Architecture, backend, Supabase, PostgreSQL, Auth, Storage, Riverpod, repositories, sécurité, permissions |
| Dev B | Ryk | UI/UX, widgets, dashboard, parcours, écrans, responsive |

**Règle de revue** : chaque Pull Request est relue par l'autre développeur avant merge.

---

## 4. Architecture du code

Architecture feature-first, chaque feature suit un découpage data / domain / presentation.

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── router.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── services/
│   ├── errors/
│   ├── utils/
│   └── widgets/
└── features/
    ├── auth/
    ├── dashboard/
    ├── classes/
    ├── learning_path/
    ├── skills/
    ├── activities/
    ├── submissions/
    ├── trainer/
    ├── sessions/
    └── profile/
```

---

## 5. Modèle de données (résumé)

Tables principales :

`users`, `sections`, `classes`, `class_members`, `class_trainers`,
`learning_paths`, `levels`, `skills`, `activities`, `submissions`,
`evaluations`, `skill_validations`, `sessions`, `attendance`.

---

## 6. État d'avancement

Légende : ⬜ à faire · 🟨 en cours · ✅ terminé

| Tâche | Responsable | Priorité | Statut |
|-------|-------------|----------|--------|
| Architecture du projet Flutter | Dev A | P0 | ✅ |
| Config Supabase | Dev A | P0 | ✅ |
| Auth (login/register/session) | Dev A | P0 | ✅ |
| GoRouter + redirections auth | Dev A | P0 | ✅ |
| UI Dashboard | Dev B | P0 | 🟨 |
| Classes et sessions | Dev A | P0 | 🟨 |
| Parcours / Niveaux / Compétences | Dev B | P0 | 🟨 |
| Sondage + quiz de placement | Dev A | P0 | 🟨 |
| Activités + Remise | Dev A | P0 | ⬜ |
| Validation compétences | Dev A | P0 | ⬜ |
| Points de compétences et paliers | Dev A | P0 | 🟨 |
| Espace Formateur | Dev B | P0 | 🟨 |
| Tests | Les deux | P0 | ⬜ |
| Repo GitHub + CI | — | P1 | ✅ (connecté au dépôt GitHub) |

---

## 7. Planning (4 semaines)

- **Semaine 1** — Architecture, base de données, auth, navigation → *Connexion fonctionnelle*
- **Semaine 2** — Dashboard, classe, parcours, compétences → *Progression visible*
- **Semaine 3** — Activités, remise, formateur, validations → *Cycle activité → validation complet*
- **Semaine 4** — Tests, bugs, sécurité, optimisation → *Version pilote stable*

---

## 8. Règles de travail

1. Commits fréquents.
2. Une fonctionnalité = une branche (`feature/...`).
3. Pas de code non relu.
4. Stabiliser avant d'ajouter.
5. Tester chaque jour.
6. Point quotidien de 10 min : *Qu'ai-je terminé ? Mon blocage ? Ma prochaine tâche ?*

**Convention de commits** : `feat:`, `fix:`, `refactor:`, `docs:`, `test:`

---

## 9. Lancer l'app

Le script `run_dev.sh` (macOS/Linux) ou `run_dev.ps1` (Windows) ne sont pas les seules façons de démarrer l'application.

> **Important Windows** : `run_dev.sh` est un script bash. Sur Windows, utilisez `run_dev.ps1` (PowerShell) ou lancez la commande `flutter run` directement.

### Option 1 — Scripts locaux

```bash
# macOS / Linux
./run_dev.sh                # Chrome (web)
./run_dev.sh android        # Android (émulateur ou device)

# Windows
.\run_dev.ps1               # Chrome (web)
.\run_dev.ps1 -Device android   # Android
```

### Option 2 — VS Code launch

Copier `.env.example` en `.env`, renseigner les deux valeurs, puis lancer
directement `lib/main.dart` avec le profil VS Code. Le fichier `.env` est ignoré
par Git et est chargé automatiquement au démarrage.

### Option 3 — commande manuelle

```bash
# Web (Chrome)
flutter run -d chrome \
  --web-port=9090 \
  --dart-define=SUPABASE_URL=https://lmabxhlwgynujhfrjwqm.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_byrAlN288EeOpRzTmVVimQ_NUgLXWSB

# Mobile (Android — émulateur ou device connecté)
flutter run -d android \
  --dart-define=SUPABASE_URL=https://lmabxhlwgynujhfrjwqm.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_byrAlN288EeOpRzTmVVimQ_NUgLXWSB
```

### Option 4 — [.env.example](.env.example)

Un exemple de configuration est fourni dans le dépôt. Copiez-le localement :

```bash
copy .env.example .env
```

Puis remplacez les valeurs par celles de votre projet Supabase.

> **Note** : l'application charge `.env` automatiquement pour les lancements locaux depuis l'IDE. `--dart-define` reste supporté en CI et pour les builds où aucun fichier `.env` n'est disponible. Le projet valide les variables au démarrage et affiche un message explicite si elles sont manquantes.

---

## 10. Configuration e-mails Supabase (no-reply)

Pour que les mails d'authentification (inscription, réinitialisation de mot de passe, confirmation) partent correctement, configurer dans le dashboard Supabase :

1. Ouvrir le projet Supabase du club.
2. Aller dans `Authentication` > `Settings` > `SMTP`.
3. Choisir un fournisseur SMTP ou le mode `Custom SMTP`.
4. Définir l'expéditeur comme un e-mail no-reply de confiance, par exemple :
   `no-reply@clubinformatique.fr`
5. Vérifier que le domaine est bien validé et que l'adresse d'envoi est autorisée.
6. Enregistrer puis tester un mail de réinitialisation.

Pour la réinitialisation de mot de passe, le mail est envoyé depuis Supabase Auth et le bouton de l'application déclenche `resetPasswordForEmail(email)`.

---

## 11. Journal de décisions

- Architecture feature-first retenue pour isoler Supabase du reste du code.
- Projet connecté sur GitHub et prêt pour travail collaboratif.
- Auth branché sur le vrai projet Supabase.
- Ajout du flux « Mot de passe oublié » dans l'écran de connexion.
- Ajout d'une configuration de lancement VS Code pour démarrer sans `run_dev.sh`.
- Ajout de `run_dev.ps1` pour Windows et support du mobile dans les scripts.
- Dashboard relié au profil Supabase et déconnexion fonctionnelle ; les modules métier restent à construire.
- Espace formateur séparé avec liste des étudiants autorisés par la RLS et consultation de leur profil.
- Les prochaines sessions de la classe de l'étudiant sont maintenant chargées depuis Supabase.
- Les niveaux pédagogiques sont standardisés en quatre étapes : Débutant, Novice, Intermédiaire et Expert.
- Après le splash, un étudiant sans niveau passe par un sondage puis un quiz de placement avant d'accéder à son espace.
- Le parcours de placement est disponible avec calcul initial Débutant, Novice, Intermédiaire ou Expert ; la persistance serveur des tentatives reste à finaliser avec les données de quiz Supabase.
- Les formateurs peuvent attribuer des points historisés pour les réalisations, la compréhension des exercices et les mini-hackathons. Les paliers sont fixés à 100, 250 et 500 points.
- Le consentement d'inscription est séparé en deux cases, lié aux versions des documents et enregistré avec le profil utilisateur lors de la création du compte.
