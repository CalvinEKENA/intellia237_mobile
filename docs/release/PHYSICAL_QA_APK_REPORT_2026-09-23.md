# INTELLIA237 — APK de test pour QA physique (23/09/2026)

## Identité du build

| Élément | Valeur |
|---|---|
| Branche | `fix/auth-v2-final-rework` (non poussée) |
| SHA du code compilé | `34b0dcc2039b7c521d0dfb2dab3a909f9bb4878d` |
| Version | `3.2.1+30` (inchangée) |
| Commande | `flutter clean` · `flutter pub get` · `flutter build apk --flavor production -t lib/main_production.dart --release` |
| APK | `build/app/outputs/flutter-apk/app-production-release.apk` |
| Taille | 80 772 974 octets (77,0 Mo) |
| SHA-256 | `874005da0a038e720f61326ed1a201717bb474af011f28c8bc952fa213511889` |
| Projet Firebase | `edunova-aabd1` (production), package `com.edunova.app` |

Aucun AAB, aucun envoi Play, aucun changement de version, aucun déploiement
Firebase, aucune modification gcloud.

## Commits de cette passe

| SHA | Objet |
|---|---|
| `410850e` | V1 sans voix pour KIRA/LEO ; langage 100 % humain sur tous les écrans |
| `dfca24d` | Démarrage instantané ; Apprendre et Quiz ne ressemblent plus à une panne |
| `40698c2` | Parcours : images publiées affichées, notions en fil d'idées animé |
| `2b12156` | Mise en forme (dart format) |
| `34b0dcc` | Configuration Google de production (edunova-aabd1) |

Le présent rapport est commité après le build ; il ne modifie aucun code.

## Suppression de la voix (KIRA/LEO)

- Compositeur « Écrire » uniquement : plus de bouton micro, de dictée,
  d'enregistrement, de transcription, ni de « Écouter » sous les réponses.
- Synthèse vocale (TTS) retirée entièrement, y compris locale.
- Code supprimé : `speech_services.dart`, `dictation_controller.dart`,
  `listen_controller.dart`, `dictation_session.dart`, `spoken_text.dart`,
  `voice_profile.dart` et leurs tests ; chaînes micro/dictée/écoute retirées
  des traductions FR/EN.
- Infrastructure serveur de la voix : aucune. La voix était 100 % sur
  l'appareil ; aucun appel, stockage ou fonction audio n'était lié aux
  compagnons. Les capsules audio des leçons (contenu enseignant,
  `just_audio`, `educationalMedia`) sont conservées.
- Données existantes : aucune migration, rien d'effacé.
- **Écart assumé** : « Montrer » n'est pas exposé. Le tuteur n'accepte pas
  encore d'image (`askTutor` ne reçoit que du texte) ; afficher le bouton
  aurait promis une fonction absente. Le compositeur est donc « Écrire »
  seul en V1.

## Permissions retirées

- `android.permission.RECORD_AUDIO`.
- Déclarations `<queries>` de `android.speech.RecognitionService` et
  `android.intent.action.TTS_SERVICE` (la requête `PROCESS_TEXT` reste).
- iOS : aucune clé micro ou reconnaissance vocale n'était déclarée.
- Permissions restantes du manifeste de l'app : `POST_NOTIFICATIONS`,
  `RECEIVE_BOOT_COMPLETED` (+ celles apportées par les plugins, voir le
  manifeste fusionné ci-dessous).

Vérifié dans l'APK final (`aapt2 dump permissions`) : **aucune permission
micro ou audio**. Présentes : `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`,
`INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `VIBRATE`, `USE_BIOMETRIC`,
`USE_FINGERPRINT`, et celles des services Google (messagerie push, référent
d'installation, identifiant publicitaire des services Analytics).

Signature : certificat SHA-1 `e8f339143076d3ff867ea60d34d16c3e6b96bf2f`,
l'une des empreintes enregistrées pour `com.edunova.app` dans
`google-services.json`. `versionCode` 30, `versionName` 3.2.1.

## Dépendances retirées

- `speech_to_text` ^7.0.0
- `flutter_tts` ^4.2.0

Enregistrements de plugins Windows/macOS régénérés en conséquence.

## Langage 100 % humain

- Garde-fou automatique `tool/user_facing_jargon_audit.dart` (+ test
  `test/l10n/user_facing_jargon_test.dart`) : toutes les traductions FR/EN et
  les phrases affichées dans `lib/` ; journaux, exceptions de développement,
  clés et interpolations ignorés. **Résultat : 0 occurrence.**
- Messages réécrits : erreurs d'authentification (plus de « Firebase », plus
  de code diagnostic à l'écran), écran de démarrage en échec, écran d'erreur
  d'affichage (plus de détail technique, même en préproduction), messages de
  quiz et de synchronisation du parcours, import de pages de cours.
- Cliquet i18n (`hardcoded_french_audit_test`) : vert.

## Démarrage et onglets (retour appareil du propriétaire)

- Environ 10 s d'écran blanc au lancement : les réglages de diagnostic et
  les notifications étaient attendus avant la première image, puis la lecture
  du profil en ligne (jusqu'à 8 s) après l'animation d'ouverture. Désormais :
  ces réglages partent après l'affichage ; une session déjà connue de
  l'appareil s'ouvre aussitôt sur son dernier profil valide et la lecture en
  ligne le confirme en arrière-plan (compte suspendu, supprimé ou rôle changé
  : appliqué dès la réponse ; hors ligne : l'espace reste ouvert).
- Apprendre et Quiz affichent leur cadre (titre, présentation, modes)
  pendant le chargement. Sans contenu publié : « Tes matières arrivent » /
  « Tes quiz arrivent » avec « Actualiser » et « Continuer mon parcours ».
  Les messages « Impossible de charger… » vus sur l'appareil venaient d'une
  version antérieure ; leurs clés sont supprimées.
- **Cause serveur probable du vide d'Apprendre en production** : la lecture
  des matières (`readLearningCatalog`, action « subjects ») est une requête
  de groupe de collections sur `status`, qui exige un index de groupe
  absent de `firestore.indexes.json`. L'émulateur ne l'exige pas. L'index
  est désormais déclaré (test de contrat ajouté) ; il prend effet au
  prochain déploiement des index par le propriétaire.

## Parcours (5e)

- Les publications « image » du Studio affichent enfin l'image (seule la
  légende apparaissait) ; elle arrive en fondu avec un léger recul.
- Notions : trait d'encre qui se dessine sous le titre ; un paragraphe de
  2 à 5 phrases courtes devient une idée clé puis un fil d'idées numérotées
  qui apparaissent l'une après l'autre ; les points suivent le même fil.
- Halos de fond qui se posent à l'arrivée de chaque carte ; chargement sous
  forme de carte plutôt qu'une roue sur fond vide.
- Toutes les animations jouent une fois et respectent « réduire les
  animations ». InteractiveLearningBlock non modifié.

## Google

- Propriétaire (23/09/2026) : Google Authentication activé sur
  `edunova-aabd1`, empreintes SHA-1/SHA-256 enregistrées, nouveau
  `android/app/google-services.json` fourni (clients OAuth Android et Web
  présents pour `com.edunova.app`). Fichier conservé et commité.
- `functions/.env.edunova-aabd1` : `GOOGLE_OAUTH_CLIENT_IDS` = client Web
  de production. Chargé au prochain déploiement des Functions.
- **Google réel configuré : côté application, oui (dans cet APK) ; côté
  serveur, non tant que les Functions (dont `probeGoogleIdentity`) ne sont
  pas redéployées avec ce paramètre.** Avant ce déploiement, « Continuer
  avec Google » affiche un message humain et ne crée aucune identité.

## Résultats des contrôles

| Contrôle | Résultat |
|---|---|
| `dart format --set-exit-if-changed lib test tool` | vert |
| `dart run tool/check_brand_references.dart` | vert |
| Garde-fou langage humain | 0 occurrence |
| `flutter analyze` | aucun problème |
| `flutter test` | 1649 réussis, 0 échec |
| Functions `npm test` | 50 fichiers, 427 réussis |
| Functions `npm run build` | vert |
| Règles et intégration (émulateur, 11 suites) | 172 réussis : règles Firestore 78, Storage 9, ressources pédagogiques 16, accès famille 17, réserve d'étude 8, annonces 4, suppression de compte 8, parcours 6, comptes admin 4, publication de leçons 9, tuteur 13 |
| Studio `flutter analyze` | aucun problème |
| Studio `flutter test` | 55 réussis |

## Actions propriétaire avant la QA complète (hors de cette mission)

Déploiement des index Firestore (index `subjects.status` de groupe) et des
Functions avec `functions/.env.edunova-aabd1` ; les éléments déjà listés
dans `AUTH_V2_FINAL_REWORK_REPORT_2026-09-23.md` restent valables.

## Liste de test sur appareil

| # | Scénario | À vérifier |
|---|---|---|
| 1 | Premier lancement | Première image en moins de 2 s, aucun écran blanc |
| 2 | Écran d'entrée | Compris sans aide : qui entre, par où |
| 3 | Téléphone +237 | Saisie, format, message clair si numéro invalide |
| 4 | Code SMS | Réception, bon code, mauvais code (« Ce code n'est pas correct. ») |
| 5 | Code élève | Entrée avec le code d'accès élève |
| 6 | Parent | Connexion et espace parent |
| 7 | Téléphone familial | « Continuer comme … » / « Je suis son parent » |
| 8 | Rattacher un enfant | Code, confirmation, enfant visible |
| 9 | Multi-enfants | Bascule entre enfants, données séparées |
| 10 | Changement d'espace | Élève ↔ parent sans mélange |
| 11 | Parcours | 5e : images visibles, fil d'idées animé, glisser fluide |
| 12 | Apprendre | Cadre immédiat ; sans contenu : « Tes matières arrivent » |
| 13 | Quiz | Cadre immédiat ; sans quiz : « Tes quiz arrivent » |
| 14 | KIRA | Écrire uniquement, aucun micro ni lecture à voix haute |
| 15 | LEO | Idem |
| 16 | InteractiveLearningBlock | Comportement inchangé |
| 17 | Découverte | Entrée et sortie |
| 18 | Déconnexion / reconnexion | Relancement : espace rouvert aussitôt |
| 19 | Appareil partagé | Aucune donnée du compte précédent |
| 20 | Réseau faible | Messages humains, aucun jargon, espace connu toujours ouvert |
| 21 | Google | **NON TESTABLE TANT QUE CONFIGURATION NON TERMINÉE** (Functions à redéployer avec `GOOGLE_OAUTH_CLIENT_IDS`) |

Points qui exigent un test physique : durée réelle du démarrage à froid,
fluidité des animations du Parcours sur un téléphone d'entrée de gamme,
affichage des images publiées (réseau réel), absence de toute demande de
permission micro, SMS réels.
