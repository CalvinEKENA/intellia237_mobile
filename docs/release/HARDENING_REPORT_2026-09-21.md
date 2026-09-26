# Durcissement de version — rapport du 21 septembre 2026

**Rien n’a été déployé.** Pas de `firebase deploy`, pas de `gcloud deploy`, pas
d’envoi Play, pas d’AAB final, numéro de version inchangé (`3.2.1+30`, hérité
de `fix/family-auth-parent-child`). Gemini 3.8 Flash et
`GEMINI_TUTOR_THINKING_LEVEL=HIGH` inchangés.

## Branches

| | |
| --- | --- |
| Audit de départ | `edu/le-savoir-tenant` @ `db45f3d` |
| Base de travail | `fix/family-auth-parent-child` @ `5e4f797` (auth famille, codes d’accès élève, migration du téléphone familial) |
| Branche de travail | `fix/release-hardening-sep2026` (worktree `Intellia237_worktrees/hardening`) |
| Consolidation | `67a71ac` fusionne `db45f3d` : une seule source Functions / règles / index |
| Contenu | `main`, `edu/le-savoir-tenant` et `fix/family-auth-parent-child` sont entièrement contenues ; seule `safety/before-history-cleanup` (2 commits, copie de sauvegarde d’avant réécriture) ne l’est pas, volontairement |

Aucune branche détruite, aucun worktree modifié en dehors de `hardening`.

## Points de l’audit

| Point | Statut | Commit |
| --- | --- | --- |
| P0 Branches divergentes (production = union des deux) | **CORRIGÉ** | `67a71ac` |
| P0 Persona tuteur injectable, jetons non bornés | **CORRIGÉ** | `8999c63` |
| P0 `establishmentId` auto-déclaré à la création | **CORRIGÉ** | `b98573a` |
| P1 `generateQuiz` / `generateSummary` ouvertes | **CORRIGÉ** (plus exportées) | `261af5f` |
| P1 Suppression de compte jamais traitée | **CORRIGÉ** | `a5bdb7b`, `5fbe813` |
| P1 Annonces « Parents » | **INFIRMÉ** sur la branche famille (routage par liens enfants approuvés déjà présent) ; tests ajoutés | `ee58a0f` |
| P1 Délai client 45 s = délai LLM | **CORRIGÉ** (45 s < 75 s < 90 s) | `19b9858` |
| P1 `getEnv()` silencieux | **CORRIGÉ** (échec immédiat en production, sans afficher les valeurs) | `25819d9` |
| P1 Parcours télécharge tout | **CORRIGÉ** (pagination bornée, index derrière drapeau) | `9272278` |
| P1 Studio `_handleHttpError` | **CORRIGÉ** | `3d2a05b` |
| P1 Prompt sans protection des mineurs ni langue EN | **CORRIGÉ** | `8999c63` |
| P1 `allowBackup` | **CORRIGÉ** | `3951c2e` |
| P1 Studio hors CI / App Check | Studio en CI **CORRIGÉ** (`7b104ef`) ; App Check **REPORTÉ** (voir plus bas) | |
| P2 `Math.random` pour le code de liaison | **INFIRMÉ** sur la branche famille (CSPRNG) ; garde-fou ajouté | `3951c2e` |
| P2 Règles à resserrer | **CORRIGÉ** | `71cd654` |
| P2 377 chaînes en dur | **PARTIEL** : Parcours traduit, cliquet par fonctionnalité, inventaire | `2af61db`, `3ad0f27` |
| P2 Crashlytics opt-in | **CONFIRMÉ**, documenté, politique inchangée | `3ad0f27` |
| P2 Coût de l’historique | **CORRIGÉ** (fenêtre bornée) ; résumé glissant **REPORTÉ** (proposition) | `8999c63`, `3ad0f27` |
| P2 Étiquetage maîtrise | **CONFIRMÉ**, **REPORTÉ** (backlog V2) | `3ad0f27` |
| P2 Ressources | **CONFIRMÉ**, rien supprimé (inventaire) ; licence Barlow ajoutée | `3ad0f27`, `b31e919` |
| P2 Documentation en retard | **CORRIGÉ** (README, `.env.example`, App Check) | |
| P2 Déclencheurs CI | **CORRIGÉ** | `7b104ef`, `563ac32` |

Trouvés pendant la mission : accents corrompus dans les erreurs de
publication (`613026f`), octets de contrôle bruts écrits dans deux fichiers
(`b0d462a`), code d’erreur Parcours trompeur après un changement d’école
(`0241bfb`, suite d’intégration qui n’était lancée nulle part), test Storage
lié à un port codé en dur (`b519b86`), remarques d’analyse Studio créées par
le formatage (`f30cd46`).

## Stratégies

**Kira et Léo.** Le téléphone n’envoie que `tutorId` ; persona, pédagogie,
règles de sécurité pour mineurs, langue (depuis le profil) et format sont
construits par le serveur. Détail : `docs/architecture/COMPANION_CONTEXT_BUDGET.md`.

**Limites.** Message 2 000 caractères ; fenêtre de 8 messages × 1 200, 6 000
au total ; contexte de leçon 5 000 ; prompt système 7 000 ; entrée au pire cas
22 000 caractères ; sortie 8 192 jetons (import de pages 32 768).

**Idempotence.** `requestId` réutilisé par « Réessayer » ; registre
`tutor_requests` (empreinte SHA-256, 15 min, 2 exécutions) ; réponse en cache
rejouée, requête en cours attendue ; quota consommé seulement si le
fournisseur a pu facturer.

**Établissement.** Aucun `establishmentId` accepté à la création côté client ;
rattachement et changement par le serveur (super-administration, motif
tracé).

**Suppression de compte.** 7 jours de grâce annulables, traitement horaire
avec bail, reprises 1 h / 6 h / 24 h / 72 h puis `needs_attention`, pierre
tombale minimale, Auth supprimé en dernier ; anciennes demandes `pending`
jamais traitées automatiquement (décision du propriétaire). Détail :
`docs/architecture/ACCOUNT_DELETION.md`.

**Annonces parents.** Via les liens enfants approuvés, vers l’école de chaque
enfant, une fois par parent, jamais vers les parents d’une autre école.

**Parcours.** Serveur : 30 cartes par page, lots de 50, 200 documents lus au
plus, lectures de leçons mémorisées ; mode indexé `audienceKeys` derrière
`FLOW_AUDIENCE_INDEX` (faux par défaut). Client : fenêtre de 12, préchargement
à 4 de la fin, 2 pages au plus par chargement, arrêt après 3 échecs, cache
de 60.

**App Check.** Client en mode surveillance ; aucune callable n’impose App
Check. Blocages documentés : Studio Windows sans fournisseur d’attestation,
APK installés hors Play qui échouent Play Integrity
(`docs/security/APP_CHECK_ROLLOUT.md`).

**Sauvegarde Android.** `allowBackup=false`, règles d’extraction et de
sauvegarde qui excluent tout ; vérifié dans le manifeste fusionné d’un APK de
debug et par `test/platform/android_backup_policy_test.dart`.

## Blocs d’apprentissage interactifs

Architecture, types, validation, hors ligne, intégration :
`docs/architecture/INTERACTIVE_LEARNING_BLOCKS.md`. En bref : le modèle propose
un contenu, le serveur valide et fabrique les identifiants, l’application
rend avec ses widgets ; `word_order` (tuiles, toucher-déplacer,
glisser-déposer) et cinq ordres empilés (étapes, équations, frise, processus,
séquence) ; correction hors ligne ; résultat renvoyé une fois au compagnon ;
contrat serveur ↔ app verrouillé par une fixture commune. Choix par matière :
`word_order` n’apparaît jamais en mathématiques, histoire, SVT ou physique.

Tests ajoutés : 16 serveur (`interactiveBlocks.test.ts`), 12 domaine,
9 rendu (360 px, texte 2×, glisser-déposer, accessibilité, frise), 7
conversation, 2 contrat. Restent : les autres primitives, la rédaction dans
Studio, la correction serveur pour un usage noté, une capture sur appareil
avec TalkBack.

## Expérience d’apprentissage

Apprendre et Quiz ont chacun leur en-tête et leur état indisponible
(`9e6a7b2`) :

- Apprendre : « Tes matières ne sont pas disponibles pour le moment » ;
- Quiz : « Tes quiz ne sont pas disponibles pour le moment », avec les modes
  Entraînement et Évaluation annoncés ;
- les deux proposent « Réessayer » et « Continuer mon parcours » ; version
  hors ligne distincte ; aucun code technique affiché (journalisé seulement).

Terme public : Parcours / Mon parcours, Learning Path en anglais ; aucun
« Flow » visible (test EN ajouté dans `2af61db`) ; identifiants techniques
inchangés. Navigation à 5 onglets conservée. INTELLIA PASS n’est présent que
dans l’accueil et l’inscription, pas dans Apprendre ni Quiz.

## Vérifications

| Suite | Résultat |
| --- | --- |
| `flutter analyze` (lib, test, tool) | aucun problème |
| `flutter test` | 1550 / 1550 |
| `dart format` (app et Studio) | aucun changement |
| Functions `vitest` | 352 / 352 |
| Functions `tsc` | propre |
| Règles (émulateur) | Firestore 61, Storage 9, ressources 16 |
| Intégration (émulateur) | famille 17, réserve d’étude 8, annonces 4, suppression 7, Parcours 6, comptes admin 4, publication de leçons 9 |
| Studio | `flutter analyze` propre, 55 / 55 |

Suites d’émulateurs lancées en local sur des ports alternatifs (un émulateur
d’une autre session occupait les ports par défaut) ; la CI utilise les ports
de `firebase.json`.

## À déployer (par le propriétaire)

1. **Secrets et IAM** (branche famille) : secret `STUDENT_ACCESS_CODE_PEPPER`,
   rôle `roles/iam.serviceAccountTokenCreator` au compte de service.
2. **Vérifier `functions/.env` de production** : la configuration échoue
   désormais au démarrage si une valeur est invalide (par exemple
   `GEMINI_TUTOR_THINKING_LEVEL` hors LOW/MEDIUM/HIGH).
3. **Functions** depuis cette branche seulement (source unique). Nouvelles
   par rapport à la famille : `cancelAccountDeletion`,
   `getCompanionRuntimeConfig`, `manageEstablishment`, `manageSchoolClass`,
   `processAccountDeletions` ; par rapport au Studio :
   `createChildStudentAccess`, `issueStudentAccessCode`,
   `listParentChildren`, `migrateStudentPhoneToParent`,
   `signInWithStudentAccessCode`. **À supprimer** : `generateQuiz`,
   `generateSummary`.
4. **Règles Firestore** et **index** (`account_deletion_requests (status,
   dueAt)`, `flow_items (status, audienceKeys, publishedAt, __name__)`).
5. **Parcours indexé**, plus tard : `backfillFlowAudienceKeys` à blanc, puis
   `--apply`, puis `FLOW_AUDIENCE_INDEX=true`.

Aucune autre migration de données.

## Décisions en attente

Crashlytics (option A recommandée), résumé glissant, pré-requis Maîtrise V2,
suppression des ressources inutilisées, ordre des lots i18n, veto parental
pour la suppression d’un compte mineur, page web de suppression exigée par
Google Play.

## Risques résiduels

- Aucune recette sur appareil de cette branche : QA propriétaire requise
  (famille, compagnon avec activités, Parcours paginé, suppression).
- App Check non imposé.
- Fenêtre de collecte au premier lancement (Crashlytics/Analytics) à vérifier.
- 372 chaînes en dur restantes (surtout établissement et équipe interne) ;
  les messages d’erreur du compagnon restent en français pour un élève
  anglophone.
- `studyMinutesToday` toujours à 0 dans l’écran enseignant.
- Premier déploiement : ordre secrets → Functions → règles → index à
  respecter, sinon l’espace famille se dégrade.
