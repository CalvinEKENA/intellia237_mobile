# Chaînes françaises en dur — inventaire et plan

Relevé du 21 septembre 2026 sur `fix/release-hardening-sep2026` (après le commit
`2af61db`). Outil : `tool/hardcoded_french_audit.dart` (détecteur de littéraux
français), étendu ponctuellement aux couches non présentation pour cet
inventaire. Aucune traduction en masse n’a été faite : ce document fixe
l’ordre, le registre et le garde-fou.

## Règles

- **Élève → tu. Parent → vous. Personnel d’établissement et Studio → vous.**
- Toute chaîne visible passe par les ARB (`lib/l10n/app_fr.arb` et
  `app_en.arb`), les deux langues dans le même commit.
- Aucun message technique n’est affiché tel quel (code Firebase, exception,
  nom de champ) : un texte humain plus un code de diagnostic.
- Le terme public est **Parcours / Mon parcours** en français et
  **Learning Path / My Learning Path** en anglais. Les identifiants
  techniques `flow*` restent inchangés.

## Garde-fou en place

`test/l10n/hardcoded_french_audit_test.dart` :

1. `auth`, `notifications` et `profile` doivent rester à zéro ;
2. **cliquet par fonctionnalité** : un plafond ne peut que baisser, une
   fonctionnalité absente de la table doit rester à zéro.

| Fonctionnalité | Plafond au 21/09 | Public |
| --- | ---: | --- |
| `campus` | 158 | établissement (vous) |
| `admin` | 153 | équipe interne (vous) |
| `learn` | 28 | élève (tu) |
| `onboarding` | 28 | élève (tu) |
| `student_registration` | 5 | élève (tu) |
| `flow` (Parcours) | **0** (était 5, traduit dans `2af61db`) | élève (tu) |

Portée du détecteur : fichiers `presentation/` et `core/widgets/`. Total
actuel : **372** littéraux.

## Ce que le détecteur ne voit pas encore

Les couches `application/`, `domain/` et `data/` produisent aussi du texte
affiché. Relevé complémentaire (même heuristique) : **705** littéraux, dont une
grande partie est légitime (données, mots-clés de correspondance, contenu de
démonstration). Le tri :

| Fichier | Littéraux | Nature | Action |
| --- | ---: | --- | --- |
| `ai_companion/data/cloud_ai_repository.dart` | 20 | **messages d’erreur du compagnon, visibles par l’élève** | P1 : passer en ARB (tu), garder les codes `TUTOR-*` |
| `ai_companion/application/ai_companion_controller.dart` | 12 | idem (quota, profil, indisponibilité) | P1 |
| `auth/domain/firebase_error_mapper.dart` | 26 | erreurs d’authentification élève et parent | P1 : registre selon le rôle |
| `greetings/domain/local_greeting_engine.dart` | 50 | salutations du compagnon | P2 : vérifier la variante EN |
| `tutor/domain/tutor_persona.dart` | 20 | descriptions de Kira et Léo | P2 |
| `tour_guide/domain/role_tour_steps.dart` | 20 | visite guidée par rôle | P2 |
| `student_registration/data/establishment_catalog.dart` | 128 | noms d’établissements (données) | aucune : ce sont des noms propres |
| `flow/data/flow_demo_content.dart` | 108 | contenu de démonstration | aucune tant qu’il reste derrière le mode démo |
| `campus/data/demo/demo_campus_fixtures.dart` | 61 | données de démonstration | aucune |
| `interactive_learning/domain/interaction_policy.dart` | 13 | mots-clés de matières pour choisir l’activité | aucune : correspondance, jamais affichée |

## Surfaces élève — détail (priorité)

`learn` (28) : états d’erreur de médias (`content_block_view.dart`,
`lesson_pdf_view.dart`, `audio_overview_player.dart`), lecteur vidéo en
**bilingue collé** (« Réessayer / Retry », « Plein écran / Full screen » dans
`educational_video_player.dart`) à scinder en deux clés, préparation de
chapitre (`chapter_detail_screen.dart`) et trois messages de validation de
`pythagoras_visual.dart` qui sont des erreurs de contenu (à journaliser, pas à
afficher).

`onboarding` (28) : textes de mise en scène de la campagne
(`campaign_scenes.dart`, `campaign_challenge.dart`, `onboarding_screen.dart`).
Une ligne anglaise est déjà codée en dur à côté de sa version française
(`campaign_scenes.dart`, « Léo. Understanding through practice. ») : le
sélecteur de langue existe donc localement, il faut le remplacer par l’ARB.

`student_registration` (5) : `establishment_search_field.dart` **vouvoie**
l’élève (« Contactez votre établissement », « Nom ou ville de votre
établissement ») : à passer au tutoiement en même temps que l’ARB.

## Surfaces parent

Pas de littéral détecté dans `parent/presentation`. Les erreurs d’auth
partagées (`firebase_error_mapper.dart`) restent à traiter (P1 ci-dessus).

## Établissement, équipe interne, Studio

`campus` (158) et `admin` (153) : outils de personnel, français d’abord ; à
traiter après l’élève. Les plus gros fichiers : `campus_localizations.dart`
(65, table de traduction maison à fusionner dans l’ARB),
`course_page_import_screen.dart` (38), `flow_composer_screen.dart` (35).

INTELLIA Studio (`apps/intellia_studio`) : **606** littéraux, application
Windows interne en français uniquement, avec `studio_localization.dart` comme
début de table. Hors périmètre de la version mobile.

## Ordre proposé

1. **P1 élève, lot 1** : messages d’erreur du compagnon et de
   l’authentification (≈ 58 chaînes) — c’est ce qu’un élève anglophone voit
   quand quelque chose échoue.
2. **P1 élève, lot 2** : `learn` (28) et `student_registration` (5), avec le
   passage au tutoiement.
3. **P2** : `onboarding` (28), salutations, personas, visite guidée.
4. **P3** : `campus`, `admin`, puis Studio.

À chaque lot : ARB FR et EN, test widget dans les deux langues à 360 px, et
baisse du plafond correspondant dans le cliquet. Étendre le détecteur aux
couches `application/` et `data/` une fois le lot 1 fait, avec une liste
d’exclusion explicite pour les fichiers de données.
